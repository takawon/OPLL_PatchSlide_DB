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
- DBの版を上げる場合は、新しい版のハッシュで `distribution.json` と
  `Manage-InstallerData.ps1` 内の `$dbHashes` を更新し、新しい Release として出します。
  既存 Release の資産差し替えはしません。
