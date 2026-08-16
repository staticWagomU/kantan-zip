import Foundation

/// 同梱した7zzの場所を解決する。
/// .app実行時は Contents/Resources/7zz、`swift run` などの開発時は
/// リポジトリの Vendor/7zz/7zz にフォールバックする。
enum SevenZipLocator {
    static func locate() -> URL? {
        if let bundled = Bundle.main.url(forResource: "7zz", withExtension: nil),
           FileManager.default.isExecutableFile(atPath: bundled.path) {
            return bundled
        }
        let developmentPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // KantanZipApp
            .deletingLastPathComponent()  // Sources
            .deletingLastPathComponent()  // リポジトリルート
            .appendingPathComponent("Vendor/7zz/7zz")
        return FileManager.default.isExecutableFile(atPath: developmentPath.path)
            ? developmentPath
            : nil
    }
}
