#!/usr/bin/env bash
# 配布用のdmgを作る。
#
# 配布方針: Google Driveに置き、受け取る人に初回だけ起動を許可してもらう。
# ブラウザでダウンロードすると com.apple.quarantine 属性が付くため、
# 公証していないアプリは初回にシステム設定での許可が必要になる。
# dmgと docs/インストール手順.md を必ずセットで配ること。
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/KantanZip.app
[ -d "$APP" ] || { echo "$APP がありません。先に scripts/make-app.sh を実行してください。" >&2; exit 1; }

STAGE=build/dmg-stage
DMG=build/KantanZip.dmg

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
# ユーザーがドラッグでインストールできるよう /Applications へのリンクを置く
ln -s /Applications "$STAGE/アプリケーション"

# 配布物に隔離属性が残っていると受け取り側で起動できないため念のため落とす
xattr -cr "$STAGE" 2>/dev/null || true

hdiutil create -volname "KantanZip" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo
echo "作成しました: $DMG"
echo
echo "Google Driveには次の2点をセットで置いてください:"
echo "  1. $DMG"
echo "  2. docs/インストール手順.md"
echo "（手順書がないと、受け取った人は初回の警告で詰まります）"
