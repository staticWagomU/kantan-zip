#!/usr/bin/env bash
# 7-Zip公式のmacOS用CLI(7zz)をVendor/に取り込む。
# 7zzはユニバーサルバイナリ(arm64+x86_64)なのでIntel/Apple Silicon両対応。
#
# ライセンス: 7-ZipはLGPL-2.1+（一部BSD、一部unRAR制限付き）。
# License.txtに「Redistributions in binary form must reproduce related
# license information from this file」とあるため、License.txtも必ず同梱する。
# アプリ本体とは別プロセスとして呼び出すだけでリンクはしないため、
# 本体のソース公開義務は生じない。
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

echo "配置しました: $VENDOR/7zz"
file "$VENDOR/7zz" | head -1
"$VENDOR/7zz" | sed -n '2p'
