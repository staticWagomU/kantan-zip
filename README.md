# KantanZip

macOS用のかんたんzip圧縮アプリ。ファイルやフォルダをウィンドウにドロップするだけで、
パスワード付きzipを作成できます。社内の非IT技術者向けに作られています。

## 機能

- ドラッグ&ドロップまたはファイル選択ダイアログで圧縮
- 複数ファイル・フォルダをまとめて1つのzipに
- パスワード付きzip
  - **ZipCrypto（既定）**: 受け取った人がダブルクリックでそのまま開ける
  - **AES-256**: 強力だが、開く側に7-ZipやKekaなどが必要
- 圧縮中の進捗表示
- 出力先は元ファイルと同じ場所（同名があれば `名前 2.zip` と連番）。設定で毎回保存ダイアログに切替可

## 動作環境

- macOS 13 Ventura 以降（Intel / Apple Silicon 両対応）

## 開発

```sh
scripts/fetch-7zz.sh   # 同梱する7zzを取得（初回のみ）
swift test             # テスト実行
swift run              # 開発中の起動
scripts/make-app.sh    # build/KantanZip.app を作成
scripts/make-dmg.sh    # build/KantanZip.dmg を作成
```

構成の詳細と開発計画は [plan.md](plan.md) を参照。

## 配布方法

macOSのGatekeeperは **`com.apple.quarantine`（隔離）属性が付いたファイルにだけ** 働きます。
そのため配布経路さえ選べば、Apple Developer Program（年間99ドル）なしで配れます。

### 推奨: 社内ファイルサーバーまたはUSBメモリで配る

```sh
scripts/make-app.sh
scripts/make-dmg.sh
# build/KantanZip.dmg を社内共有フォルダに置く、またはUSBメモリにコピーする
```

受け取る人の手順は「dmgをダブルクリック → アプリをアプリケーションフォルダにドラッグ →
ダブルクリックで起動」だけです。警告は出ません。

| 配布経路 | 隔離属性 | 未署名アプリの起動 |
|---|---|---|
| 社内ファイルサーバー（SMB共有）からコピー | 付かない | できる |
| USBメモリ・外付けディスク | 付かない | できる |
| ブラウザでダウンロード | **付く** | **ブロックされる** |
| メール添付・AirDrop・Slack等 | **付く** | **ブロックされる** |

macOS 15 Sequoia 以降は、右クリック→「開く」による回避ができなくなり、
システム設定 →「プライバシーとセキュリティ」→「このまま開く」を辿り、
管理者パスワードを入力する必要があります。
非IT技術者には負担が大きいので、隔離属性が付かない経路で配るのが現実的です。

**最初の1台で必ず確認してください。** 隔離属性が付くかどうかはファイルサーバーの
実装（SMBの拡張属性の扱い）によって変わることがあります。配布前に受け取り側の
Macで次を実行し、何も出力されなければ問題ありません。

```sh
xattr -l /Applications/KantanZip.app
```

### 将来: Developer ID署名 + 公証

社外に配る、またはブラウザ経由で配りたくなった場合はこちらが必要です。

```sh
CODESIGN_ID="Developer ID Application: <YOUR NAME> (<TEAMID>)" scripts/make-app.sh
scripts/make-dmg.sh
xcrun notarytool submit build/KantanZip.dmg --keychain-profile <profile> --wait
xcrun stapler staple build/KantanZip.dmg
```

## セキュリティ上の注意

- **ZipCrypto は互換性を優先した弱い暗号方式です。** 総当たり攻撃に耐える強度はありません。
  本当に守りたいデータには AES-256 を選ぶか、暗号化ディスクイメージなど別の手段を使ってください。
- 隔離属性を手動で剥がす方法（`xattr -dr com.apple.quarantine`）をユーザーに教えるのは
  避けてください。「警告が出たらこのスクリプトを実行する」という習慣は、本物のマルウェアを
  実行させる手口とまったく同じ形をしています。配布経路で解決するほうが安全です。

## 同梱ソフトウェア

zip圧縮には [7-Zip](https://www.7-zip.org/) の公式macOS CLI（`7zz`）を同梱しています。
7-Zip は LGPL-2.1+（一部 BSD ライセンス、一部 unRAR ライセンス制限）で配布されています。
ライセンス全文はアプリバンドル内の `Contents/Resources/7zz-License.txt`
および [Vendor/7zz/License.txt](Vendor/7zz/License.txt) を参照してください。
