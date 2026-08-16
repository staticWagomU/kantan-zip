import AppKit
import Foundation
import KantanZipCore

@MainActor
final class CompressionViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case compressing(progress: Double)
        case done(zipPath: String)
        case failed(message: String)
    }

    @Published var phase: Phase = .idle
    @Published var password = ""
    @Published var usePassword = false
    @Published var useStrongEncryption = false
    @Published private(set) var history: [CompressionRecord] = []

    private let store: HistoryStore

    init(store: HistoryStore = .applicationDefault) {
        self.store = store
        self.history = store.records()
    }

    /// alwaysAskOutputLocation: true なら毎回保存ダイアログを出す。
    /// falseでも、複数選択時は名前が自明でないのでダイアログを出す。
    func compress(urls: [URL], alwaysAskOutputLocation: Bool) {
        guard !urls.isEmpty else { return }
        if case .compressing = phase { return }

        guard let sevenZip = SevenZipLocator.locate() else {
            phase = .failed(message: "圧縮プログラム(7zz)が見つかりません。アプリを再インストールしてください。")
            return
        }

        var outputOverride: URL?
        if alwaysAskOutputLocation || urls.count > 1 {
            guard let chosen = promptSaveLocation(defaultURL: defaultOutput(for: urls)) else { return }
            outputOverride = chosen
        }

        let encryption = currentEncryption()
        let recordedPassword = encryption.password
        phase = .compressing(progress: 0)
        Task.detached { [encryption, outputOverride] in
            do {
                let output = try ZipService.compress(
                    sevenZipExecutable: sevenZip,
                    inputs: urls,
                    encryption: encryption,
                    outputOverride: outputOverride
                ) { fraction in
                    Task { @MainActor in
                        self.phase = .compressing(progress: fraction)
                    }
                }
                await MainActor.run {
                    self.finish(zipPath: output.path, password: recordedPassword)
                }
            } catch {
                await MainActor.run { self.phase = .failed(message: error.localizedDescription) }
            }
        }
    }

    func revealInFinder(path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    func reset() {
        phase = .idle
    }

    func generatePassword() {
        password = PasswordGenerator.generate()
        usePassword = true
        copyToClipboard(password)
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - 履歴

    func password(for record: CompressionRecord) -> String? {
        // キーチェーンが読めなくてもアプリを止めたくないのでnilに畳む
        try? store.password(for: record)
    }

    func delete(_ record: CompressionRecord) {
        try? store.delete(record)
        history = store.records()
    }

    func deleteAllHistory() {
        try? store.deleteAll()
        history = store.records()
    }

    // MARK: - 内部

    private func finish(zipPath: String, password: String?) {
        phase = .done(zipPath: zipPath)
        // 履歴の保存に失敗しても圧縮自体は成功しているので、完了表示は消さない
        try? store.record(zipPath: zipPath, password: password, createdAt: Date())
        history = store.records()
    }

    private func currentEncryption() -> ZipEncryption {
        guard usePassword, !password.isEmpty else { return .none }
        return useStrongEncryption
            ? .aes256(password: password)
            : .zipCrypto(password: password)
    }

    private func defaultOutput(for urls: [URL]) -> URL {
        OutputPathResolver.resolve(
            inputs: urls,
            fileExists: { FileManager.default.fileExists(atPath: $0.path) }
        )
    }

    private func promptSaveLocation(defaultURL: URL) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.directoryURL = defaultURL.deletingLastPathComponent()
        panel.nameFieldStringValue = defaultURL.lastPathComponent
        panel.title = "zipの保存先とファイル名"
        panel.prompt = "作成"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
