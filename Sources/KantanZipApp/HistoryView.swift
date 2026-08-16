import KantanZipCore
import SwiftUI

/// 「どのファイルにどのパスワードを付けたか」を後から確認する画面。
struct HistoryView: View {
    @ObservedObject var viewModel: CompressionViewModel
    @Environment(\.dismiss) private var dismiss
    /// パスワードは既定で伏せ、明示的に押したものだけ表示する
    @State private var revealedIDs: Set<UUID> = []
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if viewModel.history.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(width: 520, height: 420)
    }

    private var header: some View {
        HStack {
            Text("圧縮の履歴")
                .font(.headline)
            Spacer()
            if !viewModel.history.isEmpty {
                Button("すべて削除") { isConfirmingDeleteAll = true }
            }
            Button("閉じる") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(12)
        .confirmationDialog(
            "履歴をすべて削除しますか？",
            isPresented: $isConfirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("すべて削除", role: .destructive) {
                viewModel.deleteAllHistory()
                revealedIDs.removeAll()
            }
        } message: {
            Text("保存されているパスワードも一緒に消えます。zipファイル自体は削除されません。")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("まだ履歴がありません")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List(viewModel.history) { record in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(record.fileName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if !record.stillExists {
                        Text("移動/削除済み")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(record.createdAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                passwordRow(for: record)
            }
            .padding(.vertical, 4)
            .contextMenu {
                if record.stillExists {
                    Button("Finderで表示") { viewModel.revealInFinder(path: record.zipPath) }
                }
                Button("この履歴を削除", role: .destructive) {
                    viewModel.delete(record)
                    revealedIDs.remove(record.id)
                }
            }
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
                    Button("コピー") { viewModel.copyToClipboard(password) }
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
