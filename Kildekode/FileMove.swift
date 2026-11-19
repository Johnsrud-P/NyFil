import Foundation
import Darwin

enum MoveError: LocalizedError {
    case intoItself(String)

    var errorDescription: String? {
        switch self {
        case .intoItself(let name):
            "Mappen «\(name)» kan ikke flyttes inn i seg selv."
        }
    }
}

enum FileMover {
    /// Flytter hvert objekt til mappen. Objekter som allerede ligger der, blir liggende.
    /// Finnes navnet fra før, får det flyttede objektet et nummer. Ingenting overskrives.
    static func move(_ items: [URL], to folder: URL) throws -> [URL] {
        let folder = folder.standardizedFileURL.resolvingSymlinksInPath()
        var moved: [URL] = []
        for item in items {
            let source = item.standardizedFileURL
            let resolvedSource = source.resolvingSymlinksInPath()
            if resolvedSource.deletingLastPathComponent().path == folder.path { continue }
            if folder.path == resolvedSource.path || folder.path.hasPrefix(resolvedSource.path + "/") {
                throw MoveError.intoItself(source.lastPathComponent)
            }
            moved.append(try moveOne(source, into: folder))
        }
        return moved
    }

    private static func moveOne(_ source: URL, into folder: URL) throws -> URL {
        let name = source.lastPathComponent
        let values = try? source.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        let plainFolder = values?.isDirectory == true && values?.isPackage != true
        let ext = plainFolder ? "" : source.pathExtension
        let base = ext.isEmpty ? name : String(name.dropLast(ext.count + 1))
        let suffix = ext.isEmpty ? "" : ".\(ext)"

        var number = 1
        while true {
            let candidate = number == 1 ? name : "\(base) \(number)\(suffix)"
            let destination = folder.appendingPathComponent(candidate)
            let result = source.withUnsafeFileSystemRepresentation { from in
                destination.withUnsafeFileSystemRepresentation { to in
                    renamex_np(from!, to!, UInt32(RENAME_EXCL))
                }
            }
            if result == 0 { return destination }

            switch errno {
            case EEXIST:
                number += 1
            case EXDEV:
                // Annen disk: kopier og slett. FileManager nekter å overskrive.
                if FileManager.default.fileExists(atPath: destination.path) {
                    number += 1
                    continue
                }
                do {
                    try FileManager.default.moveItem(at: source, to: destination)
                    return destination
                } catch let error as CocoaError where error.code == .fileWriteFileExists {
                    number += 1
                }
            case let code:
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(code),
                              userInfo: [NSFilePathErrorKey: source.path])
            }
        }
    }
}

/// De sist brukte målmappene. Lagres i en fil i den ekte hjemmemappen, slik at både
/// hovedappen og den sandkassede Finder-utvidelsen leser og skriver samme liste.
enum RecentFolders {
    private static let legacyKey = "nyligeMapper"
    private static let limit = 5

    static var storeURL: URL {
        var home = NSHomeDirectory()
        if let account = getpwuid(getuid()), let dir = account.pointee.pw_dir {
            home = String(cString: dir)
        }
        return URL(fileURLWithPath: home, isDirectory: true)
            .appendingPathComponent("Library/Application Support/NyFil/nylige-mapper.json")
    }

    private static func storedPaths() -> [String] {
        if let data = try? Data(contentsOf: storeURL),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            return paths
        }
        // Liste fra versjon 1.2, lagret i utvidelsens egne innstillinger.
        return UserDefaults.standard.stringArray(forKey: legacyKey) ?? []
    }

    static func load() -> [URL] {
        storedPaths().map { URL(fileURLWithPath: $0, isDirectory: true) }.filter {
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }

    static func remember(_ folder: URL) {
        var paths = storedPaths()
        paths.removeAll { $0 == folder.path }
        paths.insert(folder.path, at: 0)
        do {
            try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(Array(paths.prefix(limit))).write(to: storeURL, options: .atomic)
        } catch {
            UserDefaults.standard.set(Array(paths.prefix(limit)), forKey: legacyKey)
        }
    }
}
