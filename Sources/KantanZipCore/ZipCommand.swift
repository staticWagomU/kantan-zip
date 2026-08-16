import Foundation

/// /usr/bin/zip に渡す引数の組み立て（純粋ロジック、Process実行はZipRunnerが担う）
public struct ZipCommand: Equatable {
    public let executablePath = "/usr/bin/zip"
    public let workingDirectory: URL
    public let arguments: [String]

    /// zipは作業ディレクトリからの相対パスでエントリ名を記録するため、
    /// 入力ファイルの親をworkingDirectoryにしてファイル名だけを渡す。
    public static func build(inputs: [URL], output: URL, password: String?) -> ZipCommand {
        let workingDirectory = inputs[0].deletingLastPathComponent()
        let passwordOptions = password.map { ["-P", $0] } ?? []
        let arguments = ["-r", "-y"] + passwordOptions + [output.path] + inputs.map(\.lastPathComponent)
        return ZipCommand(workingDirectory: workingDirectory, arguments: arguments)
    }
}
