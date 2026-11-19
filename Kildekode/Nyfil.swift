import AppKit
import FinderSync
import SwiftUI

@main
struct NyfilApp: App {
    var body: some Scene {
        Window("NyFil", id: "nyfil") {
            SetupView()
        }
        .windowResizability(.contentSize)
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
