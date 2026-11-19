import AppKit
import FinderSync
import SwiftUI

@main
struct NyfilApp: App {
    var body: some Scene {
        Window("Nyfil", id: "nyfil") {
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
                    Text("Nyfil")
                        .font(.system(size: 27, weight: .semibold))
                    Label(enabled ? "Finder-utvidelsen er aktiv" : "Finder-utvidelsen må aktiveres",
                          systemImage: enabled ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(enabled ? Color.green : Color.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(enabled
                     ? "Høyreklikk på et tomt område i en mappe i Finder og velg Ny fil."
                     : "Åpne innstillingene for Finder-utvidelser og slå på Nyfil.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Excel (.xlsx)  ·  Word (.docx)  ·  Tekst (.txt)")
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
