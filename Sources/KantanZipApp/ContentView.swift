import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CompressionViewModel()
    @AppStorage("askOutputLocation") private var askOutputLocation = false
    @State private var isDropTargeted = false
    @State private var isShowingHistory = false
    @State private var isShowingAdvanced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if case let .done(zipPath, password) = viewModel.phase {
                    successBanner(zipPath: zipPath, password: password)
                }
                if case let .failed(message) = viewModel.phase {
                    failureBanner(message: message)
                }

                fileSection
                passwordSection
                createSection
                advancedSection
                historyLink

                if let hint = viewModel.clipboardHint {
                    Label(hint, systemImage: "doc.on.clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            .padding(20)
            .animation(.easeInOut(duration: 0.2), value: viewModel.clipboardHint)
        }
        .frame(width: 460, height: 560)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingHistory = true
                } label: {
                    Label("履歴", systemImage: "clock.arrow.circlepath")
                }
                .help("過去に作ったzipのパスワードを確認できます")
            }
        }
        .sheet(isPresented: $isShowingHistory) {
            HistoryView(viewModel: viewModel)
        }
    }

    // MARK: - File

    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ファイル")
                .font(.headline)

            if viewModel.selectedURLs.isEmpty {
                dropZone
            } else {
                selectedFilesCard
            }
        }
    }

    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 36))
                .foregroundStyle(isDropTargeted ? Color.accentColor : .secondary)
            Text("ここにファイルやフォルダをドロップ")
                .font(.body.weight(.medium))
            Text("複数まとめてドロップすると、1つのzipになります")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("ファイルを選択…") { selectFiles() }
                .controlSize(.large)
                .disabled(viewModel.isCompressing)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            viewModel.setSelectedURLs(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ファイルのドロップエリア")
    }

    private var selectedFilesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: viewModel.selectedURLs.count == 1 ? "doc.fill" : "doc.on.doc.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedSummary)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Text("\(viewModel.selectedURLs.count)件を1つのzipにまとめます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button("選び直す") {
                    viewModel.clearSelection()
                    selectFiles()
                }
                .controlSize(.small)
                .disabled(viewModel.isCompressing)
            }

            if viewModel.selectedURLs.count <= 5 {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.selectedURLs, id: \.self) { url in
                        Text("・\(url.lastPathComponent)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(.leading, 38)
            }

            HStack {
                Button("追加で選ぶ…") { selectFiles(appending: true) }
                    .controlSize(.small)
                    .disabled(viewModel.isCompressing)
                Spacer()
                Button("クリア", role: .destructive) { viewModel.clearSelection() }
                    .controlSize(.small)
                    .disabled(viewModel.isCompressing)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .dropDestination(for: URL.self) { urls, _ in
            viewModel.setSelectedURLs(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
    }

    // MARK: - Password

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("パスワード")
                .font(.headline)

            Toggle(isOn: $viewModel.usePassword) {
                Text("パスワードを付ける")
            }
            .disabled(viewModel.isCompressing)
            .onChange(of: viewModel.usePassword) { _ in
                viewModel.clearValidation()
            }

            if viewModel.usePassword {
                HStack(spacing: 8) {
                    Group {
                        if viewModel.isPasswordVisible {
                            TextField("パスワードを入力", text: $viewModel.password)
                        } else {
                            SecureField("パスワードを入力", text: $viewModel.password)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isCompressing)
                    .onChange(of: viewModel.password) { _ in
                        viewModel.clearValidation()
                    }

                    Button {
                        viewModel.isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                    }
                    .help(viewModel.isPasswordVisible ? "パスワードを隠す" : "パスワードを表示")
                    .disabled(viewModel.isCompressing)
                }

                HStack(spacing: 8) {
                    Button {
                        viewModel.generatePassword()
                    } label: {
                        Label("自動で作る", systemImage: "key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .help("新しいパスワードを作り、クリップボードにもコピーします")

                    Button("コピー") {
                        viewModel.copyCurrentPassword()
                    }
                    .disabled(viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("いまのパスワードをコピーします")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isCompressing)

                Text("ファイルを選ぶとパスワードが入ります。作り直すときは「自動で作る」を押してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("作ったパスワードは相手に別途伝えてください。zipと同じメールに書くと意味がありません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("パスワードなしでも作れますが、誰でも中身を見られます。社外へ送るときはオンにしてください。")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Create

    private var createSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("作成")
                .font(.headline)

            if let message = viewModel.validationMessage {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            switch viewModel.phase {
            case let .compressing(progress):
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress) {
                        Text("作成中… \(Int(progress * 100))%")
                    }
                    Text("終わるまでこのままお待ちください")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .done:
                Text("上の案内からパスワードのコピーや Finder での確認ができます。続けて作るときは下のボタンを押してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("続けて作る") {
                    viewModel.startAnother()
                }
                .controlSize(.large)
            default:
                Button {
                    viewModel.createZip(alwaysAskOutputLocation: askOutputLocation)
                } label: {
                    Label(
                        viewModel.usePassword ? "パスワード付きzipを作成" : "zipを作成",
                        systemImage: "doc.zipper"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canCreate)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Advanced (通常は隠す)

    private var advancedSection: some View {
        DisclosureGroup("詳細な設定", isExpanded: $isShowingAdvanced) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("保存先とファイル名を毎回選ぶ", isOn: $askOutputLocation)
                        .disabled(viewModel.isCompressing)
                    Text(askOutputLocation
                         ? "作成のたびに、保存場所と名前を確認します。"
                         : "1件だけのときは、元のファイルと同じ場所に自動保存します。複数件のときは名前を確認します。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.usePassword {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("開きやすさ")
                            .font(.subheadline.weight(.medium))
                        Picker("開きやすさ", selection: $viewModel.useStrongEncryption) {
                            Text("相手がそのまま開ける").tag(false)
                            Text("より強固な暗号（専用アプリが必要）").tag(true)
                        }
                        .pickerStyle(.radioGroup)
                        .disabled(viewModel.isCompressing)
                        .labelsHidden()

                        Text(viewModel.useStrongEncryption
                             ? "相手は 7-Zip や Keka などのアプリが必要で、Macの標準機能では開けません。"
                             : "受け取った人はダブルクリックで開けます（パスワードの入力は必要です）。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 8)
        }
        .font(.callout)
    }

    private var historyLink: some View {
        Button {
            isShowingHistory = true
        } label: {
            Text("過去のパスワードを確認…")
        }
        .buttonStyle(.link)
        .help("履歴を開きます")
    }

    // MARK: - Inline success / failure

    private func successBanner(zipPath: String, password: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("作成できました")
                    .font(.headline)
                Spacer()
            }

            Text((zipPath as NSString).lastPathComponent)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            if let password, !password.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("パスワード")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(password)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        Spacer()
                        Button("コピー") {
                            viewModel.copyPasswordAgain(password)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )

                    Text("このパスワードはzipとは別の手段（チャットや電話など）で伝えてください。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.revealInFinder(path: zipPath)
                } label: {
                    Label("Finderで表示", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isShowingHistory = true
                } label: {
                    Text("履歴を開く")
                }
            }

            Text("パスワードを忘れたときは、ツールバーの「履歴」か下のリンクからも確認できます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.green.opacity(0.25))
        )
    }

    private func failureBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("作成できませんでした")
                        .font(.headline)
                    Text(message)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text("よくある原因: 同じ名前のファイルを別のアプリで開いたまま、保存場所に書けない、など。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("閉じる") {
                viewModel.dismissFailure()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.25))
        )
    }

    // MARK: - Helpers

    private func selectFiles(appending: Bool = false) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "圧縮したいファイルやフォルダを選んでください"
        panel.prompt = "選択"
        if panel.runModal() == .OK {
            if appending {
                var merged = viewModel.selectedURLs
                for url in panel.urls where !merged.contains(url) {
                    merged.append(url)
                }
                viewModel.setSelectedURLs(merged)
            } else {
                viewModel.setSelectedURLs(panel.urls)
            }
        }
    }
}
