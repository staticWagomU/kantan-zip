import XCTest
@testable import KantanZipCore

/// テスト用のパスワード保管庫。実物はKeychainを使う。
private final class InMemoryPasswordVault: PasswordVault {
    private var storage: [String: String] = [:]

    func save(password: String, for id: String) throws { storage[id] = password }
    func password(for id: String) throws -> String? { storage[id] }
    func delete(for id: String) throws { storage[id] = nil }
}

final class HistoryStoreTests: XCTestCase {
    private var tempDir: URL!
    private var vault: InMemoryPasswordVault!
    private var store: HistoryStore!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HistoryStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        vault = InMemoryPasswordVault()
        store = HistoryStore(fileURL: tempDir.appendingPathComponent("history.json"), vault: vault)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_圧縮結果を記録して一覧で取り出せる() throws {
        try store.record(zipPath: "/Users/taro/報告書.zip", password: nil, createdAt: Date())

        let records = store.records()

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].fileName, "報告書.zip")
        XCTAssertFalse(records[0].hasPassword)
    }

    func test_新しい記録が先頭に来る() throws {
        let base = Date()
        try store.record(zipPath: "/a/古い.zip", password: nil, createdAt: base)
        try store.record(zipPath: "/a/新しい.zip", password: nil, createdAt: base.addingTimeInterval(60))

        XCTAssertEqual(store.records().map(\.fileName), ["新しい.zip", "古い.zip"])
    }

    func test_パスワードは履歴ファイルではなく保管庫に入る() throws {
        let record = try store.record(
            zipPath: "/a/秘密.zip", password: "himitsu123", createdAt: Date())

        XCTAssertTrue(record.hasPassword)
        XCTAssertEqual(try store.password(for: record), "himitsu123")

        // 履歴ファイル自体にパスワードが平文で残っていないこと
        let raw = try String(contentsOf: tempDir.appendingPathComponent("history.json"), encoding: .utf8)
        XCTAssertFalse(raw.contains("himitsu123"), "履歴ファイルにパスワードが平文で保存されている")
    }

    func test_保存した履歴は読み込み直しても残る() throws {
        try store.record(zipPath: "/a/報告書.zip", password: "pw", createdAt: Date())

        let reloaded = HistoryStore(
            fileURL: tempDir.appendingPathComponent("history.json"), vault: vault)

        XCTAssertEqual(reloaded.records().map(\.fileName), ["報告書.zip"])
        XCTAssertEqual(try reloaded.password(for: reloaded.records()[0]), "pw")
    }

    func test_削除するとパスワードも保管庫から消える() throws {
        let record = try store.record(zipPath: "/a/秘密.zip", password: "pw", createdAt: Date())

        try store.delete(record)

        XCTAssertTrue(store.records().isEmpty)
        XCTAssertNil(try vault.password(for: record.id.uuidString))
    }

    func test_全削除でパスワードもすべて消える() throws {
        let first = try store.record(zipPath: "/a/1.zip", password: "pw1", createdAt: Date())
        let second = try store.record(zipPath: "/a/2.zip", password: "pw2", createdAt: Date())

        try store.deleteAll()

        XCTAssertTrue(store.records().isEmpty)
        XCTAssertNil(try vault.password(for: first.id.uuidString))
        XCTAssertNil(try vault.password(for: second.id.uuidString))
    }

    func test_履歴は上限を超えると古いものから捨てられる() throws {
        let base = Date()
        var oldestIDs: [String] = []
        for index in 0..<(HistoryStore.maximumRecordCount + 5) {
            let record = try store.record(
                zipPath: "/a/\(index).zip",
                password: "pw\(index)",
                createdAt: base.addingTimeInterval(Double(index))
            )
            if index < 5 { oldestIDs.append(record.id.uuidString) }
        }

        let records = store.records()
        XCTAssertEqual(records.count, HistoryStore.maximumRecordCount)
        XCTAssertEqual(records.last?.fileName, "5.zip", "古い0〜4が捨てられていること")
        for id in oldestIDs {
            XCTAssertNil(try vault.password(for: id), "捨てた記録のパスワードは残さない")
        }
    }
}
