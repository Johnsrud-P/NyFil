import Foundation

@main
struct Check {
    static func main() throws {
        let resources = Bundle(path: CommandLine.arguments[1])!
        let dir = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)

        for format in FileKind.allCases {
            let first = try format.create(in: dir, resources: resources)
            let original = try Data(contentsOf: first)
            let second = try format.create(in: dir, resources: resources)
            precondition(second.lastPathComponent == "\(format.filename) 2.\(format.fileExtension)")
            precondition(first.pathExtension == format.fileExtension)
            let current = try Data(contentsOf: first)
            let copy = try Data(contentsOf: second)
            precondition(original == current && original == copy)
        }

        try DispatchQueue.concurrentPerform(iterations: 20) { _ in
            do {
                _ = try FileKind.text.create(in: dir, resources: resources)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        let txt = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".txt") }
        precondition(txt.count == 22)
        print("Tekst, Word, Excel, duplikater og parallelle opprettelser: OK")
    }
}
