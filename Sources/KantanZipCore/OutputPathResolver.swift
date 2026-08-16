import Foundation

/// 出力先zipのパス決定。Finderの「圧縮」と同じく元ファイルと同じ場所に作る。
/// ファイル存在チェックはクロージャ注入(fileExists)でテスト可能にしている。
public enum OutputPathResolver {
    public static func resolve(inputs: [URL], fileExists: (URL) -> Bool) -> URL {
        let input = inputs[0]
        if inputs.count == 1 {
            return input.deletingPathExtension().appendingPathExtension("zip")
        }
        return input.deletingLastPathComponent().appendingPathComponent("アーカイブ.zip")
    }
}
