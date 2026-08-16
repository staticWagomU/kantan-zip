#!/usr/bin/env bash
# 7-Zip公式のmacOS用CLI(7zz)をVendor/に取り込む。
# 7zzはユニバーサルバイナリ(arm64+x86_64)なのでIntel/Apple Silicon両対応。
#
# ライセンス: 7-ZipはLGPL-2.1+（一部BSD、一部unRAR制限付き）。
# アプリ本体とは別プロセスとして呼び出すだけでリンクはしないため、
# 本体のソース公開義務は生じない。ただしLGPLバイナリを再配布する以上、
# 次の義務は残るので満たしておく:
#   - License.txt 全文の同梱（License.txt自身が明文で要求している）
#   - LGPLである旨と www.7-zip.org へのリンクの明示（READMEに記載）
#   - 対応ソースの提供手段（同じバージョンのsrc tarballも取得して保管する）
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${SEVENZIP_VERSION:-2602}"
URL="https://www.7-zip.org/a/7z${VERSION}-mac.tar.xz"
VENDOR="Vendor/7zz"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "取得中: $URL"
curl -fsSL -o "$WORK/7z.tar.xz" "$URL"
tar xf "$WORK/7z.tar.xz" -C "$WORK"

mkdir -p "$VENDOR"
cp "$WORK/7zz" "$VENDOR/7zz"
cp "$WORK/License.txt" "$VENDOR/License.txt"
chmod +x "$VENDOR/7zz"

# LGPLの「対応ソースを提供できる状態にする」義務を満たすため、
# 同じバージョンのソースの入手先を記録する。
# （tarball自体は大きいのでリポジトリには入れず、URLを固定して残す）
cat > "$VENDOR/SOURCE.md" <<EOF
# 同梱している 7-Zip のソース入手先

同梱バイナリ: 7-Zip ${VERSION}（macOS用 7zz、未改変）

LGPL-2.1+ に基づき、このバイナリに対応するソースコードは以下から入手できます。

- ソース: https://www.7-zip.org/a/7z${VERSION}-src.tar.xz
- 配布元: https://www.7-zip.org/

バイナリには一切の改変を加えていません。
社外に配布する場合は、このURLを案内するか、上記tarballを添付してください。
EOF

echo "配置しました: $VENDOR/7zz"
file "$VENDOR/7zz" | head -1
"$VENDOR/7zz" | sed -n '2p'
