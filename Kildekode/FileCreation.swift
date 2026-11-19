import Foundation
import Darwin

enum FileNameError: LocalizedError {
    case invalidName

    var errorDescription: String? {
        "Skriv et filnavn uten skråstrek, kolon eller linjeskift."
    }
}

enum FileKind: Int, CaseIterable {
    case excel, word, text

    var title: String {
        switch self {
        case .excel: "Excel-arbeidsbok (.xlsx)"
        case .word: "Word-dokument (.docx)"
        case .text: "Tekstfil (.txt)"
        }
    }

    var filename: String {
        switch self {
        case .excel: "Ny Excel-arbeidsbok"
        case .word: "Nytt Word-dokument"
        case .text: "Ny tekstfil"
        }
    }

    var fileExtension: String {
        switch self {
        case .excel: "xlsx"
        case .word: "docx"
        case .text: "txt"
        }
    }

    func rename(_ file: URL, to proposedName: String) throws -> URL {
        var name = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = ".\(fileExtension)"
        if name.lowercased().hasSuffix(suffix) {
            name = String(name.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
        }
        let invalidCharacters = CharacterSet(charactersIn: "/:\u{0000}").union(.newlines)
        guard !name.isEmpty, name != ".", name != "..",
              name.rangeOfCharacter(from: invalidCharacters) == nil else {
            throw FileNameError.invalidName
        }

        let newName = name + suffix
        guard file.lastPathComponent.utf8.elementsEqual(newName.utf8) == false else { return file }
        let destination = file.deletingLastPathComponent().appendingPathComponent(newName, isDirectory: false)
        try FileManager.default.moveItem(at: file, to: destination)
        return destination
    }

    func create(in directory: URL, resources: Bundle) throws -> URL {
        let content: Data
        if self == .text {
            content = Data()
        } else {
            guard let template = resources.url(forResource: "Tom", withExtension: fileExtension) else {
                throw CocoaError(.fileNoSuchFile)
            }
            content = try Data(contentsOf: template)
        }

        var number = 1
        while true {
            let name = number == 1 ? filename : "\(filename) \(number)"
            let destination = directory.appendingPathComponent("\(name).\(fileExtension)", isDirectory: false)
            let descriptor = destination.withUnsafeFileSystemRepresentation { path in
                open(path!, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0o666)
            }
            if descriptor == -1 {
                let error = errno
                if error == EEXIST {
                    number += 1
                    continue
                }
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(error))
            }

            let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
            do {
                try handle.write(contentsOf: content)
                try handle.close()
                return destination
            } catch {
                try? handle.close()
                try? FileManager.default.removeItem(at: destination)
                throw error
            }
        }
    }
}
