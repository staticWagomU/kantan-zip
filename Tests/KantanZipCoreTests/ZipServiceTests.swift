import XCTest
@testable import KantanZipCore

final class ZipServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZipServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDir)
    }

    func test_入力から出力先決定まで一括で圧縮し進捗を通知する() throws {
        let photos = tempDir.appendingPathComponent("photos")
        try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
        try "a".write(to: photos.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try "b".write(to: photos.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)

        var fractions: [Double] = []
        let output = try ZipService.compress(inputs: [photos], password: nil) { fractions.append($0) }

        XCTAssertEqual(output.path, tempDir.appendingPathComponent("photos.zip").path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(fractions.last, 1.0, "最終的に進捗100%になること: \(fractions)")
    }
}
