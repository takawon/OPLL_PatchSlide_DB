# OPLL PatchSlide DB

A shared database of OPLL (YM2413) patch-slide candidates for applications.
It provides 12,180 candidates measured from a real MGSC/MGSDRV chain, with candidate
definitions, acoustic fingerprints, search vectors, tags and clusters, as SQLite files.

Japanese documentation is primary: [README.md](README.md) / [SPEC.md](SPEC.md).

## Current dataset

Only one version is distributed; all other versions are work in progress.

- Package version: `patchslide-pruned-v1-compact`
- Semantic dataset version: `patchslide-pruned-v1`
- Candidates: 12,180 (13,950 initial candidates minus 1,770 duplicate-patch candidates)
- Search method: `B-frozen-acoustic-search-v1`, 768 dimensions, codec `f64le_v1`
- Tags: 94; Clusters: two sets (16 and 64)

## Files (one set, never mix versions)

| File | Size (bytes) | SHA-256 |
|---|---:|---|
| `patchslide.sqlite` | 52,154,368 | `67e3de24979e2c3fe0817653fa8fce6386ee91099b9a615d4231a7a32512d0a0` |
| `patchslide_search.sqlite` | 172,707,840 | `a7b43f1121e2355f2023488f078cdbe7c8f952d028b6602291cc4a6616e47fa1` |
| `manifest.json` | 29,618 | `d912cf65a8f61fe4a1a3d5c07746525401038521cf48b3bf3cce51b7d6c7eb93` |

Available from the GitHub Release tagged `patchslide-pruned-v1-compact` as a standalone
installer, a combined ZIP, or the three individual files. The database files are not
stored in the git repository itself.

## Usage

Shared fixed location (primary):

- Windows: `%ProgramData%\OPLL_PatchSlide_DB\`
- Other systems: `/usr/local/share/OPLL_PatchSlide_DB`

Any application may instead keep its own copy in a private directory.
See [SPEC.md](SPEC.md) for the integration contract, [SCHEMA.md](SCHEMA.md)
(plus `schemas/`) for the table definitions, and [QUERY.md](QUERY.md) for how
to build search query vectors from fingerprints. Python examples (reading,
verification, query-vector construction) are in `examples/python/`.

## License

- Database files and documentation: **CC BY 4.0** (see [LICENSE](LICENSE)).
  Attribution is required; indicate if you changed the material.
- Sample code under `examples/`: **MIT** (see [LICENSE-CODE](LICENSE-CODE)).

Attribution example:

> OPLL PatchSlide DB (`patchslide-pruned-v1-compact`) by Takawo., licensed under CC BY 4.0.
> https://github.com/takawon/OPLL_PatchSlide_DB

The official set is identified by the SHA-256 hashes above; modified files are not
the official set.

## Provenance

This database is measurement/analysis data. It was built by running the original
MGSC 1.11 and MGSDRV 3.20 under openMSX, capturing YM2413 register traces, and
analysing the audio with emu2413 at fixed commit
`11676f6c43af7a53a0a940f8faea57eed73a22ba`. Versions and hashes of the measurement
chain are recorded in the database metadata (`db_meta` / `search_meta`) and in
`manifest.json`. No MGSC, MGSDRV, MSX ROM or MSX-DOS binaries are included; those
were local measurement inputs, not distributable outputs.
