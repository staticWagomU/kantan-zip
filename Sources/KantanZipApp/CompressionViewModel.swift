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

    /// askOutputLocation: true なら毎回保存ダイアログ、false なら元ファイルと同じ場所
    func compress(urls: [URL], askOutputLocation: Bool) {
        guard !urls.isEmpty else { return }
        if case .compressing = phase { return }

        let effectivePassword = usePassword && !password.isEmpty ? password : nil

        var outputOverride: URL?
        if askOutputLocation {
            guard let chosen = promptSaveLocation(defaultURL: defaultOutput(for: urls)) else { return }
            outputOverride = chosen
        }

        phase = .compressing(progress: 0)
        Task.detached { [effectivePassword, outputOverride] in
            do {
                let output = try ZipService.compress(
                    inputs: urls,
                    password: effectivePassword,
                    outputOverride: outputOverride
                ) { fraction in
                    Task { @MainActor in
                        self.phase = .compressing(progress: fraction)
                    }
                }
                await MainActor.run { self.phase = .done(zipPath: output.path) }
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
        panel.title = "zipの保存先を選択"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
