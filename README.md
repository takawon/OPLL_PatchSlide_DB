# OPLL PatchSlide DB

OPLL（YM2413）のパッチスライド候補を集めた、アプリケーション共有のデータベースです。
実機系統の測定から構築した 12,180 件の候補について、候補定義・音響フィンガープリント・
検索用ベクトル・タグ・クラスタを SQLite ファイルで提供します。

English summary: see [README.en.md](README.en.md).

## 配布中のデータセット

現在公開しているのは次の1版だけです。他の版は制作途中のため配布していません。

| 項目 | 値 |
|---|---|
| データセット版（物理パッケージ） | `patchslide-pruned-v1-compact` |
| データセット版（意味内容） | `patchslide-pruned-v1` |
| 候補数 | 12,180（初期版 13,950 から重複パッチ候補 1,770 を除外） |
| 検索方法 | `B-frozen-acoustic-search-v1`（768次元、コーデック `f64le_v1`） |
| タグ | 94件 |
| クラスタ | 16群／64群の2セット |

## ファイル

DBは次の3ファイルで1セットです。版の異なるファイルを混ぜて使わないでください。

| ファイル | サイズ (bytes) | SHA-256 |
|---|---:|---|
| `patchslide.sqlite` | 52,154,368 | `67e3de24979e2c3fe0817653fa8fce6386ee91099b9a615d4231a7a32512d0a0` |
| `patchslide_search.sqlite` | 172,707,840 | `a7b43f1121e2355f2023488f078cdbe7c8f952d028b6602291cc4a6616e47fa1` |
| `manifest.json` | 29,618 | `d912cf65a8f61fe4a1a3d5c07746525401038521cf48b3bf3cce51b7d6c7eb93` |

入手方法（いずれも GitHub Releases のタグ `patchslide-pruned-v1-compact` から）:

- **単体インストーラー** — 共有の固定場所へ安全に導入します（推奨）。
- **全部入りZIP** — 3ファイルをまとめたものです。展開して使います。
- **3ファイル個別** — 独自に配布・配置したい人向けです。

データベース本体を git リポジトリには含めていません（Release 資産でのみ配布します）。

## 使い方

### 共有の固定場所（本線）

- Windows: `%ProgramData%\OPLL_PatchSlide_DB\`
- Windows以外: `/usr/local/share/OPLL_PatchSlide_DB`

対応アプリはこの場所を参照するだけで、同じDBを共有できます。
導入は単体インストーラーか、ZIP／個別ファイルを上記の場所へ
3ファイルまとめてコピーすること（管理者権限が必要です）で行います。

MGS Tone Craft（MGSTC）のインストーラーで導入した場合も、同じ場所に同じ3ファイルが
配置され、そのまま共有できます。

### 独自配置（任意）

自分のアプリに同梱するなど、任意のフォルダーに置いて使うこともできます。
アプリ側で配置先を指定できる場合は、そのフォルダーの3ファイルを参照してください。

アプリ開発者向けの詳細な契約（識別・読み取り規則・互換性・導入／更新／削除の作法）は
[SPEC.md](SPEC.md)、テーブル定義は [SCHEMA.md](SCHEMA.md) と `schemas/`、
検索クエリベクトルの構築手順は [QUERY.md](QUERY.md) を参照してください。
Python のサンプル（読み取り・検証・クエリベクトル構築）が `examples/python/` にあります。

## ライセンス

- データベース（SQLite 2ファイル＋`manifest.json`）と本リポジトリの文書: **CC BY 4.0**
  （全文は [LICENSE](LICENSE)）。利用・改変・再配布（商用含む）ができます。
  出典表示を行い、改変した場合はその旨を示してください。
- `examples/` のサンプルコード: **MIT**（[LICENSE-CODE](LICENSE-CODE)）。

出典表示の例:

> OPLL PatchSlide DB (`patchslide-pruned-v1-compact`) by Takawo., licensed under CC BY 4.0.
> https://github.com/takawon/OPLL_PatchSlide_DB

公式セットは上表の SHA-256 で識別されます。改変されたファイルは公式セットではありません。

## 出典・生成方法について

本DBは測定・解析データです。実 MGSC 1.11 → 実 MGSDRV 3.20 を openMSX 上で実行して
YM2413 レジスタトレースを取得し、固定コミット `11676f6c43af7a53a0a940f8faea57eed73a22ba` の
emu2413 で音響解析して構築しました。各測定系の版とハッシュは DB 内のメタ情報
（`db_meta` / `search_meta`）と `manifest.json` に記録されています。

MGSC、MGSDRV、MSX ROM、MSX-DOS 等のバイナリは本DBに含まれていません。
それらは測定時のローカル入力であり、配布物ではありません。
