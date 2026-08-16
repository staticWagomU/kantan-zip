import XCTest
@testable import KantanZipCore

final class SevenZipCommandTests: XCTestCase {
    private let executable = URL(fileURLWithPath: "/opt/KantanZip.app/Contents/Resources/7zz")

    func test_パスワードなしはZipCrypto指定もパスワード引数も付かない() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")
        let output = URL(fileURLWithPath: "/Users/taro/Documents/report.zip")

        let command = SevenZipCommand.build(
            executable: executable,
            inputs: [input],
            output: output,
            encryption: .none
        )

        XCTAssertEqual(command.executableURL, executable)
        XCTAssertEqual(command.workingDirectory.path, "/Users/taro/Documents")
        XCTAssertEqual(
            command.arguments,
            ["a", "-tzip", "-bsp1", "-bb1", "-y", "/Users/taro/Documents/report.zip", "report.txt"]
        )
        XCTAssertNil(command.passwordForStdin)
    }

    func test_ZipCrypto指定時はmemオプションが付きパスワードは標準入力へ回る() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")
        let output = URL(fileURLWithPath: "/Users/taro/Documents/report.zip")

        let command = SevenZipCommand.build(
            executable: executable,
            inputs: [input],
            output: output,
            encryption: .zipCrypto(password: "himitsu123")
        )

        XCTAssertEqual(
            command.arguments,
            ["a", "-tzip", "-bsp1", "-bb1", "-y", "-mem=ZipCrypto", "-p",
             "/Users/taro/Documents/report.zip", "report.txt"]
        )
        XCTAssertEqual(command.passwordForStdin, "himitsu123")
        XCTAssertFalse(
            command.arguments.contains("himitsu123"),
            "パスワードがプロセス引数に載らないこと"
        )
    }

    func test_AES256指定時はmemAES256が付く() {
        let input = URL(fileURLWithPath: "/Users/taro/Documents/report.txt")
        let output = URL(fileURLWithPath: "/Users/taro/Documents/report.zip")

        let command = SevenZipCommand.build(
            executable: executable,
            inputs: [input],
            output: output,
            encryption: .aes256(password: "himitsu123")
        )

        XCTAssertTrue(command.arguments.contains("-mem=AES256"))
        XCTAssertEqual(command.passwordForStdin, "himitsu123")
    }

    func test_複数入力は作業ディレクトリからの相対名で渡す() {
        let inputs = [
            URL(fileURLWithPath: "/Users/taro/Documents/report.txt"),
            URL(fileURLWithPath: "/Users/taro/Documents/photos", isDirectory: true),
        ]
        let output = URL(fileURLWithPath: "/Users/taro/Documents/アーカイブ.zip")

        let command = SevenZipCommand.build(
            executable: executable,
            inputs: inputs,
            output: output,
            encryption: .none
        )

        XCTAssertEqual(command.arguments.suffix(2), ["report.txt", "photos"])
    }
}
