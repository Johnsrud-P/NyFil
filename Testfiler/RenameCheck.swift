import Foundation

@main
struct RenameCheck {
    static func main() throws {
        let resources = Bundle(path: CommandLine.arguments[1])!
        let directory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        let first = try FileKind.excel.create(in: directory, resources: resources)
        let original = try Data(contentsOf: first)

        for name in ["", "   ", "/", "mappe/fil", "Hei:der", "Hei\nder", ".xlsx", ".."] {
            do {
                _ = try FileKind.excel.rename(first, to: name)
                fatalError("Ugyldig filnavn ble godkjent: \(name)")
            } catch FileNameError.invalidName {}
        }

        let unchanged = try FileKind.excel.rename(first, to: first.deletingPathExtension().lastPathComponent)
        assert(unchanged == first)
        let renamed = try FileKind.excel.rename(first, to: "Budsjett for Ålesund.XLSX")
        let renamedData = try Data(contentsOf: renamed)
        assert(renamed.lastPathComponent == "Budsjett for Ålesund.xlsx")
        assert(renamedData == original)
        assert(!FileManager.default.fileExists(atPath: first.path))

        let existing = directory.appendingPathComponent("Eksisterende.xlsx")
        try Data("behold meg".utf8).write(to: existing)
        do {
            _ = try FileKind.excel.rename(renamed, to: "Eksisterende")
            fatalError("Eksisterende fil ble overskrevet")
        } catch let error as CocoaError where error.code == .fileWriteFileExists {
            let existingData = try Data(contentsOf: existing)
            assert(String(data: existingData, encoding: .utf8) == "behold meg")
            assert(FileManager.default.fileExists(atPath: renamed.path))
        }

        let caseOnly = try FileKind.excel.rename(renamed, to: "budsjett for Ålesund")
        let entries = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        assert(entries.contains(caseOnly.lastPathComponent))
        print(caseOnly.path)
    }
}
