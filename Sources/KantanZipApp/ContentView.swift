import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = CompressionViewModel()
    @AppStorage("askOutputLocation") private var askOutputLocation = false
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            dropZone
            passwordSection
            outputSection
            statusSection
        }
        .padding(24)
        .frame(width: 420)
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 40))
                .foregroundStyle(isDropTargeted ? Color.accentColor : .secondary)
            Text("ここにファイルやフォルダをドロップ")
                .foregroundStyle(.secondary)
            Button("ファイルを選択…") { selectFiles() }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            viewModel.compress(urls: urls, askOutputLocation: askOutputLocation)
            return true
        } isTargeted: { isDropTargeted = $0 }
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("パスワードを付ける", isOn: $viewModel.usePassword)
            if viewModel.usePassword {
                SecureField("パスワード", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                Toggle("強力な暗号化を使う（AES-256）", isOn: $viewModel.useStrongEncryption)
                Text(viewModel.useStrongEncryption
                     ? "開く側に 7-Zip や Keka などのアプリが必要です。Macの標準機能では開けません。"
                     : "受け取った人がダブルクリックでそのまま開けます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var outputSection: some View {
        Toggle("保存先を毎回選ぶ（オフ: 元のファイルと同じ場所）", isOn: $askOutputLocation)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case let .compressing(progress):
            ProgressView(value: progress) {
                Text("圧縮中… \(Int(progress * 100))%")
            }
        case let .done(zipPath):
            HStack {
                Label("作成しました: \((zipPath as NSString).lastPathComponent)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Button("Finderで表示") { viewModel.revealInFinder(path: zipPath) }
                Button("閉じる") { viewModel.reset() }
            }
        case let .failed(message):
            HStack(alignment: .top) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Spacer()
                Button("閉じる") { viewModel.reset() }
            }
        }
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "圧縮"
        if panel.runModal() == .OK {
            viewModel.compress(urls: panel.urls, askOutputLocation: askOutputLocation)
        }
    }
}
