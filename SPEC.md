# 利用仕様（アプリ開発者向け契約）

OPLL PatchSlide DB をアプリケーションから利用するための契約です。
この文書の規則に従うアプリは、同じDBセットを安全に共有できます。

## 1. ファイルセットと識別

DBは次の3ファイルで1セットです。ファイル名は固定です。

- `patchslide.sqlite` — ランタイムDB（候補定義・フィンガープリント）。`PRAGMA user_version = 1`
- `patchslide_search.sqlite` — 検索DB（ベクトル・タグ・クラスタ）。`PRAGMA user_version = 2`
- `manifest.json` — セットの識別情報（`manifest_version = patchslide-search-manifest-v2`）

アプリは使用前に、少なくとも次を照合してください。

- 3ファイルがすべて存在する
- `manifest.json` の `source_db_sha256` / `search_db_sha256` が実ファイルの SHA-256 と一致する
- `manifest.json` の `candidate_count`、`schema_version`（`2`）、
  `dataset_version`、`physical_packaging.version` が、アプリが対応する版と一致する
- 両DBの `PRAGMA user_version` が上記の値である

照合できないセットは使用しないでください。公式セットは Release に記載の
SHA-256 で識別されます（[README.md](README.md) の表）。

現在の公式セット:

- `dataset_version` = `patchslide-pruned-v1`
- `physical_packaging.version` = `patchslide-pruned-v1-compact`
- `candidate_count` = 12180

## 2. 配置場所

既定の共有場所:

- Windows: `%ProgramData%\OPLL_PatchSlide_DB\`（`FOLDERID_ProgramData` で解決すること。
  解決できない場合は `C:\ProgramData\OPLL_PatchSlide_DB`）
- Windows以外: `/usr/local/share/OPLL_PatchSlide_DB`

アプリは、利用者やアプリ自身の設定で別のフォルダーを指定することもできます
（独自配布・同梱の場合）。その場合もファイルセットの規則は同じです。

## 3. 読み取り規則

- DBは不変データとして扱い、**読み取り専用**で開いてください。
  SQLite では読み取り専用URI（例: `file:<path>?mode=ro&immutable=1`）の使用を推奨します。
- DBファイルへの書き込み、スキーマ変更、インデックス追加を行わないでください。
- `-wal` / `-shm` / `-journal` 等の副作用ファイルを共有場所に作らないでください。
  副作用ファイルが存在するセットは、更新途中などの異常状態として扱ってください。
- 音響ベクトルは検索DBの `search_vectors` にあります。形式は
  `search_methods` が示すとおり、現在の公式セットでは 768次元・`f64le_v1`
  （little-endian binary64 × 768 = 6,144 bytes）です。
  類似検索の距離は二乗ユークリッド距離です（[SCHEMA.md](SCHEMA.md) 参照）。

## 4. 互換性と異常時の振る舞い

- DBが存在しない、ファイルが不足する、照合に失敗する、未知の版である場合は、
  アプリを異常終了させず、**PatchSlide 機能だけを無効化**して、
  利用者にDBの導入方法（このリポジトリの Release）を案内してください。
- アプリは自分が対応する版の範囲を明示してください。将来の版のDBを、
  対応を宣言していないアプリが黙って読み込むことは想定していません。

## 5. 導入・更新・削除の作法

- 共有場所への導入・更新は、単体インストーラーの使用を推奨します。
  手動で行う場合も、DBを使用するすべてのアプリを終了し、
  3ファイルを**一括で**入れ替えてください（1ファイルずつの更新や版の混在は禁止）。
- 共有場所のファイルは、すべての利用者が読み取れる権限で配置してください。
- アプリのアンインストール時に共有DBを削除しないでください。
  削除は、共有DB専用のインストーラー／アンインストーラーで、
  利用者が明示的に選択した場合に限ります（他のアプリが使用している可能性があります）。

## 6. 再配布

- DBと文書は CC BY 4.0 です。アプリへの同梱を含む再配布・改変ができます。
- **公式互換DBセットとして配布する場合**は、出典表示に加えて、`manifest.json`
  を含む3ファイル一式と、その整合性（ハッシュ・版の一致、§1）を保ってください。
  アプリ側の検証を通るのはこの形だけです。
- **加工・部分抽出したデータ**も、CC BY 4.0 の条件（出典表示、改変した場合は
  その旨の表示など）に従って再配布できます。ただし、その場合は公式セットでは
  ありません。公式セットであるかのような表示をしないでください
  （公式セットの識別は SHA-256 によります）。
