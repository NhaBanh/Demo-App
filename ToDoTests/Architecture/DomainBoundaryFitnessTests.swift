import XCTest

final class DomainBoundaryFitnessTests: XCTestCase {
    func testDomainLayerDoesNotImportOuterLayerFrameworks() throws {
        let featuresDirectory = try repositoryRoot()
            .appendingPathComponent("ToDo")
            .appendingPathComponent("Features")

        let forbiddenImports = [
            "import SwiftUI",
            "import SwiftData",
            "import SQLite3",
            "import UIKit",
        ]

        let swiftFiles = try domainSwiftFiles(in: featuresDirectory)
        XCTAssertFalse(swiftFiles.isEmpty, "Expected Domain Swift files to exist.")

        var violations: [String] = []

        for fileURL in swiftFiles {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let matchedImports = forbiddenImports.filter { contents.contains($0) }
            guard !matchedImports.isEmpty else { continue }

            let relativePath = fileURL.path.replacingOccurrences(
                of: featuresDirectory.deletingLastPathComponent().path + "/",
                with: ""
            )
            violations.append("\(relativePath): \(matchedImports.joined(separator: ", "))")
        }

        XCTAssertTrue(
            violations.isEmpty,
            """
            Domain layer imported outer-layer frameworks.
            Violations:
            \(violations.joined(separator: "\n"))
            """
        )
    }

    func testApplicationLayerDoesNotImportOuterLayerFrameworks() throws {
        let featuresDirectory = try repositoryRoot()
            .appendingPathComponent("ToDo")
            .appendingPathComponent("Features")

        let forbiddenImports = [
            "import SwiftUI",
            "import SwiftData",
            "import SQLite3",
            "import UIKit",
        ]

        let swiftFiles = try applicationSwiftFiles(in: featuresDirectory)
        XCTAssertFalse(swiftFiles.isEmpty, "Expected Application Swift files to exist.")

        var violations: [String] = []

        for fileURL in swiftFiles {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let matchedImports = forbiddenImports.filter { contents.contains($0) }
            guard !matchedImports.isEmpty else { continue }

            let relativePath = fileURL.path.replacingOccurrences(
                of: featuresDirectory.deletingLastPathComponent().path + "/",
                with: ""
            )
            violations.append("\(relativePath): \(matchedImports.joined(separator: ", "))")
        }

        XCTAssertTrue(
            violations.isEmpty,
            """
            Application layer imported outer-layer frameworks.
            Violations:
            \(violations.joined(separator: "\n"))
            """
        )
    }

    func testFeatureDirectoriesOnlyContainAllowedTopLevelLayers() throws {
        let featuresDirectory = try repositoryRoot()
            .appendingPathComponent("ToDo")
            .appendingPathComponent("Features")

        let allowedDirectories = Set(["Application", "Data", "Domain", "Presentation"])
        let featureDirectories = try FileManager.default.contentsOfDirectory(
            at: featuresDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
            .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }

        var violations: [String] = []

        for featureDirectory in featureDirectories {
            let childDirectories = try FileManager.default.contentsOfDirectory(
                at: featureDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
                .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }
                .map(\.lastPathComponent)

            let unexpectedDirectories = childDirectories
                .filter { !allowedDirectories.contains($0) }
                .sorted()

            if !unexpectedDirectories.isEmpty {
                violations.append("\(featureDirectory.lastPathComponent): \(unexpectedDirectories.joined(separator: ", "))")
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            """
            Feature directories contained unexpected top-level folders.
            Expected only Application, Data, Domain, and/or Presentation.
            Violations:
            \(violations.joined(separator: "\n"))
            """
        )
    }

    func testDomainLayerDoesNotReferenceFeatureDataOrPresentationTypes() throws {
        let featuresDirectory = try repositoryRoot()
            .appendingPathComponent("ToDo")
            .appendingPathComponent("Features")

        let featureDirectories = try FileManager.default.contentsOfDirectory(
            at: featuresDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
            .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }

        var violations: [String] = []

        for featureDirectory in featureDirectories {
            let forbiddenSymbols = try architectureTypeNames(in: featureDirectory)
            guard !forbiddenSymbols.isEmpty else { continue }

            let domainDirectory = featureDirectory.appendingPathComponent("Domain")
            guard FileManager.default.fileExists(atPath: domainDirectory.path) else {
                continue
            }

            for fileURL in try swiftFiles(in: domainDirectory) {
                let contents = try String(contentsOf: fileURL, encoding: .utf8)
                let matchedSymbols = forbiddenSymbols.filter { symbol in
                    contents.range(
                        of: "\\b\(NSRegularExpression.escapedPattern(for: symbol))\\b",
                        options: .regularExpression
                    ) != nil
                }

                guard !matchedSymbols.isEmpty else { continue }

                let relativePath = fileURL.path.replacingOccurrences(
                    of: featuresDirectory.deletingLastPathComponent().path + "/",
                    with: ""
                )
                violations.append("\(relativePath): \(matchedSymbols.sorted().joined(separator: ", "))")
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            """
            Domain layer referenced feature Data or Presentation types directly.
            Violations:
            \(violations.joined(separator: "\n"))
            """
        )
    }

    private func repositoryRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 {
            url.deleteLastPathComponent()
        }
        return url
    }

    private func domainSwiftFiles(in featuresDirectory: URL) throws -> [URL] {
        try layerSwiftFiles(in: featuresDirectory, layerName: "Domain")
    }

    private func applicationSwiftFiles(in featuresDirectory: URL) throws -> [URL] {
        try layerSwiftFiles(in: featuresDirectory, layerName: "Application")
    }

    private func layerSwiftFiles(in featuresDirectory: URL, layerName: String) throws -> [URL] {
        let featureDirectories = try FileManager.default.contentsOfDirectory(
            at: featuresDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        let directories = try featureDirectories
            .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }

        var files: [URL] = []
        for featureDirectory in directories {
            let layerDirectory = featureDirectory.appendingPathComponent(layerName)
            guard FileManager.default.fileExists(atPath: layerDirectory.path) else {
                continue
            }
            files.append(contentsOf: try swiftFiles(in: layerDirectory))
        }

        return files.sorted { $0.path < $1.path }
    }

    private func architectureTypeNames(in featureDirectory: URL) throws -> [String] {
        let candidateDirectories = [
            featureDirectory.appendingPathComponent("Data"),
            featureDirectory.appendingPathComponent("Presentation"),
        ]

        var names = Set<String>()
        for directory in candidateDirectories where FileManager.default.fileExists(atPath: directory.path) {
            let files = try swiftFiles(in: directory)
            for fileURL in files {
                names.insert(fileURL.deletingPathExtension().lastPathComponent)
            }
        }

        return names.sorted()
    }

    private func swiftFiles(in directory: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var files: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }
            files.append(fileURL)
        }
        return files.sorted { $0.path < $1.path }
    }
}
