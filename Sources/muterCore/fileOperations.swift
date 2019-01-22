import SwiftSyntax
import Foundation

// MARK - Source Code
func sourceCode(fromFileAt path: String) -> SourceFileSyntax? {
    let url = URL(fileURLWithPath: path)
    return try? SyntaxTreeParser.parse(url)
}

func copySourceCode(fromFileAt sourcePath: String, to destinationPath: String) {
    let source = sourceCode(fromFileAt: sourcePath)
    try? source?.description.write(toFile: destinationPath, atomically: true, encoding: .utf8)
}

// MARK - Working Directory
func createWorkingDirectory(in directory: String, fileManager: FileSystemManager = FileManager.default) -> String {
    let workingDirectory = "\(directory)/muter_tmp"
    try! fileManager.createDirectory(atPath: workingDirectory, withIntermediateDirectories: true, attributes: nil)
    return workingDirectory
}

func removeWorkingDirectory(at path: String) {
    do {
        try FileManager.default.removeItem(atPath: path)
    } catch {
        printMessage("Encountered error removing Muter's working directory")
        printMessage("\(error)")
    }
}

// MARK - Swap File Path
func swapFilePaths(forFilesAt paths: [String], using workingDirectoryPath: String) ->  [String: String] {
    var swapFilePathsByOriginalPath: [String: String] = [:]

    for path in paths {
        swapFilePathsByOriginalPath[path] = swapFilePath(forFileAt: path, using: workingDirectoryPath)
    }

    return swapFilePathsByOriginalPath
}

func swapFilePath(forFileAt path: String, using workingDirectory: String) -> String {
    let url = URL(fileURLWithPath: path)
    return "\(workingDirectory)/\(url.lastPathComponent)"
}
