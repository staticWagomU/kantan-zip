import XCTest
@testable import KantanZipCore

final class OutputPathResolverTests: XCTestCase {
    func test_単一ファイルは同じ場所に同名のzipを作る() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")

        let output = OutputPathResolver.resolve(inputs: [input], fileExists: { _ in false })

        XCTAssertEqual(output.path, "/Users/taro/Documents/report.zip")
    }

    func test_複数ファイルは親フォルダ名をzip名にする() {
        let inputs = [
            URL(fileURLWithPath: "/Users/taro/Documents/案件A/report.txt"),
            URL(fileURLWithPath: "/Users/taro/Documents/案件A/photos", isDirectory: true),
        ]

        let output = OutputPathResolver.resolve(inputs: inputs, fileExists: { _ in false })

        XCTAssertEqual(output.path, "/Users/taro/Documents/案件A/案件A.zip")
    }

    func test_親フォルダ名が使えない場合はアーカイブにする() {
        let inputs = [
            URL(fileURLWithPath: "/report.txt"),
            URL(fileURLWithPath: "/photos", isDirectory: true),
        ]

        let output = OutputPathResolver.resolve(inputs: inputs, fileExists: { _ in false })

        XCTAssertEqual(output.path, "/アーカイブ.zip")
    }

    func test_同名zipが既にある場合は連番を付ける() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")
        let existing = ["/Users/taro/Documents/report.zip", "/Users/taro/Documents/report 2.zip"]

        let output = OutputPathResolver.resolve(
            inputs: [input],
            fileExists: { existing.contains($0.path) }
        )

        XCTAssertEqual(output.path, "/Users/taro/Documents/report 3.zip")
    }
}
