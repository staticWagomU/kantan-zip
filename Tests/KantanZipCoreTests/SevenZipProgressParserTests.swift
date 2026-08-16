import XCTest
@testable import KantanZipCore

final class SevenZipProgressParserTests: XCTestCase {
    func test_パーセンテージ表記から進捗を読み取る() {
        var parser = SevenZipProgressParser()

        parser.consume(chunk: " 42% 5 + big/f105.bin")

        XCTAssertEqual(parser.fraction, 0.42, accuracy: 0.001)
    }

    func test_パーセンテージを含まない出力では進捗が変わらない() {
        var parser = SevenZipProgressParser()
        parser.consume(chunk: " 42% 5 + big/f105.bin")

        parser.consume(chunk: "Creating archive: big.zip")

        XCTAssertEqual(parser.fraction, 0.42, accuracy: 0.001)
    }

    func test_1チャンクに複数のパーセンテージがあれば最後を採用する() {
        var parser = SevenZipProgressParser()

        // 7zzはバックスペースで行を書き換えるため、1チャンクに複数の%が混ざる
        parser.consume(chunk: "  7%\u{8}\u{8}\u{8}\u{8} 19%\u{8}\u{8}\u{8}\u{8} 23%")

        XCTAssertEqual(parser.fraction, 0.23, accuracy: 0.001)
    }

    func test_進捗は後戻りしない() {
        var parser = SevenZipProgressParser()
        parser.consume(chunk: " 80%")

        parser.consume(chunk: " 12%")

        XCTAssertEqual(parser.fraction, 0.80, accuracy: 0.001)
    }
}
