import Foundation

/// 出力先zipのパス決定。Finderの「圧縮」と同じく元ファイルと同じ場所に作る。
/// ファイル存在チェックはクロージャ注入(fileExists)でテスト可能にしている。
public enum OutputPathResolver {
    public static func resolve(inputs: [URL], fileExists: (URL) -> Bool) -> URL {
        let input = inputs[0]
        let candidate: URL
        if inputs.count == 1 {
            candidate = input.deletingPathExtension().appendingPathExtension("zip")
        } else {
            candidate = input.deletingLastPathComponent().appendingPathComponent("アーカイブ.zip")
        }
        return avoidingCollision(candidate, fileExists: fileExists)
    }

    /// Finderと同じく "name 2.zip", "name 3.zip" と空くまで連番を上げる
    private static func avoidingCollision(_ candidate: URL, fileExists: (URL) -> Bool) -> URL {
        guard fileExists(candidate) else { return candidate }
        let directory = candidate.deletingLastPathComponent()
        let baseName = candidate.deletingPathExtension().lastPathComponent
        var number = 2
        while true {
            let numbered = directory.appendingPathComponent("\(baseName) \(number).zip")
            if !fileExists(numbered) { return numbered }
            number += 1
        }
    }
}
