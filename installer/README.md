# 単体インストーラー

共有DBを `%ProgramData%\OPLL_PatchSlide_DB\` へ導入する、DB専用のインストーラーです。
MGS Tone Craft が無くても、他の対応アプリのためにDBだけを入れられます。

## 構成

| ファイル | 役割 |
|---|---|
| `OPLL_PatchSlide_DB.iss` | Inno Setup スクリプト（AppId `{2506C8EC-CDB3-4205-8F6C-EDB91288DB5F}`、MGSTCとは別製品として登録） |
| `Manage-InstallerData.ps1` | 導入・削除ヘルパー。**MGSTCのものとバイト同一の複製**で、使うのは `InstallDb` / `RemoveDb` モードだけです（ユーザーデータ系モードは呼びません） |
| `distribution.json` | DBファイル・ヘルパー・言語ファイル・コンパイラのハッシュ固定 |
| `build-installer.ps1` | ハッシュ検証つきステージング＋ISCC実行 |
| `languages/` | Inno Setup 6.7.3 の言語ファイル（Inno Setup のライセンスは同フォルダー内） |

## ライセンス

このフォルダーのスクリプト（`Manage-InstallerData.ps1`、`build-installer.ps1`、
`OPLL_PatchSlide_DB.iss`）は **AGPL-3.0-only** です。`Manage-InstallerData.ps1`
は MGS Tone Craft（AGPL-3.0-only）から流用したものを含みます。改変・再利用は
AGPL-3.0 の条件に従ってください（全文は同フォルダーの `LICENSE-AGPL.txt`）。
Inno Setup の言語ファイルは Inno Setup の
ライセンスに従います（`languages/Inno-Setup-LICENSE.txt`）。

## 振る舞い

- インストール: DB 3ファイルのハッシュを照合し、トランザクション方式で
  `%ProgramData%\OPLL_PatchSlide_DB\` へ一括配置します（失敗時は元の状態へ復元）。
  配置先とファイルには全ユーザーの読み取り権限を付けます。
  DBを使用中のアプリがある場合は、閉じるよう案内して中止します。
- アンインストール: 共有DBの削除は独立した選択肢で、確認ダイアログつきです。
  削除しない選択もできます。サイレントアンインストールは行いません。
- MGSTC のインストーラーで導入済みのDBがある場合も、同じハッシュの同じ3ファイル
  なので、そのまま上書き導入できます（内容は同一です）。

## ビルド方法（Windows）

前提: Inno Setup **6.7.3**（`ISCC.exe` の SHA-256 が `distribution.json` の
`compilerSha256` と一致すること）。DBファイルは公式セット（Release 資産または
MGSTC の引渡しフォルダー）から用意します。

```powershell
powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 `
  -DbSourceDirectory <3ファイルのあるフォルダー> [-IsccPath <ISCC.exe>] [-OutputDirectory dist]
```

出力: `dist\OPLL_PatchSlide_DB-patchslide-pruned-v1-compact-setup.exe`
（末尾に SHA-256 が表示されます）。

## 注意

- インストーラーは未署名です（MGSTC と同様）。SmartScreen の警告が出る場合があります。
- 既知の制限：アンインストール時のDB削除は所定のファイル名を対象に行い、
  版の照合はしません。将来、別の版のDBが共有フォルダーに入っている状態で
  古い版のインストーラーをアンインストールすると、新しい版も削除対象に
  なります（確認ダイアログは出ます）。将来の版では、削除前に `manifest.json`
  の版を照合し、異なる版の場合は警告して削除を見送る方式に変更する予定です。
- DBの版を上げる場合は、新しい版のハッシュで `distribution.json` と
  `Manage-InstallerData.ps1` 内の `$dbHashes` を更新し、新しい Release として出します。
  既存 Release の資産差し替えはしません。
