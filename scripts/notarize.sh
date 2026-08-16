#!/usr/bin/env bash
# Developer ID署名済みのdmgをAppleに公証(notarization)してもらい、結果を貼り付ける。
#
# Google Driveやメールなど、隔離属性が付く経路で配るにはこれが必要。
# 公証さえ通れば、受け取った人はダウンロードしてダブルクリックするだけで起動できる。
#
# 事前準備（初回のみ）:
#   1. Apple Developer Program に加入（年間99ドル）
#   2. 証明書「Developer ID Application」を作成しキーチェーンに入れる
#   3. appleid.apple.com でApp用パスワード（app-specific password）を作成
#   4. 認証情報をキーチェーンに保存:
#      xcrun notarytool store-credentials kantanzip \
#        --apple-id <AppleID> --team-id <TeamID> --password <App用パスワード>
#
# 使い方:
#   CODESIGN_ID="Developer ID Application: NAME (TEAMID)" scripts/make-app.sh
#   scripts/make-dmg.sh
#   NOTARY_PROFILE=kantanzip scripts/notarize.sh
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${NOTARY_PROFILE:?NOTARY_PROFILE にキーチェーンプロファイル名を指定してください}"
DMG=build/KantanZip.dmg
[ -f "$DMG" ] || { echo "$DMG がありません。先に scripts/make-dmg.sh を実行してください。" >&2; exit 1; }

# ad-hoc署名のままでは公証を通らないので、事前に弾いて原因を分かりやすくする
if codesign -dv "build/KantanZip.app" 2>&1 | grep -q "Signature=adhoc"; then
  echo "エラー: アプリがad-hoc署名のままです。" >&2
  echo "  CODESIGN_ID=\"Developer ID Application: ...\" scripts/make-app.sh から実行し直してください。" >&2
  exit 1
fi

echo "Appleに提出中（数分かかります）..."
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait

# 公証結果をdmgに貼り付ける。これでオフラインでも検証が通る。
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo
echo "完了: $DMG は公証済みです。Google Drive等で配布できます。"
