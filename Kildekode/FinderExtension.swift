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

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard let target = controller.targetedURL(), target.isFileURL else { return nil }
        switch menuKind {
        case .contextualMenuForContainer:
            break
        case .contextualMenuForItems, .contextualMenuForSidebar:
            guard (controller.selectedItemURLs()?.count ?? 0) <= 1,
                  let values = try? target.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]),
                  values.isDirectory == true, values.isPackage != true else { return nil }
        default:
            return nil
        }

        let menu = NSMenu()
        let newFile = NSMenuItem(title: "Ny fil", action: nil, keyEquivalent: "")
        let options = NSMenu(title: "Ny fil")
        for kind in FileKind.allCases {
            let item = NSMenuItem(title: kind.title, action: #selector(createFile(_:)), keyEquivalent: "")
            item.target = self
            item.tag = kind.rawValue
            options.addItem(item)
        }
        newFile.submenu = options
        menu.addItem(newFile)
        return menu
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
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Nyfil kunne ikke opprette filen"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            NSApp?.activate(ignoringOtherApps: true)
            alert.runModal()
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
