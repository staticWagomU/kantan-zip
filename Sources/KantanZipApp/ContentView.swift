import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CompressionViewModel()
    @AppStorage("askOutputLocation") private var askOutputLocation = false
    @State private var isDropTargeted = false
    @State private var isShowingHistory = false
    @State private var isShowingAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch viewModel.phase {
                    case .done(let zipPath, let password):
                        completionSection(zipPath: zipPath, password: password)
                    case .failed(let message):
                        failureSection(message: message)
                    default:
                        workingSections
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 460, height: 560)
        .sheet(isPresented: $isShowingHistory) {
            HistoryView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("KantanZip")
                    .font(.title2.weight(.semibold))
                Text("パスワード付きzipをかんたんに作成")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isShowingHistory = true
            } label: {
                Label("履歴", systemImage: "clock.arrow.circlepath")
            }
            .help("過去に作ったzipのパスワードを確認できます")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Main working flow

    private var workingSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepFileSelection
            stepPassword
            stepCreate
            if let hint = viewModel.clipboardHint {
                Label(hint, systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.clipboardHint)
    }

    // MARK: Step 1 — files

    private var stepFileSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepLabel(number: 1, title: "ファイルを選ぶ")

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
        }
        .frame(maxWidth: .infinity, minHeight: 168)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .dropDestination(for: URL.self) { urls, _ in
            viewModel.setSelectedURLs(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
    }

    // MARK: Step 2 — password

    private var stepPassword: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepLabel(number: 2, title: "パスワードを決める")

            Toggle(isOn: $viewModel.usePassword) {
                Text("パスワードを付ける（おすすめ）")
            }
            .disabled(viewModel.isCompressing)
            .onChange(of: viewModel.usePassword) { _ in
                viewModel.clearValidation()
            }

            if viewModel.usePassword {
                VStack(alignment: .leading, spacing: 10) {
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

                    Button {
                        viewModel.generatePassword()
                    } label: {
                        Label("自動で作る（おすすめ）", systemImage: "key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(viewModel.isCompressing)
                    .help("安全なパスワードを作り、クリップボードにもコピーします")

                    Text("作ったパスワードは相手に別途伝えてください。zipと同じメールに書くと意味がありません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    DisclosureGroup("詳細な設定", isExpanded: $isShowingAdvanced) {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("開きやすさ", selection: $viewModel.useStrongEncryption) {
                                Text("相手がそのまま開ける（おすすめ）").tag(false)
                                Text("より強固な暗号（専用アプリが必要）").tag(true)
                            }
                            .pickerStyle(.radioGroup)
                            .disabled(viewModel.isCompressing)
                            .labelsHidden()

                            Text(viewModel.useStrongEncryption
                                 ? "強力な暗号化です。相手は 7-Zip や Keka などのアプリが必要で、Macの標準機能では開けません。"
                                 : "受け取った人はダブルクリックで開けます（パスワードの入力は必要です）。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 6)
                    }
                    .font(.callout)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.secondary.opacity(0.05))
                )
            } else {
                Text("パスワードなしでも作れますが、誰でも中身を見られます。社外へ送るときはオンにしてください。")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Step 3 — create

    private var stepCreate: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepLabel(number: 3, title: "zipを作成する")

            Toggle("保存先とファイル名を毎回選ぶ", isOn: $askOutputLocation)
                .disabled(viewModel.isCompressing)
            Text(askOutputLocation
                 ? "作成のたびに、保存場所と名前を確認します。"
                 : "1件だけのときは、元のファイルと同じ場所に自動保存します。複数件のときは名前を確認します。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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

    // MARK: Completion / failure

    private func completionSection(zipPath: String, password: String?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("作成できました")
                        .font(.title3.weight(.semibold))
                    Text((zipPath as NSString).lastPathComponent)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            if let password, !password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("パスワード")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(password)
                            .font(.system(.title3, design: .monospaced))
                            .textSelection(.enabled)
                        Spacer()
                        Button("コピー") {
                            viewModel.copyPasswordAgain(password)
                        }
                        .controlSize(.large)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )

                    Label(
                        "このパスワードはzipとは別の手段（チャットや電話など）で伝えてください。",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let hint = viewModel.clipboardHint {
                Label(hint, systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.revealInFinder(path: zipPath)
                } label: {
                    Label("Finderで表示", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("続けて作る") {
                    viewModel.startAnother()
                }
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }

            Text("パスワードを忘れたときは、右上の「履歴」から確認できます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func failureSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 6) {
                    Text("作成できませんでした")
                        .font(.title3.weight(.semibold))
                    Text(message)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text("よくある原因: 同じ名前のファイルを別のアプリで開いたまま、保存場所に書けない、など。")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("やり直す") {
                    viewModel.dismissFailure()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func stepLabel(number: Int, title: String) -> some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))
            Text(title)
                .font(.headline)
        }
    }

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
