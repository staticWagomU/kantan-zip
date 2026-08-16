#!/usr/bin/env bash
# 配布用のdmgを作る。
#
# 重要: この dmg を「社内ファイルサーバー」や「USBメモリ」経由で渡すこと。
# ブラウザやメール、AirDropで渡すと com.apple.quarantine 属性が付き、
# 未署名アプリはGatekeeperにブロックされて起動できない（macOS 26で確認済み）。
# 隔離属性が付かない経路で配れば、署名なしのままダブルクリックで起動する。
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
echo "配布方法: 社内ファイルサーバーまたはUSBメモリでコピーしてください。"
echo "（ブラウザ/メール/AirDrop経由だと隔離属性が付いて起動できません）"
