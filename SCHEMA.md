# スキーマ概要

完全な CREATE 文は `schemas/` にあります。

- `schemas/patchslide_v1.schema.sql` — 配布 `patchslide.sqlite` の実スキーマ（ダンプ）
- `schemas/patchslide_search_v2.schema.sql` — 配布 `patchslide_search.sqlite` の実スキーマ（ダンプ）
- `schemas/patchslide_runtime_v1.sql` — ランタイムDBの生成時スキーマ定義（v1）
- `schemas/patchslide_search_tags_v2.sql` — 検索DBのタグ拡張スキーマ定義（v2）

## patchslide.sqlite（ランタイムDB、`user_version = 1`）

| テーブル | 内容 |
|---|---|
| `candidates` | 候補の定義。主キー `candidate_id`（例 `slide_0_1_h1`） |
| `search_fingerprints` | 候補×発音4回分の音響フィンガープリント（48,720件） |
| `fingerprint_layouts` | フィンガープリントの形式定義 |
| `decision_policy` | AUTO_SAFE 判定ポリシー |
| `partition_codes` | 分割パターン符号（`AAAA` 等） |
| `db_meta` | 生成系・測定系の版とハッシュ等のメタ情報 |

`candidates` の主な列:

- `patch_a` / `patch_b` / `patch_c` — スライドを構成する OPLL パッチ番号（0–14）。
  `change_count = 1` のとき `patch_c` は NULL、`change_count = 2` のとき値を持ちます
- `hold_pattern`（`h1`/`h2`/`h11`/`h12`/`h21`/`h22`）、`hold_a_steps` / `hold_b_steps` — 保持パターンと歩数
- `auto_safe` — 自動使用が安全と判定された候補か（判定規則は `decision_policy`:
  `predicted_partition == "AAAA" AND raw_different_count == 0`）
- `manual_use_allowed` / `visibility`（`normal`/`manual_warning`/`hidden`）/ `enabled`
- `predicted_partition` / `human_pattern` — 予測／人手の分割パターン。`human_pattern` が
  NULL の候補は人手ラベルなしを意味し、推測で埋めてはいけません
- ビュー `v_auto_safe_candidates` / `v_manual_candidates` が有効候補の絞り込みに使えます

フィンガープリント形式: `fp436_v1`、コーデック `fp436_q16le_v1`、436要素
（envelope 50ビン、spectrum 8フレーム、harmonic 32ビン、log-band 16ビンほか。
詳細は `fingerprint_layouts.layout_json`）。

## patchslide_search.sqlite（検索DB、`user_version = 2`）

| テーブル | 内容 |
|---|---|
| `search_vectors` | 候補ごとの検索ベクトル（12,180件） |
| `search_methods` | 検索方法の定義（`standard_b` / `B-frozen-acoustic-search-v1`） |
| `tags` / `candidate_tags` / `tagging_candidates` / `tagging_meta` | 94件の標準タグと候補への付与 |
| `cluster_sets` / `clusters` / `cluster_memberships` | クラスタ集合（16群・64群）と所属 |
| `search_meta` | 本体DBとの結び付け（候補ID集合のハッシュ等） |

検索ベクトル: 768次元、コーデック `f64le_v1`
（little-endian binary64 × 768 = 6,144 bytes、`vector_blob`）。
候補間の距離はベクトル同士の二乗ユークリッド距離で、小さいほど音響的に近い候補です。
クエリベクトルは、対象候補のフィンガープリントから `search_methods.config_json` /
`layout_json` に記録された凍結済み方法で算出します。方法の再現にはこれらの定義が正本です。

タグは日本語の標準タグ94件で、`tags.ordinal` の順序が安定した表示順です。
クラスタは `sampled_medoids_k16`（16群）と `sampled_medoids_k64`（64群）の2集合があり、
各群に代表候補（`clusters.representative_candidate_id`）が定義されています。
