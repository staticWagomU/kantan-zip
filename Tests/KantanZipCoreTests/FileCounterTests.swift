import XCTest
@testable import KantanZipCore

final class FileCounterTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileCounterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDir)
    }

    func test_フォルダ再帰でzipのエントリ数を数える() throws {
        // photos/ 自身 + a.txt + b.txt + photos/sub/ + photos/sub/c.txt = 5エントリ
        let photos = tempDir.appendingPathComponent("photos")
        let sub = photos.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try "a".write(to: photos.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try "b".write(to: photos.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)
        try "c".write(to: sub.appendingPathComponent("c.txt"), atomically: true, encoding: .utf8)

        let count = FileCounter.countEntries(inputs: [photos])

        XCTAssertEqual(count, 5)
    }
}
