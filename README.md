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
つまり「どう配るか」で必要な手続きが変わります。

### Google Drive で配るなら公証（notarization）が必要

**ブラウザでダウンロードした時点で隔離属性が付く**ため、署名なしのアプリは
ダウンロードした人の環境で起動できません。Apple Developer Program（年間99ドル）に
加入して公証を通すのが唯一の現実的な解です。

```sh
CODESIGN_ID="Developer ID Application: NAME (TEAMID)" scripts/make-app.sh
scripts/make-dmg.sh
NOTARY_PROFILE=kantanzip scripts/notarize.sh
```

初回の準備手順は [scripts/notarize.sh](scripts/notarize.sh) の冒頭コメントを参照。
公証さえ通れば、受け取る人は「ダウンロード → ダブルクリック → ドラッグ」だけで、
警告は一切出ません。

### 費用をかけない場合: 社内ファイルサーバーまたはUSBメモリで配る

Google Drive をやめて、隔離属性が付かない経路で配る方法です。

```sh
scripts/make-app.sh
scripts/make-dmg.sh
# build/KantanZip.dmg を社内共有フォルダに置く、またはUSBメモリにコピーする
```

こちらも受け取る人の手順はダブルクリックとドラッグだけで、警告は出ません。
ただし配布経路を全員に守ってもらう必要があり、誰かがブラウザ経由で共有し直すと
そこで破綻します。

### 配布経路と隔離属性の対応

| 配布経路 | 隔離属性 | 未署名アプリの起動 |
|---|---|---|
| 社内ファイルサーバー（SMB共有）からコピー | 付かない | できる |
| USBメモリ・外付けディスク | 付かない | できる |
| **Google Drive（ブラウザでダウンロード）** | **付く** | **ブロックされる** |
| メール添付・AirDrop・Slack等 | **付く** | **ブロックされる** |

macOS 15 Sequoia 以降は、右クリック→「開く」による回避ができなくなり、
システム設定 →「プライバシーとセキュリティ」→「このまま開く」を辿り、
管理者パスワードを入力する必要があります。非IT技術者には負担が大きく、
毎回の更新のたびに発生するので、実用的な回避策にはなりません。

**最初の1台で必ず確認してください。** 隔離属性が付くかどうかは配布経路の実装に
左右されます。配布前に受け取り側のMacで次を実行し、何も出力されなければ問題ありません。

```sh
xattr -l /Applications/KantanZip.app
```

## セキュリティ上の注意

- **ZipCrypto は互換性を優先した弱い暗号方式です。** 総当たり攻撃に耐える強度はありません。
  本当に守りたいデータには AES-256 を選ぶか、暗号化ディスクイメージなど別の手段を使ってください。
- 隔離属性を手動で剥がす方法（`xattr -dr com.apple.quarantine`）をユーザーに教えるのは
  避けてください。「警告が出たらこのスクリプトを実行する」という習慣は、本物のマルウェアを
  実行させる手口とまったく同じ形をしています。配布経路で解決するほうが安全です。

## 同梱ソフトウェア

このアプリは **[7-Zip](https://www.7-zip.org/) のコードを使用しています。**
7-Zip の公式 macOS CLI（`7zz`、未改変）をそのまま同梱しています。

- 7-Zip は **GNU LGPL** で配布されています（一部 BSD ライセンス、一部 unRAR ライセンス制限）
- 配布元: https://www.7-zip.org/
- ライセンス全文: アプリバンドル内 `Contents/Resources/7zz-License.txt`、
  リポジトリでは [Vendor/7zz/License.txt](Vendor/7zz/License.txt)
- 対応ソースの入手先: [Vendor/7zz/SOURCE.md](Vendor/7zz/SOURCE.md)

7zz はアプリ本体とリンクせず別プロセスとして呼び出しているため、
本体のソース公開義務は生じません。ただし LGPL のバイナリを再配布する以上、
上記のライセンス表示と対応ソースの提供手段は必要です。
（一般的な理解であり法的助言ではありません。社外配布時は法務確認を推奨します）
