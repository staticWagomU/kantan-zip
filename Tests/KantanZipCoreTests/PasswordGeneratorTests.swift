import XCTest
@testable import KantanZipCore

final class PasswordGeneratorTests: XCTestCase {
    func test_指定した長さのパスワードを生成する() {
        let password = PasswordGenerator.generate(length: 16)

        XCTAssertEqual(password.count, 16)
    }

    func test_紛らわしい文字を含まない() {
        // 電話やチャットで口頭伝達されるため、0とO、1とlとIの混同を避ける
        let confusing = Set("0O1lI")

        for _ in 0..<200 {
            let password = PasswordGenerator.generate(length: 20)
            XCTAssertTrue(
                password.allSatisfy { !confusing.contains($0) },
                "紛らわしい文字が含まれている: \(password)"
            )
        }
    }

    func test_英大文字と英小文字と数字をそれぞれ含む() {
        for _ in 0..<200 {
            let password = PasswordGenerator.generate(length: 12)
            XCTAssertTrue(password.contains(where: \.isUppercase), "大文字がない: \(password)")
            XCTAssertTrue(password.contains(where: \.isLowercase), "小文字がない: \(password)")
            XCTAssertTrue(password.contains(where: \.isNumber), "数字がない: \(password)")
        }
    }

    func test_生成するたびに異なる() {
        let generated = (0..<50).map { _ in PasswordGenerator.generate(length: 16) }

        XCTAssertEqual(Set(generated).count, generated.count, "重複が発生している")
    }

    func test_短すぎる長さを指定しても最低限の長さを確保する() {
        // 各種文字を1つずつ含める都合上、生成できる最小長を下回らないこと
        let password = PasswordGenerator.generate(length: 1)

        XCTAssertGreaterThanOrEqual(password.count, 3)
    }
}
