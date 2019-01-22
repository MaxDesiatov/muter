import Foundation

protocol MutationTestingIODelegate {
    func backupFile(at path: String)
    func writeFile(to path: String, contents: String) throws
    func runTestSuite(savingResultsIntoFileNamed: String) -> TestSuiteResult
    func restoreFile(at path: String)
}

// MARK - Mutation Testing I/O Delegate
@available(OSX 10.13, *)
struct MutationTestingDelegate: MutationTestingIODelegate {

    let configuration: MuterConfiguration
    let swapFilePathsByOriginalPath: [String: String]

    func backupFile(at path: String) {
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: path, to: swapFilePath)
    }

    func writeFile(to path: String, contents: String) throws {
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }

    func runTestSuite(savingResultsIntoFileNamed: String) -> TestSuiteResult {
        do {

            let (testProcessFileHandle, testLogUrl) = try fileHandle(for: savingResultsIntoFileNamed)

            let process = try testProcess(with: configuration, and: testProcessFileHandle)
            try process.run()
            process.waitUntilExit()
            testProcessFileHandle.closeFile()

            let contents = try String(contentsOf: testLogUrl)
            return TestSuiteResult.from(testLog: contents)

        } catch {
            printMessage("Muter encountered an error running your test suite and can't continue\n\(error)")
            exit(1)
        }
    }

    func restoreFile(at path: String) {
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: swapFilePath, to: path)
    }
}

@available(OSX 10.13, *)
private extension MutationTestingDelegate {

    func fileHandle(for logFileName: String) throws -> (handle: FileHandle, logFileUrl: URL) {
        let testLogFileName = logFileName + ".log"
        let testLogUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + testLogFileName)
        try Data().write(to: testLogUrl)

        return (
            handle: try FileHandle(forWritingTo: testLogUrl),
            logFileUrl: testLogUrl
        )
    }

    func testProcess(with configuration: MuterConfiguration, and fileHandle: FileHandle) throws -> Process {

        let process = Process()
        process.arguments = configuration.testCommandArguments
        process.executableURL = URL(fileURLWithPath: configuration.testCommandExecutable)
        process.standardOutput = fileHandle
        process.standardError = fileHandle

        return process
    }
}
