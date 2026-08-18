import XCTest
@testable import KantanZipCore

final class PasswordAutofillTests: XCTestCase {
    func test_パスワード付きで空欄なら生成する() {
        XCTAssertTrue(PasswordAutofill.shouldFill(usePassword: true, currentPassword: ""))
    }

    func test_空白だけの欄は空と同じ扱いで生成する() {
        XCTAssertTrue(PasswordAutofill.shouldFill(usePassword: true, currentPassword: "   \n"))
    }

    func test_既に入っているパスワードは上書きしない() {
        XCTAssertFalse(PasswordAutofill.shouldFill(usePassword: true, currentPassword: "keep-me"))
    }

    func test_パスワードなしなら生成しない() {
        XCTAssertFalse(PasswordAutofill.shouldFill(usePassword: false, currentPassword: ""))
    }

    func test_初回のファイル選択では空欄にパスワードを入れて表示する() {
        let next = PasswordAutofill.afterSelectingFiles(
            usePassword: true,
            current: .init(password: "", isVisible: false),
            isNextJob: false,
            generate: { "generated-1" }
        )

        XCTAssertEqual(next, .init(password: "generated-1", isVisible: true))
    }

    func test_追加選択や選び直しでは既存のパスワードを保つ() {
        let next = PasswordAutofill.afterSelectingFiles(
            usePassword: true,
            current: .init(password: "keep-me", isVisible: false),
            isNextJob: false,
            generate: { "should-not-be-used" }
        )

        XCTAssertEqual(next, .init(password: "keep-me", isVisible: false))
    }

    func test_完了後の次のzipでは前のパスワードを捨てて作り直す() {
        let next = PasswordAutofill.afterSelectingFiles(
            usePassword: true,
            current: .init(password: "old-password", isVisible: true),
            isNextJob: true,
            generate: { "generated-2" }
        )

        XCTAssertEqual(next, .init(password: "generated-2", isVisible: true))
    }

    func test_パスワードを付けないときは次のzipでも生成しない() {
        let next = PasswordAutofill.afterSelectingFiles(
            usePassword: false,
            current: .init(password: "old-password", isVisible: true),
            isNextJob: true,
            generate: { "should-not-be-used" }
        )

        XCTAssertEqual(next, .init(password: "", isVisible: false))
    }
}
