import AppKit
import Foundation
import KantanZipCore

@MainActor
final class CompressionViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case compressing(progress: Double)
        case done(zipPath: String, password: String?)
        case failed(message: String)
    }

    @Published var phase: Phase = .idle
    /// 選んだファイル／フォルダ。ドロップや選択ダイアログで更新し、作成ボタンで圧縮する。
    @Published private(set) var selectedURLs: [URL] = []
    @Published var password = ""
    /// 社内利用ではパスワード付きが前提なので、最初からオン。
    @Published var usePassword = true
    @Published var useStrongEncryption = false
    @Published var isPasswordVisible = false
    /// 「パスワードを付けたいが未入力」など、作成直前の案内。
    @Published private(set) var validationMessage: String?
    @Published private(set) var history: [CompressionRecord] = []
    /// 自動生成した直後など、コピー済みであることを短く伝える。
    @Published private(set) var clipboardHint: String?

    private let store: HistoryStore
    private var clipboardHintTask: Task<Void, Never>?

    var canCreate: Bool {
        !selectedURLs.isEmpty && !isCompressing
    }

    var isCompressing: Bool {
        if case .compressing = phase { return true }
        return false
    }

    var selectedSummary: String {
        switch selectedURLs.count {
        case 0:
            return ""
        case 1:
            return selectedURLs[0].lastPathComponent
        default:
            let first = selectedURLs[0].lastPathComponent
            return "\(first) ほか\(selectedURLs.count - 1)件"
        }
    }

    init(store: HistoryStore = .applicationDefault) {
        self.store = store
        self.history = store.records()
    }

    func setSelectedURLs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        if case .compressing = phase { return }
        let isNextJob: Bool = {
            if case .done = phase { return true }
            return false
        }()
        selectedURLs = urls
        validationMessage = nil
        // 完了／失敗のあとで選び直したら、次の作業に入れるよう状態を戻す
        if case .done = phase { phase = .idle }
        if case .failed = phase { phase = .idle }
        applyAutofill(isNextJob: isNextJob)
    }

    func clearSelection() {
        guard !isCompressing else { return }
        selectedURLs = []
        validationMessage = nil
    }

    /// alwaysAskOutputLocation: true なら毎回保存ダイアログを出す。
    /// falseでも、複数選択時は名前が自明でないのでダイアログを出す。
    func createZip(alwaysAskOutputLocation: Bool) {
        guard !selectedURLs.isEmpty else {
            validationMessage = "先にファイルやフォルダを選んでください。"
            return
        }
        if case .compressing = phase { return }

        if usePassword && password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "パスワードを入力するか、「自動で作る」で作り直してください。"
            return
        }
        validationMessage = nil

        guard let sevenZip = SevenZipLocator.locate() else {
            phase = .failed(message: "圧縮プログラムが見つかりません。アプリを再インストールしてください。")
            return
        }

        var outputOverride: URL?
        if alwaysAskOutputLocation || selectedURLs.count > 1 {
            guard let chosen = promptSaveLocation(defaultURL: defaultOutput(for: selectedURLs)) else {
                return
            }
            outputOverride = chosen
        }

        let encryption = currentEncryption()
        let recordedPassword = encryption.password
        let urls = selectedURLs
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
                await MainActor.run { self.phase = .failed(message: friendlyMessage(for: error)) }
            }
        }
    }

    func revealInFinder(path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    /// 完了画面から次の圧縮へ進む。パスワードは捨て、次のファイル選択で作り直す。
    func startAnother() {
        selectedURLs = []
        password = ""
        isPasswordVisible = false
        validationMessage = nil
        clipboardHint = nil
        phase = .idle
    }

    func dismissFailure() {
        phase = .idle
        validationMessage = nil
    }

    func generatePassword() {
        applyGeneratedPassword()
        copyToClipboard(password, hint: "パスワードをコピーしました。相手には別の方法で伝えてください。")
    }

    func copyCurrentPassword() {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        copyToClipboard(trimmed, hint: "パスワードをコピーしました。相手には別の方法で伝えてください。")
    }

    func clearValidation() {
        validationMessage = nil
    }

    func copyToClipboard(_ text: String, hint: String? = nil) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        if let hint {
            showClipboardHint(hint)
        }
    }

    func copyPasswordAgain(_ password: String) {
        copyToClipboard(password, hint: "パスワードをコピーしました。")
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

    /// 欄が空のときだけ生成する。追加選択や選び直しでは既存の値を守る。
    /// クリップボードには入れない（ドロップのたびにコピーすると他の文面を上書きするため）。
    private func applyAutofill(isNextJob: Bool) {
        let next = PasswordAutofill.afterSelectingFiles(
            usePassword: usePassword,
            current: .init(password: password, isVisible: isPasswordVisible),
            isNextJob: isNextJob
        )
        password = next.password
        isPasswordVisible = next.isVisible
    }

    private func applyGeneratedPassword() {
        password = PasswordGenerator.generate()
        usePassword = true
        isPasswordVisible = true
        clearValidation()
    }

    private func finish(zipPath: String, password: String?) {
        phase = .done(zipPath: zipPath, password: password)
        // 履歴の保存に失敗しても圧縮自体は成功しているので、完了表示は消さない
        try? store.record(zipPath: zipPath, password: password, createdAt: Date())
        history = store.records()
    }

    private func currentEncryption() -> ZipEncryption {
        guard usePassword else { return .none }
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        return useStrongEncryption
            ? .aes256(password: trimmed)
            : .zipCrypto(password: trimmed)
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
        panel.title = "zipの名前と保存先"
        panel.message = "分かりやすい名前を付けてください（例: 見積書_2026年3月.zip）"
        panel.prompt = "作成"
        panel.nameFieldLabel = "名前:"
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func showClipboardHint(_ message: String) {
        clipboardHintTask?.cancel()
        clipboardHint = message
        clipboardHintTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            clipboardHint = nil
        }
    }
}

/// 技術的なエラー文を、そのまま見せても困らない日本語に寄せる。
private func friendlyMessage(for error: Error) -> String {
    let text = error.localizedDescription
    if text.isEmpty {
        return "圧縮に失敗しました。ファイルが開いたままになっていないか確認して、もう一度お試しください。"
    }
    return text
}
