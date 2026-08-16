import XCTest
@testable import KantanZipCore

final class OutputPathResolverTests: XCTestCase {
    func test_単一ファイルは同じ場所に同名のzipを作る() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")

        let output = OutputPathResolver.resolve(inputs: [input], fileExists: { _ in false })

        XCTAssertEqual(output.path, "/Users/taro/Documents/report.zip")
    }

    func test_複数ファイルはアーカイブという名前のzipを作る() {
        let inputs = [
            URL(fileURLWithPath: "/Users/taro/Documents/report.txt"),
            URL(fileURLWithPath: "/Users/taro/Documents/photos", isDirectory: true),
        ]

        let output = OutputPathResolver.resolve(inputs: inputs, fileExists: { _ in false })

        XCTAssertEqual(output.path, "/Users/taro/Documents/アーカイブ.zip")
    }
}
