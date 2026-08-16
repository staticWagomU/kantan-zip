import XCTest
@testable import KantanZipCore

final class ZipServiceTests: XCTestCase {
    var tempDir: URL!

    private var vendoredSevenZip: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Vendor/7zz/7zz")
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(
            FileManager.default.fileExists(atPath: vendoredSevenZip.path),
            "Vendor/7zz/7zz が無い。scripts/fetch-7zz.sh を実行すること"
        )
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZipServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    func test_入力から出力先決定まで一括で圧縮し進捗を通知する() throws {
        let photos = tempDir.appendingPathComponent("photos")
        try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
        try "a".write(to: photos.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try "b".write(to: photos.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)

        var fractions: [Double] = []
        let output = try ZipService.compress(
            sevenZipExecutable: vendoredSevenZip,
            inputs: [photos],
            encryption: .none
        ) { fractions.append($0) }

        XCTAssertEqual(output.path, tempDir.appendingPathComponent("photos.zip").path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(fractions.last, 1.0, "最終的に進捗100%になること: \(fractions)")
    }

    func test_同名zipがあれば連番を付けて既存を壊さない() throws {
        let file = tempDir.appendingPathComponent("report.txt")
        try "本文".write(to: file, atomically: true, encoding: .utf8)

        let first = try ZipService.compress(
            sevenZipExecutable: vendoredSevenZip, inputs: [file], encryption: .none
        ) { _ in }
        let second = try ZipService.compress(
            sevenZipExecutable: vendoredSevenZip, inputs: [file], encryption: .none
        ) { _ in }

        XCTAssertEqual(first.lastPathComponent, "report.zip")
        XCTAssertEqual(second.lastPathComponent, "report 2.zip")
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
    }
}
