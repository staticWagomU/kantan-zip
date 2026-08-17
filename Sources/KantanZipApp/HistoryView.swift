import KantanZipCore
import SwiftUI

/// 「どのファイルにどのパスワードを付けたか」を後から確認する画面。
struct HistoryView: View {
    @ObservedObject var viewModel: CompressionViewModel
    @Environment(\.dismiss) private var dismiss
    /// パスワードは既定で伏せ、明示的に押したものだけ表示する
    @State private var revealedIDs: Set<UUID> = []
    @State private var isConfirmingDeleteAll = false
    @State private var copiedHint: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if viewModel.history.isEmpty {
                emptyState
            } else {
                list
            }
            if let copiedHint {
                Divider()
                Label(copiedHint, systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
        }
        .frame(width: 540, height: 440)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("圧縮の履歴")
                    .font(.headline)
                Text("パスワードを忘れたときに確認できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !viewModel.history.isEmpty {
                Button("すべて削除") { isConfirmingDeleteAll = true }
            }
            Button("閉じる") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(14)
        .confirmationDialog(
            "履歴をすべて削除しますか？",
            isPresented: $isConfirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("すべて削除", role: .destructive) {
                viewModel.deleteAllHistory()
                revealedIDs.removeAll()
                copiedHint = nil
            }
        } message: {
            Text("保存されているパスワードも一緒に消えます。すでに作ったzipファイル自体は消えません。")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("まだ履歴がありません")
                .font(.body.weight(.medium))
            Text("zipを作ると、ここに記録されます。\nパスワードを忘れたときに見返せます。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var list: some View {
        List(viewModel.history) { record in
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.fileName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if !record.stillExists {
                        Text("移動/削除済み")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(record.createdAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                passwordRow(for: record)
                HStack(spacing: 12) {
                    if record.stillExists {
                        Button("Finderで表示") {
                            viewModel.revealInFinder(path: record.zipPath)
                        }
                        .controlSize(.small)
                    }
                    Button("この履歴を削除", role: .destructive) {
                        viewModel.delete(record)
                        revealedIDs.remove(record.id)
                    }
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func passwordRow(for record: CompressionRecord) -> some View {
        if !record.hasPassword {
            Text("パスワードなし")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if revealedIDs.contains(record.id) {
            HStack(spacing: 8) {
                if let password = viewModel.password(for: record) {
                    Text(password)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    Button("コピー") {
                        viewModel.copyToClipboard(password)
                        copiedHint = "パスワードをコピーしました"
                    }
                    .controlSize(.small)
                    Button("隠す") { revealedIDs.remove(record.id) }
                        .controlSize(.small)
                } else {
                    Text("パスワードを取り出せませんでした")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } else {
            Button("パスワードを表示") { revealedIDs.insert(record.id) }
                .controlSize(.small)
        }
    }
}
