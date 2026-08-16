import Foundation

public enum ZipRunnerError: LocalizedError {
    case failed(exitCode: Int32, message: String)

    public var errorDescription: String? {
        switch self {
        case let .failed(exitCode, message):
            return "zipコマンドが失敗しました (終了コード\(exitCode)): \(message)"
        }
    }
}

/// /usr/bin/zip をProcessで実行する薄いI/O層。
/// stdoutを1行ずつコールバックし、呼び出し側(UI)が進捗表示に使う。
public enum ZipRunner {
    public static func run(command: ZipCommand, onOutputLine: ((String) -> Void)? = nil) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executablePath)
        process.arguments = command.arguments
        process.currentDirectoryURL = command.workingDirectory

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // readabilityHandlerは単一の内部キューで直列に呼ばれるためbufferの排他は不要。
        // EOF(availableDataが空)まで読み切ったことをセマフォで待ってから戻る。
        var buffer = Data()
        let finishedReading = DispatchSemaphore(value: 0)
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                if !buffer.isEmpty, let line = String(data: buffer, encoding: .utf8) {
                    onOutputLine?(line)
                }
                finishedReading.signal()
                return
            }
            buffer.append(data)
            while let newlineIndex = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let lineData = buffer[buffer.startIndex..<newlineIndex]
                buffer.removeSubrange(buffer.startIndex...newlineIndex)
                if let line = String(data: lineData, encoding: .utf8) {
                    onOutputLine?(line)
                }
            }
        }

        try process.run()
        process.waitUntilExit()
        finishedReading.wait()

        if process.terminationStatus != 0 {
            let stderrData = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
            let message = String(data: stderrData, encoding: .utf8) ?? ""
            throw ZipRunnerError.failed(
                exitCode: process.terminationStatus,
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
}
