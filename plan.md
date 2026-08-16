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
| 暗号化 | ZipCrypto（既定・受け取り側がそのまま開ける）と AES-256（強力だが7-Zip等が必要）を選択可 |
| zip処理 | 同梱した 7-Zip 公式CLI `7zz`（ユニバーサルバイナリ）を Process で呼び出す |
| 進捗 | `7zz -bsp1` が出力するパーセンテージをそのまま使う（バイト数ベース） |
| 出力先 | デフォルトは元ファイルと同じ場所（同名は連番 `name 2.zip`）、設定で保存ダイアログに切替可 |
| UI言語 | 日本語 |
| 配布 | 隔離属性が付かない経路（社内共有フォルダ・USB）でdmgを配る。将来的にDeveloper ID署名+公証 |

### 7zz を同梱する理由

- パスワードを値なしの `-p` で渡し標準入力から流し込めるため、`zip -P` と違い
  パスワードがプロセス引数（`ps` で見える）に載らない。
- AES-256 を選べる。`/usr/bin/zip` はZipCryptoしか作れない。
- 進捗が実際のパーセンテージで取れる。
- ライセンス: LGPL-2.1+（一部BSD/unRAR制限）。別プロセス実行でリンクしないため
  本体のソース公開義務は生じないが、License.txt の同梱義務があるので必ず入れる。

### 割り切り（README に明記する）

- ZipCrypto は暗号強度が弱い。互換性（受け取り側がダブルクリックで開ける）を優先した既定値で、
  機密性の高いデータには AES-256 か別手段を推奨する。
- AES-256 は macOS 標準の unzip / アーカイブユーティリティでは開けない
  （`need PK compat. v5.1` で失敗することを実機で確認済み）。

## アーキテクチャ

```
Vendor/7zz/           # 同梱する7-Zip公式CLI（fetch-7zz.shで取得、gitで追跡）
Sources/
  KantanZipCore/        # ロジック層（テスト対象）
    SevenZipCommand.swift       # 7zzの引数組み立て + 暗号化方式（純粋関数）
    SevenZipProgressParser.swift # 7zz出力の "NN%" から進捗を算出（純粋関数）
    OutputPathResolver.swift    # 出力先パス決定・同名時の連番（純粋関数）
    SevenZipRunner.swift        # Processで7zzを実行、パスワードはstdinへ（I/O層）
    ZipService.swift            # 上記を束ねるファサード
  KantanZipApp/         # SwiftUI層（executable）
    KantanZipApp.swift
    ContentView.swift           # ドロップゾーン + パスワード + 暗号化方式 + 進捗
    CompressionViewModel.swift  # 圧縮の状態遷移
    SevenZipLocator.swift       # バンドル内/開発時の7zzパス解決
Tests/
  KantanZipCoreTests/
scripts/
  fetch-7zz.sh          # 7zzをVendorに取り込む
  make-app.sh           # .app化（7zz同梱 + ad-hoc署名）
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
