import Foundation

/// 進捗率の分母となる総エントリ数を事前に数える。
/// zip -r はフォルダ自身も1エントリ("adding: photos/")として出力するため、
/// ディレクトリもカウントに含めてadding行の数と一致させる。
public enum FileCounter {
    public static func countEntries(inputs: [URL]) -> Int {
        let fileManager = FileManager.default
        var count = 0
        for input in inputs {
            count += 1
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: input.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  let enumerator = fileManager.enumerator(at: input, includingPropertiesForKeys: nil)
            else { continue }
            count += enumerator.allObjects.count
        }
        return count
    }
}
