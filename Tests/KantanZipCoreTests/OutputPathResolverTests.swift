import XCTest
@testable import KantanZipCore

final class OutputPathResolverTests: XCTestCase {
    func test_単一ファイルは同じ場所に同名のzipを作る() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")

        let output = OutputPathResolver.resolve(inputs: [input], fileExists: { _ in false })

        XCTAssertEqual(output.path, "/Users/taro/Documents/report.zip")
    }
}
