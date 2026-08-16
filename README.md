# KantanZip

macOS用のかんたんzip圧縮アプリ。ファイルやフォルダをウィンドウにドロップするだけで、
パスワード付きzipを作成できます。社内の非IT技術者向けに作られています。

## 機能

- ドラッグ&ドロップまたはファイル選択ダイアログで圧縮
- 複数ファイル・フォルダをまとめて1つのzipに
- パスワード付きzip（ZipCrypto方式。Mac標準のアーカイブユーティリティやWindowsエクスプローラーでそのまま開ける）
- 圧縮中の進捗表示
- 出力先は元ファイルと同じ場所（同名があれば `名前 2.zip` と連番）。設定で毎回保存ダイアログに切替可

## 動作環境

- macOS 13 Ventura 以降

## 開発

```sh
swift test        # テスト実行
swift run         # 開発中の起動
scripts/make-app.sh   # build/KantanZip.app を作成
```

構成の詳細と開発計画は [plan.md](plan.md) を参照。

## 配布

社内配布にはDeveloper ID署名と公証（notarization）が必要です。
未署名のまま渡すとGatekeeperにブロックされ、受け取った人が開けません。

```sh
scripts/make-app.sh
codesign --deep --options runtime -s "Developer ID Application: <YOUR NAME>" build/KantanZip.app
ditto -c -k --keepParent build/KantanZip.app build/KantanZip.zip
xcrun notarytool submit build/KantanZip.zip --keychain-profile <profile> --wait
xcrun stapler staple build/KantanZip.app
```

## セキュリティ上の注意

- ZipCryptoは互換性を優先した弱い暗号方式です。機密性の高いデータには
  別の手段（暗号化ディスクイメージ等）を使ってください。
- 内部で `/usr/bin/zip -P` を使うため、圧縮中はパスワードがプロセス引数から
  理論上参照できます。個人のMacで使う前提のツールです。
