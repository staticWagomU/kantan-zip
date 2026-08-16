import XCTest
@testable import KantanZipCore

final class ZipProgressParserTests: XCTestCase {
    func test_adding行を数えて進捗率を計算する() {
        var parser = ZipProgressParser(totalEntryCount: 4)

        parser.consume(line: "  adding: report.txt (deflated 60%)")
        parser.consume(line: "  adding: photos/ (stored 0%)")

        XCTAssertEqual(parser.fraction, 0.5, accuracy: 0.001)
    }

    func test_adding以外の行は進捗に影響しない() {
        var parser = ZipProgressParser(totalEntryCount: 2)

        parser.consume(line: "updating: report.txt (deflated 60%)")
        parser.consume(line: "")

        XCTAssertEqual(parser.fraction, 0.0, accuracy: 0.001)
    }
}
