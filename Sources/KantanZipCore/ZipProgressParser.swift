import Foundation

/// zipコマンドのstdout("  adding: <entry> ...")を数えて進捗率を出す。
/// zip自体は進捗APIを持たないため、事前に数えた総エントリ数との比で近似する。
public struct ZipProgressParser {
    public let totalEntryCount: Int
    public private(set) var addedCount = 0

    public init(totalEntryCount: Int) {
        self.totalEntryCount = totalEntryCount
    }

    public var fraction: Double {
        guard totalEntryCount > 0 else { return 0 }
        return Double(addedCount) / Double(totalEntryCount)
    }

    public mutating func consume(line: String) {
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("adding:") {
            addedCount += 1
        }
    }
}
