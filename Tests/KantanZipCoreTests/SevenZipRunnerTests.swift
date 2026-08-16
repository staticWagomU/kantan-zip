import XCTest
@testable import KantanZipCore

final class SevenZipRunnerTests: XCTestCase {
    var tempDir: URL!

    /// テスト時はリポジトリにvendorした7zzを使う（アプリ実行時はバンドル内から解決する）
    private var vendoredSevenZip: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // KantanZipCoreTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // リポジトリルート
            .appendingPathComponent("Vendor/7zz/7zz")
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(
            FileManager.default.fileExists(atPath: vendoredSevenZip.path),
            "Vendor/7zz/7zz が無い。scripts/fetch-7zz.sh を実行すること"
        )
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SevenZipRunnerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    func test_ZipCryptoで作ったzipはmacOS標準のunzipで開ける() throws {
        let file = tempDir.appendingPathComponent("secret.txt")
        try "極秘".write(to: file, atomically: true, encoding: .utf8)
        let output = tempDir.appendingPathComponent("secret.zip")
        let command = SevenZipCommand.build(
            executable: vendoredSevenZip,
            inputs: [file],
            output: output,
            encryption: .zipCrypto(password: "himitsu123")
        )

        try SevenZipRunner.run(command: command)

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(unzipTestExitCode(of: output, password: "himitsu123"), 0)
        XCTAssertNotEqual(unzipTestExitCode(of: output, password: "machigai"), 0)
    }

    func test_圧縮の進捗が通知される() throws {
        let folder = tempDir.appendingPathComponent("data")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for index in 0..<30 {
            let payload = String(repeating: "圧縮対象のテキスト", count: 500)
            try payload.write(
                to: folder.appendingPathComponent("file\(index).txt"),
                atomically: true,
                encoding: .utf8
            )
        }
        let output = tempDir.appendingPathComponent("data.zip")
        let command = SevenZipCommand.build(
            executable: vendoredSevenZip,
            inputs: [folder],
            output: output,
            encryption: .none
        )

        var chunks: [String] = []
        try SevenZipRunner.run(command: command) { chunks.append($0) }

        XCTAssertTrue(
            chunks.contains { $0.contains("%") },
            "進捗を含む出力が流れてくること: \(chunks)"
        )
    }

    func test_失敗時はエラーを投げる() throws {
        let missing = tempDir.appendingPathComponent("存在しない.txt")
        let output = tempDir.appendingPathComponent("out.zip")
        let command = SevenZipCommand.build(
            executable: vendoredSevenZip,
            inputs: [missing],
            output: output,
            encryption: .none
        )

        XCTAssertThrowsError(try SevenZipRunner.run(command: command))
    }

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
