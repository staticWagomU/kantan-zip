import Foundation

/// zipに付けるパスワードを生成する。
///
/// 記号を含めないのは意図的。パスワードは電話やチャットで口頭伝達されることが多く、
/// 記号は「アンダーバー」「ハイフン」の言い間違いや、環境による入力ミスの原因になる。
/// 強度は記号ではなく長さで確保する。
public enum PasswordGenerator {
    /// 0とO、1とlとI のような紛らわしい文字は除いてある
    private static let uppercase = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
    private static let lowercase = Array("abcdefghijkmnopqrstuvwxyz")
    private static let digits = Array("23456789")

    public static let defaultLength = 16

    public static func generate(length: Int = defaultLength) -> String {
        let all = uppercase + lowercase + digits

        // 種類ごとに最低1文字を入れてから残りを埋める。
        // 全体からランダムに選ぶだけだと「数字が1つもない」パスワードが生まれうる。
        var characters: [Character] = [
            uppercase.randomElement()!,
            lowercase.randomElement()!,
            digits.randomElement()!,
        ]
        if length > characters.count {
            characters += (0..<(length - characters.count)).map { _ in all.randomElement()! }
        }
        return String(characters.shuffled())
    }
}
