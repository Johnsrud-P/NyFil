import AppKit
import FinderSync
import SwiftUI

/// Hovedappen viser oppsettvinduet når den åpnes vanlig. Finder-utvidelsen åpner den
/// også med `nyfil://flytt?sti=…` for å vise mappevelgeren, fordi en sandkasset
/// Finder-utvidelse ikke får lov til å vise NSOpenPanel selv.
@main
final class NyfilApp: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = NyfilApp()
        app.delegate = delegate
        app.run()
    }

    private var window: NSWindow?
    private var openedForMove = false
    private var moving = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = Self.makeMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ved oppstart fra Finder kommer flytte-URL-en rett etter at appen er startet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if !self.openedForMove { self.showSetupWindow() }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "nyfil" && url.host == "flytt" {
            openedForMove = true
            let paths = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.filter { $0.name == "sti" }.compactMap(\.value) ?? []
            chooseFolderAndMove(paths)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSetupWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !moving
    }

    private func showSetupWindow() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SetupView()))
            window.title = "NyFil"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func chooseFolderAndMove(_ paths: [String]) {
        let items = paths.map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !items.isEmpty else { return finishMove() }

        moving = true
        if window?.isVisible != true { NSApp.setActivationPolicy(.accessory) }
        NSApp.activate(ignoringOtherApps: true)

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

        if panel.runModal() == .OK, let folder = panel.url {
            do {
                _ = try FileMover.move(items, to: folder)
                RecentFolders.remember(folder.standardizedFileURL)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "NyFil kunne ikke flytte"
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
        finishMove()
    }

    private func finishMove() {
        moving = false
        if window?.isVisible != true { NSApp.terminate(nil) }
    }

    private static func makeMainMenu() -> NSMenu {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Skjul NyFil", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Avslutt NyFil", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Vindu")
        windowMenu.addItem(withTitle: "Lukk", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        return main
    }
}

private struct SetupView: View {
    @State private var enabled = FIFinderSyncController.isExtensionEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 58, height: 58)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("NyFil")
                        .font(.system(size: 27, weight: .semibold))
                    Label(enabled ? "Finder-utvidelsen er aktiv" : "Finder-utvidelsen må aktiveres",
                          systemImage: enabled ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(enabled ? Color.green : Color.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(enabled
                     ? "Høyreklikk i en mappe eller på filer i Finder og velg NyFil."
                     : "Åpne innstillingene for Finder-utvidelser og slå på NyFil.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Excel  ·  Word  ·  PowerPoint  ·  Tekst  ·  Flytt til  ·  Kopier sti")
                    .foregroundStyle(.secondary)
            }

            Button("Åpne innstillinger for Finder-utvidelser") {
                FIFinderSyncController.showExtensionManagementInterface()
            }
        }
        .padding(26)
        .frame(width: 400, alignment: .leading)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            enabled = FIFinderSyncController.isExtensionEnabled
        }
    }
}
