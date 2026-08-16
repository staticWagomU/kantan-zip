import Foundation

/// zipの暗号化方式。互換性(ZipCrypto)と強度(AES-256)はトレードオフの関係にある。
public enum ZipEncryption: Equatable {
    case none
    /// macOS標準のアーカイブユーティリティやWindowsエクスプローラーがそのまま開ける旧方式。
    case zipCrypto(password: String)
    /// 強度は高いが、受け取り側に7-Zip/Keka等が必要（macOS標準のunzipは開けない）。
    case aes256(password: String)

    public var password: String? {
        switch self {
        case .none: return nil
        case let .zipCrypto(password), let .aes256(password): return password
        }
    }

    var methodOptions: [String] {
        switch self {
        case .none: return []
        case .zipCrypto: return ["-mem=ZipCrypto", "-p"]
        case .aes256: return ["-mem=AES256", "-p"]
        }
    }
}

/// 同梱した7zzに渡す引数の組み立て。
/// パスワードは値なしの `-p` を渡して標準入力から流し込むため、
/// `ps` などでプロセス引数から読み取られない。
public struct SevenZipCommand: Equatable {
    public let executableURL: URL
    public let workingDirectory: URL
    public let arguments: [String]
    public let passwordForStdin: String?

    public static func build(
        executable: URL,
        inputs: [URL],
        output: URL,
        encryption: ZipEncryption
    ) -> SevenZipCommand {
        // -bsp1: 進捗を標準出力へ / -bb1: 追加ファイル名を出力 / -y: 確認を全てyes
        let baseOptions = ["a", "-tzip", "-bsp1", "-bb1", "-y"]
        let arguments = baseOptions
            + encryption.methodOptions
            + [output.path]
            + inputs.map(\.lastPathComponent)

        return SevenZipCommand(
            executableURL: executable,
            workingDirectory: inputs[0].deletingLastPathComponent(),
            arguments: arguments,
            passwordForStdin: encryption.password
        )
    }
}
