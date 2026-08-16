import Foundation

public enum SevenZipRunnerError: LocalizedError {
    case executableNotFound(URL)
    case failed(exitCode: Int32, message: String)

    public var errorDescription: String? {
        switch self {
        case let .executableNotFound(url):
            return "圧縮プログラムが見つかりません: \(url.path)"
        case let .failed(_, message):
            return message.isEmpty ? "圧縮に失敗しました" : "圧縮に失敗しました: \(message)"
        }
    }
}

/// 同梱した7zzをProcessで実行する薄いI/O層。
/// パスワードは引数ではなく標準入力から渡すため、プロセス一覧に露出しない。
public enum SevenZipRunner {
    public static func run(
        command: SevenZipCommand,
        onOutputChunk: ((String) -> Void)? = nil
    ) throws {
        guard FileManager.default.isExecutableFile(atPath: command.executableURL.path) else {
            throw SevenZipRunnerError.executableNotFound(command.executableURL)
        }

        let process = Process()
        process.executableURL = command.executableURL
        process.arguments = command.arguments
        process.currentDirectoryURL = command.workingDirectory

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // 7zzはバックスペースで進捗表示を書き換えるため行単位に区切れない。
        // 読めた塊をそのまま渡し、区切りの解釈はパーサー側に任せる。
        var collectedOutput = ""
        let finishedReading = DispatchSemaphore(value: 0)
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                finishedReading.signal()
                return
            }
            if let chunk = String(data: data, encoding: .utf8) {
                collectedOutput += chunk
                onOutputChunk?(chunk)
            }
        }

        try process.run()

        // -p を値なしで渡しているので、7zzはここからパスワードを読む。
        // パスワードが無い場合も即座に閉じないと7zzが入力待ちで止まる。
        if let password = command.passwordForStdin {
            stdinPipe.fileHandleForWriting.write(Data((password + "\n").utf8))
        }
        try? stdinPipe.fileHandleForWriting.close()

        process.waitUntilExit()
        finishedReading.wait()

        if process.terminationStatus != 0 {
            let stderrData = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
            let stderrText = String(data: stderrData, encoding: .utf8) ?? ""
            let message = stderrText.isEmpty ? collectedOutput : stderrText
            throw SevenZipRunnerError.failed(
                exitCode: process.terminationStatus,
                message: Self.summarize(message)
            )
        }
    }

    /// 7zzの出力は冗長なので、エラー表示用にERROR行だけ拾って短くする
    private static func summarize(_ message: String) -> String {
        let errorLines = message
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.contains("ERROR") || $0.contains("Cannot") }
        let picked = errorLines.isEmpty ? message : errorLines.joined(separator: " / ")
        return picked.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
