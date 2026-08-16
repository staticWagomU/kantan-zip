import Foundation

/// UI層の入口。出力先決定→7zz実行→進捗通知までを束ねる。
public enum ZipService {
    /// 圧縮を実行し、作成したzipのURLを返す。onProgressには0.0〜1.0を通知する。
    @discardableResult
    public static func compress(
        sevenZipExecutable: URL,
        inputs: [URL],
        encryption: ZipEncryption,
        outputOverride: URL? = nil,
        onProgress: @escaping (Double) -> Void
    ) throws -> URL {
        let output = outputOverride ?? OutputPathResolver.resolve(
            inputs: inputs,
            fileExists: { FileManager.default.fileExists(atPath: $0.path) }
        )
        let command = SevenZipCommand.build(
            executable: sevenZipExecutable,
            inputs: inputs,
            output: output,
            encryption: encryption
        )

        var parser = SevenZipProgressParser()
        try SevenZipRunner.run(command: command) { chunk in
            parser.consume(chunk: chunk)
            onProgress(parser.fraction)
        }
        onProgress(1.0)
        return output
    }
}
