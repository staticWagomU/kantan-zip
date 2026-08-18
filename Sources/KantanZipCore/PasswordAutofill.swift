import Foundation

/// パスワード欄をいつ自動生成するかのルール。
///
/// クリップボード操作は含めない。ファイル選択のたびにコピーすると、
/// メール文面などを上書きしてしまうため、コピーは明示操作に任せる。
public enum PasswordAutofill {
    public struct Field: Equatable {
        public var password: String
        public var isVisible: Bool

        public init(password: String, isVisible: Bool) {
            self.password = password
            self.isVisible = isVisible
        }
    }

    /// パスワード付きで、欄が空（空白のみを含む）なら自動生成する。
    /// 既に入っている値は、追加選択や選び直しでも上書きしない。
    public static func shouldFill(usePassword: Bool, currentPassword: String) -> Bool {
        usePassword && currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// ファイル選択後のパスワード欄。
    /// - isNextJob: 直前のzipが完了したあとの次作業。前のパスワードは捨てて作り直す。
    public static func afterSelectingFiles(
        usePassword: Bool,
        current: Field,
        isNextJob: Bool,
        generate: () -> String = { PasswordGenerator.generate() }
    ) -> Field {
        var field = current
        if isNextJob {
            field.password = ""
            field.isVisible = false
        }
        guard shouldFill(usePassword: usePassword, currentPassword: field.password) else {
            return field
        }
        field.password = generate()
        field.isVisible = true
        return field
    }
}
