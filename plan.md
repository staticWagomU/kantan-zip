# KantanZip 開発計画

## 概要

macOS用のzip圧縮GUIアプリ。社内の非IT技術者に配布する実用ツール。
ファイルをドラッグ&ドロップ（またはダイアログで選択）して、パスワード付きzipを作成する。

## 仕様

| 項目 | 決定内容 |
|---|---|
| 技術 | Swift + SwiftUI、SPM + Xcode併用構成 |
| 対象OS | macOS 13 Ventura以降 |
| 入力 | ドラッグ&ドロップ + ファイル選択ダイアログ、複数ファイル/フォルダ→1つのzip |
| 暗号化 | パスワード付きzip（ZipCrypto方式＝Mac標準アーカイブユーティリティで開ける）。パスワードなしも可 |
| zip処理 | `/usr/bin/zip` をProcessで呼び出し（`zip -r -P <password>`） |
| 進捗 | 圧縮中のプログレス表示（事前にファイル数を数え、stdoutの`adding:`行をカウントして割合を出す） |
| 出力先 | デフォルトは元ファイルと同じ場所（同名は連番 `name 2.zip`）、設定で保存ダイアログに切替可 |
| UI言語 | 日本語 |
| 配布 | Developer ID署名 + 公証（App Store外の直接配布） |

### 割り切り（README に明記する）

- `zip -P` はパスワードがプロセス引数に載るため `ps` で見える理論上のリスクがある。
  個人のMacで自分が起動するGUIアプリという前提で許容する。
- ZipCrypto は暗号強度が弱い。互換性（受け取り側がダブルクリックで開ける）を優先した選択で、
  機密性の高いデータには別手段を推奨する。

## アーキテクチャ

```
Sources/
  KantanZipCore/        # ロジック層（テスト対象）
    ZipCommand.swift        # zipコマンドの引数組み立て（純粋関数）
    OutputPathResolver.swift # 出力先パス決定・同名時の連番
    ZipProgressParser.swift  # zip stdoutの "adding:" 行から進捗を算出
    FileCounter.swift        # 圧縮対象のファイル数を事前カウント
    ZipRunner.swift          # Processで /usr/bin/zip を実行（薄いI/O層）
  KantanZipApp/         # SwiftUI層（executable）
    KantanZipApp.swift
    ContentView.swift       # ドロップゾーン + ファイル選択 + パスワード入力 + 進捗
    AppSettings.swift       # 出力先モードの設定（UserDefaults）
Tests/
  KantanZipCoreTests/
```

方針: I/O（Process実行・ファイルシステム）を薄い層に隔離し、
引数組み立て・パス解決・進捗パースを純粋なロジックとしてTDDで作る。

## TDDステップ

1. [x] ZipCommand: 引数組み立て（単一ファイル / 複数 / フォルダ=-r / パスワード=-P / 相対パス化のためのworkingDirectory）
2. [x] OutputPathResolver: zip名の決定（単一→`<name>.zip`、複数→共通親フォルダ名 or `アーカイブ.zip`）、既存時の連番
3. [x] ZipProgressParser: `adding: ...` 行のカウント→進捗率
4. [x] FileCounter: フォルダ再帰のファイル数カウント
5. [x] ZipRunner: 実際に /usr/bin/zip を叩く統合テスト（tempディレクトリで往復確認）
6. [x] SwiftUI層: ドロップ→圧縮→完了 のフロー（手動確認）
7. [x] アプリバンドル化スクリプト（scripts/make-app.sh）

## 配布手順（将来）

- Apple Developer Program 加入後、Developer ID Application 証明書で codesign
- `xcrun notarytool submit` で公証 → staple
- zipに固めて社内配布
