import XCTest
@testable import KantanZipCore

/// 実際のキーチェーンを使う統合テスト。
/// テスト専用のserviceを使い、後始末で必ず消す。
final class KeychainPasswordVaultTests: XCTestCase {
    private var vault: KeychainPasswordVault!
    private var id: String!

    override func setUpWithError() throws {
        vault = KeychainPasswordVault(service: "com.staticwagomu.kantanzip.tests")
        id = UUID().uuidString
    }

    override func tearDownWithError() throws {
        try? vault.delete(for: id)
    }

    func test_保存したパスワードを取り出せる() throws {
        try vault.save(password: "himitsu123", for: id)

        XCTAssertEqual(try vault.password(for: id), "himitsu123")
    }

    func test_存在しないIDはnilを返す() throws {
        XCTAssertNil(try vault.password(for: UUID().uuidString))
    }

    func test_同じIDに保存し直すと上書きされる() throws {
        try vault.save(password: "old", for: id)

        try vault.save(password: "new", for: id)

        XCTAssertEqual(try vault.password(for: id), "new")
    }

    func test_削除するとnilになる() throws {
        try vault.save(password: "himitsu123", for: id)

        try vault.delete(for: id)

        XCTAssertNil(try vault.password(for: id))
    }

    func test_存在しないIDを削除してもエラーにならない() throws {
        XCTAssertNoThrow(try vault.delete(for: UUID().uuidString))
    }

    func test_日本語や記号を含むパスワードも往復できる() throws {
        let password = "パス🔐word!@#$%^&*()_+"

        try vault.save(password: password, for: id)

        XCTAssertEqual(try vault.password(for: id), password)
    }
}
