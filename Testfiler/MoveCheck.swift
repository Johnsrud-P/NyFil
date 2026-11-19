import Foundation

@main
struct MoveCheck {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let fm = FileManager.default
        let source = root.appendingPathComponent("Kilde æøå", isDirectory: true)
        let target = root.appendingPathComponent("Mål", isDirectory: true)
        try fm.createDirectory(at: source, withIntermediateDirectories: true)
        try fm.createDirectory(at: target, withIntermediateDirectories: true)

        // Vanlig flytting bevarer innholdet.
        let report = source.appendingPathComponent("Rapport.txt")
        try Data("ny".utf8).write(to: report)
        try Data("gammel".utf8).write(to: target.appendingPathComponent("Rapport.txt"))
        let moved = try FileMover.move([report], to: target)
        precondition(moved.map(\.lastPathComponent) == ["Rapport 2.txt"])
        let old = try Data(contentsOf: target.appendingPathComponent("Rapport.txt"))
        let new = try Data(contentsOf: moved[0])
        precondition(String(decoding: old, as: UTF8.self) == "gammel")
        precondition(String(decoding: new, as: UTF8.self) == "ny")
        precondition(!fm.fileExists(atPath: report.path))

        // Mapper med punktum i navnet får nummer bak hele navnet.
        let folder = source.appendingPathComponent("Prosjekt.v2", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        try fm.createDirectory(at: target.appendingPathComponent("Prosjekt.v2"), withIntermediateDirectories: true)
        let movedFolder = try FileMover.move([folder], to: target)
        precondition(movedFolder[0].lastPathComponent == "Prosjekt.v2 2")

        // En mappe kan ikke flyttes inn i seg selv eller en undermappe.
        let inner = movedFolder[0].appendingPathComponent("Under", isDirectory: true)
        try fm.createDirectory(at: inner, withIntermediateDirectories: true)
        for destination in [movedFolder[0], inner] {
            do {
                _ = try FileMover.move([movedFolder[0]], to: destination)
                fatalError("Mappe ble flyttet inn i seg selv")
            } catch MoveError.intoItself {}
        }

        // Flytting til mappen filen allerede ligger i, gjør ingenting.
        let stay = target.appendingPathComponent("Bli.txt")
        try Data().write(to: stay)
        let none = try FileMover.move([stay], to: target)
        precondition(none.isEmpty)
        precondition(fm.fileExists(atPath: stay.path))

        // Flere filer samtidig, og fil uten filendelse.
        let a = source.appendingPathComponent("a.pdf")
        let b = source.appendingPathComponent("Makefile")
        try Data().write(to: a)
        try Data().write(to: b)
        try Data().write(to: target.appendingPathComponent("Makefile"))
        let many = try FileMover.move([a, b], to: target)
        precondition(many.map(\.lastPathComponent) == ["a.pdf", "Makefile 2"])

        print("Flytting, duplikater, mapper og selvflytting: OK")
    }
}
