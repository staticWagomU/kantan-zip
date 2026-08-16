import XCTest
@testable import KantanZipCore

final class ZipRunnerTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZipRunnerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDir)
    }

    func test_実際にzipファイルを作成できる() throws {
        let file = tempDir.appendingPathComponent("hello.txt")
        try "こんにちは".write(to: file, atomically: true, encoding: .utf8)
        let output = tempDir.appendingPathComponent("hello.zip")
        let command = ZipCommand.build(inputs: [file], output: output, password: nil)

        var lines: [String] = []
        try ZipRunner.run(command: command) { lines.append($0) }

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertTrue(lines.contains { $0.contains("adding:") }, "進捗行が流れてくること: \(lines)")
    }

    func test_パスワード付きzipは正しいパスワードでだけ開ける() throws {
        let file = tempDir.appendingPathComponent("secret.txt")
        try "極秘".write(to: file, atomically: true, encoding: .utf8)
        let output = tempDir.appendingPathComponent("secret.zip")
        let command = ZipCommand.build(inputs: [file], output: output, password: "himitsu123")

        try ZipRunner.run(command: command)

        XCTAssertEqual(unzipTestExitCode(of: output, password: "himitsu123"), 0, "正しいパスワードで検証が通ること")
        XCTAssertNotEqual(unzipTestExitCode(of: output, password: "machigai"), 0, "誤ったパスワードでは検証が失敗すること")
    }

    /// unzip -t -P で整合性検証し、終了コードを返す
    private func unzipTestExitCode(of zip: URL, password: String) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-t", "-P", password, zip.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
