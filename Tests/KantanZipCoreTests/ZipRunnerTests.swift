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
}
