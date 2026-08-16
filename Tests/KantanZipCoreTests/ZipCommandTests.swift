import XCTest
@testable import KantanZipCore

final class ZipCommandTests: XCTestCase {
    func test_単一ファイルをパスワードなしで圧縮する引数を組み立てる() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")
        let output = URL(fileURLWithPath: "/Users/taro/Documents/report.zip")

        let command = ZipCommand.build(inputs: [input], output: output, password: nil)

        XCTAssertEqual(command.executablePath, "/usr/bin/zip")
        XCTAssertEqual(command.workingDirectory.path, "/Users/taro/Documents")
        XCTAssertEqual(command.arguments, ["-r", "-y", "/Users/taro/Documents/report.zip", "report.txt"])
    }

    func test_パスワード指定時はPオプションが付く() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")
        let output = URL(fileURLWithPath: "/Users/taro/Documents/report.zip")

        let command = ZipCommand.build(inputs: [input], output: output, password: "himitsu123")

        XCTAssertEqual(
            command.arguments,
            ["-r", "-y", "-P", "himitsu123", "/Users/taro/Documents/report.zip", "report.txt"]
        )
    }
}
