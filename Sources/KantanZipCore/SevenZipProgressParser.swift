import Foundation

/// 7zz(-bsp1)が出力する "NN%" から進捗を読み取る。
/// 圧縮済みバイト数ベースなので、ファイル数を数える方式より実感に近い。
/// 7zzはバックスペースで表示を書き換えるため行単位に区切れない。
/// そのため受け取った塊(チャンク)ごとに最後の%を採用する。
public struct SevenZipProgressParser {
    public private(set) var fraction: Double = 0

    public init() {}

    public mutating func consume(chunk: String) {
        guard let percent = Self.lastPercentage(in: chunk) else { return }
        // 7zzは新しいファイルに移る際に一時的に小さい値を出すことがあるため後戻りさせない
        fraction = max(fraction, min(Double(percent) / 100.0, 1.0))
    }

    private static func lastPercentage(in chunk: String) -> Int? {
        var lastValue: Int?
        var digits = ""
        for character in chunk {
            if character.isNumber {
                digits.append(character)
            } else {
                if character == "%", let value = Int(digits) {
                    lastValue = value
                }
                digits = ""
            }
        }
        return lastValue
    }
}
