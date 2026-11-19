import AppKit
import FinderSync
import os

@objc(NyfilFinderExtension)
final class NyfilFinderExtension: FIFinderSync {
    private let controller = FIFinderSyncController.default()
    private let logger = Logger(subsystem: "no.nyfil.mac", category: "Finder")

    override init() {
        super.init()

        var folders: Set<URL> = [
            URL(fileURLWithPath: "/", isDirectory: true),
            URL(fileURLWithPath: "/Volumes", isDirectory: true)
        ]
        if let account = getpwuid(getuid()), let home = account.pointee.pw_dir {
            folders.insert(URL(fileURLWithPath: String(cString: home), isDirectory: true))
        }
        controller.directoryURLs = folders
        logger.info("Nyfil er lastet i Finder.")
    }

    /// Mappene som ble vist i «Flytt til» sist menyen ble bygget. Menyvalgets tag peker hit.
    private var menuRecentFolders: [URL] = []

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard let target = controller.targetedURL(), target.isFileURL else { return nil }
        let menu = NSMenu()

        switch menuKind {
        case .contextualMenuForContainer:
            menu.addItem(newFileItem())
            menu.addItem(copyPathItem(count: 1))
        case .contextualMenuForItems:
            let selected = controller.selectedItemURLs() ?? []
            guard !selected.isEmpty else { return nil }
            if selected.count == 1, isPlainFolder(selected[0]) {
                menu.addItem(newFileItem())
            }
            menu.addItem(moveItem(for: selected))
            menu.addItem(copyPathItem(count: selected.count))
        case .contextualMenuForSidebar:
            guard isPlainFolder(target) else { return nil }
            menu.addItem(newFileItem())
        default:
            return nil
        }
        return menu
    }

    private func isPlainFolder(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        return values?.isDirectory == true && values?.isPackage != true
    }

    private func newFileItem() -> NSMenuItem {
        let newFile = NSMenuItem(title: "Ny fil", action: nil, keyEquivalent: "")
        let options = NSMenu(title: "Ny fil")
        for kind in FileKind.allCases {
            let item = NSMenuItem(title: kind.title, action: #selector(createFile(_:)), keyEquivalent: "")
            item.target = self
            item.tag = kind.rawValue
            options.addItem(item)
        }
        newFile.submenu = options
        return newFile
    }

    private func copyPathItem(count: Int) -> NSMenuItem {
        let item = NSMenuItem(title: count > 1 ? "Kopier stier" : "Kopier sti",
                              action: #selector(copyPath(_:)), keyEquivalent: "")
        item.target = self
        return item
    }

    private func moveItem(for selected: [URL]) -> NSMenuItem {
        let parents = Set(selected.map { $0.standardizedFileURL.deletingLastPathComponent().path })
        menuRecentFolders = RecentFolders.load().filter { !(parents.count == 1 && parents.contains($0.path)) }

        let move = NSMenuItem(title: "Flytt til", action: nil, keyEquivalent: "")
        let options = NSMenu(title: "Flytt til")
        for (index, folder) in menuRecentFolders.enumerated() {
            let item = NSMenuItem(title: folder.lastPathComponent, action: #selector(moveToRecent(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            let icon = NSWorkspace.shared.icon(forFile: folder.path)
            icon.size = NSSize(width: 16, height: 16)
            item.image = icon
            options.addItem(item)
        }
        if !menuRecentFolders.isEmpty { options.addItem(.separator()) }
        let choose = NSMenuItem(title: "Velg mappe …", action: #selector(moveToChosenFolder(_:)), keyEquivalent: "")
        choose.target = self
        options.addItem(choose)
        move.submenu = options
        return move
    }

    @objc private func copyPath(_ sender: NSMenuItem) {
        var urls = controller.selectedItemURLs() ?? []
        if urls.isEmpty, let target = controller.targetedURL() { urls = [target] }
        guard !urls.isEmpty else { return }
        let text = urls.map { $0.standardizedFileURL.path }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    @objc private func moveToRecent(_ sender: NSMenuItem) {
        guard menuRecentFolders.indices.contains(sender.tag) else { return }
        move(controller.selectedItemURLs() ?? [], to: menuRecentFolders[sender.tag])
    }

    @objc private func moveToChosenFolder(_ sender: NSMenuItem) {
        let items = controller.selectedItemURLs() ?? []
        guard !items.isEmpty else { return }
        DispatchQueue.main.async {
            self.bringToFront()
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Flytt hit"
            panel.message = items.count == 1
                ? "Velg hvor «\(items[0].lastPathComponent)» skal flyttes."
                : "Velg hvor de \(items.count) objektene skal flyttes."
            panel.directoryURL = RecentFolders.load().first ?? items[0].deletingLastPathComponent()
            guard panel.runModal() == .OK, let folder = panel.url else { return }
            self.move(items, to: folder)
        }
    }

    private func move(_ items: [URL], to folder: URL) {
        guard !items.isEmpty else { return }
        do {
            _ = try FileMover.move(items, to: folder)
            RecentFolders.remember(folder.standardizedFileURL)
        } catch {
            logger.error("Kunne ikke flytte: \(error.localizedDescription, privacy: .public)")
            showError("NyFil kunne ikke flytte", error)
        }
    }

    private func bringToFront() {
        let app = NSApplication.shared
        if app.activationPolicy() == .prohibited {
            app.setActivationPolicy(.accessory)
        }
        app.activate(ignoringOtherApps: true)
    }

    private func showError(_ title: String, _ error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = title
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            self.bringToFront()
            alert.runModal()
        }
    }

    @objc private func createFile(_ sender: NSMenuItem) {
        guard let kind = FileKind(rawValue: sender.tag),
              let folder = controller.targetedURL(), folder.isFileURL else { return }

        do {
            let newFile = try kind.create(in: folder, resources: Bundle(for: NyfilFinderExtension.self))
            if kind == .excel {
                DispatchQueue.main.async {
                    let finalFile = self.promptForExcelName(newFile)
                    NSWorkspace.shared.activateFileViewerSelecting([finalFile])
                }
            } else {
                NSWorkspace.shared.activateFileViewerSelecting([newFile])
            }
        } catch {
            logger.error("Kunne ikke opprette fil: \(error.localizedDescription, privacy: .public)")
            showError("NyFil kunne ikke opprette filen", error)
        }
    }

    @MainActor
    private func promptForExcelName(_ file: URL) -> URL {
        let app = NSApplication.shared
        if app.activationPolicy() == .prohibited {
            app.setActivationPolicy(.accessory)
        }

        var proposedName = file.deletingPathExtension().lastPathComponent
        var message = "Skriv inn navnet på Excel-filen."
        while true {
            let alert = NSAlert()
            alert.messageText = "Gi Excel-filen et navn"
            alert.informativeText = message
            alert.addButton(withTitle: "Bytt navn")
            alert.addButton(withTitle: "Behold navnet").keyEquivalent = "\u{1B}"

            let field = NSTextField(string: proposedName)
            field.frame = NSRect(x: 0, y: 0, width: 270, height: 24)
            field.setAccessibilityLabel("Filnavn")
            alert.accessoryView = field
            alert.layout()
            alert.window.initialFirstResponder = field
            alert.window.level = .floating
            app.activate(ignoringOtherApps: true)
            field.selectText(nil)

            guard alert.runModal() == .alertFirstButtonReturn else { return file }
            proposedName = field.stringValue
            do {
                return try FileKind.excel.rename(file, to: proposedName)
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                message = "En fil med dette navnet finnes allerede. Velg et annet navn."
            } catch {
                message = error.localizedDescription
            }
        }
    }
}
