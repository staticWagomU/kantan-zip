import Foundation

/// パスワードの保管先。実物はKeychain、テストではメモリ上の実装に差し替える。
public protocol PasswordVault {
    func save(password: String, for id: String) throws
    func password(for id: String) throws -> String?
    func delete(for id: String) throws
}

/// 圧縮1件分の記録。パスワードそのものは持たない（保管庫側にある）。
public struct CompressionRecord: Codable, Identifiable, Equatable {
    public let id: UUID
    public let zipPath: String
    public let createdAt: Date
    public let hasPassword: Bool

    public var fileName: String { (zipPath as NSString).lastPathComponent }

    /// zipが削除・移動されていないか
    public var stillExists: Bool { FileManager.default.fileExists(atPath: zipPath) }
}

/// 「どのファイルにどのパスワードを付けたか」を後から確認できるようにする履歴。
///
/// パスワードは履歴ファイルには書かず、必ずPasswordVault(実物はKeychain)に預ける。
/// 平文で置くと、パスワード付きzipにした意味がなくなるため。
public final class HistoryStore {
    /// 際限なく貯めるとパスワードが残り続けるリスクになるので上限を設ける
    public static let maximumRecordCount = 100

    private let fileURL: URL
    private let vault: PasswordVault
    private var storedRecords: [CompressionRecord]

    public init(fileURL: URL, vault: PasswordVault) {
        self.fileURL = fileURL
        self.vault = vault
        self.storedRecords = Self.load(from: fileURL)
    }

    /// 新しい順に並んだ履歴
    public func records() -> [CompressionRecord] {
        storedRecords.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    public func record(zipPath: String, password: String?, createdAt: Date) throws
        -> CompressionRecord
    {
        let record = CompressionRecord(
            id: UUID(),
            zipPath: zipPath,
            createdAt: createdAt,
            hasPassword: password != nil
        )
        if let password {
            try vault.save(password: password, for: record.id.uuidString)
        }
        storedRecords.append(record)
        try pruneOverflow()
        try persist()
        return record
    }

    public func password(for record: CompressionRecord) throws -> String? {
        guard record.hasPassword else { return nil }
        return try vault.password(for: record.id.uuidString)
    }

    public func delete(_ record: CompressionRecord) throws {
        try vault.delete(for: record.id.uuidString)
        storedRecords.removeAll { $0.id == record.id }
        try persist()
    }

    public func deleteAll() throws {
        for record in storedRecords {
            try vault.delete(for: record.id.uuidString)
        }
        storedRecords.removeAll()
        try persist()
    }

    private func pruneOverflow() throws {
        guard storedRecords.count > Self.maximumRecordCount else { return }
        let sorted = storedRecords.sorted { $0.createdAt > $1.createdAt }
        let keep = Array(sorted.prefix(Self.maximumRecordCount))
        let keepIDs = Set(keep.map(\.id))
        for dropped in storedRecords where !keepIDs.contains(dropped.id) {
            try vault.delete(for: dropped.id.uuidString)
        }
        storedRecords = keep
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(storedRecords)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func load(from fileURL: URL) -> [CompressionRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([CompressionRecord].self, from: data)) ?? []
    }
}
