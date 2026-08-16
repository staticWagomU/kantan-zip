import Foundation

/// UI層の入口。入力URLから出力先決定→エントリ数カウント→zip実行までを束ねる。
public enum ZipService {
    /// 圧縮を実行し、作成したzipのURLを返す。onProgressには0.0〜1.0を通知する。
    @discardableResult
    public static func compress(
        inputs: [URL],
        password: String?,
        outputOverride: URL? = nil,
        onProgress: @escaping (Double) -> Void
    ) throws -> URL {
        let output = outputOverride ?? OutputPathResolver.resolve(
            inputs: inputs,
            fileExists: { FileManager.default.fileExists(atPath: $0.path) }
        )
        let totalEntryCount = FileCounter.countEntries(inputs: inputs)
        let command = ZipCommand.build(inputs: inputs, output: output, password: password)

        var parser = ZipProgressParser(totalEntryCount: totalEntryCount)
        try ZipRunner.run(command: command) { line in
            parser.consume(line: line)
            onProgress(parser.fraction)
        }
        onProgress(1.0)
        return output
    }
}
