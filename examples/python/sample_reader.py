#!/usr/bin/env python3
"""Minimal reader example for the OPLL PatchSlide DB.

SPDX-License-Identifier: MIT

Verifies a database set (manifest + SHA-256), opens both SQLite files
read-only, and shows basic queries: candidate lookup, tags, and nearest
neighbours by squared Euclidean distance over the 768-dim f64le vectors.

Usage:
    python sample_reader.py [--dir PATH] [--candidate ID] [--top N]
"""

import argparse
import hashlib
import json
import os
import sqlite3
import struct
import sys

FILES = ("patchslide.sqlite", "patchslide_search.sqlite", "manifest.json")
DIMENSION = 768


def default_directory() -> str:
    if os.name == "nt":
        base = os.environ.get("ProgramData", r"C:\ProgramData")
        return os.path.join(base, "OPLL_PatchSlide_DB")
    return "/usr/local/share/OPLL_PatchSlide_DB"


def sha256_of(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def open_readonly(path: str) -> sqlite3.Connection:
    uri = "file:" + path.replace("?", "%3f").replace("#", "%23") + "?mode=ro&immutable=1"
    return sqlite3.connect(uri, uri=True)


def load_verified(directory: str):
    paths = {name: os.path.join(directory, name) for name in FILES}
    for name, path in paths.items():
        if not os.path.isfile(path):
            raise SystemExit(f"missing file: {path}")
    with open(paths["manifest.json"], encoding="utf-8") as stream:
        manifest = json.load(stream)
    if sha256_of(paths["patchslide.sqlite"]) != manifest["source_db_sha256"]:
        raise SystemExit("patchslide.sqlite SHA-256 mismatch")
    if sha256_of(paths["patchslide_search.sqlite"]) != manifest["search_db_sha256"]:
        raise SystemExit("patchslide_search.sqlite SHA-256 mismatch")
    runtime = open_readonly(paths["patchslide.sqlite"])
    search = open_readonly(paths["patchslide_search.sqlite"])
    if runtime.execute("PRAGMA user_version").fetchone()[0] != 1:
        raise SystemExit("patchslide.sqlite user_version must be 1")
    if search.execute("PRAGMA user_version").fetchone()[0] != 2:
        raise SystemExit("patchslide_search.sqlite user_version must be 2")
    count = runtime.execute("SELECT COUNT(*) FROM candidates").fetchone()[0]
    if count != manifest["candidate_count"]:
        raise SystemExit("candidate_count mismatch")
    return manifest, runtime, search


def vector_of(search: sqlite3.Connection, candidate_id: str):
    row = search.execute(
        "SELECT codec, vector_blob FROM search_vectors WHERE candidate_id = ?",
        (candidate_id,),
    ).fetchone()
    if row is None:
        raise SystemExit(f"unknown candidate: {candidate_id}")
    codec, blob = row
    if codec != "f64le_v1" or len(blob) != DIMENSION * 8:
        raise SystemExit(f"unsupported vector codec: {codec}")
    return struct.unpack(f"<{DIMENSION}d", blob)


def nearest(search: sqlite3.Connection, candidate_id: str, top: int):
    query = vector_of(search, candidate_id)
    results = []
    for other_id, blob in search.execute(
        "SELECT candidate_id, vector_blob FROM search_vectors"
    ):
        if other_id == candidate_id:
            continue
        target = struct.unpack(f"<{DIMENSION}d", blob)
        distance = sum((a - b) ** 2 for a, b in zip(query, target))
        results.append((distance, other_id))
    results.sort()
    return results[:top]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", default=default_directory(), help="database directory")
    parser.add_argument("--candidate", default="slide_0_1_h1")
    parser.add_argument("--top", type=int, default=5)
    args = parser.parse_args()

    manifest, runtime, search = load_verified(args.dir)
    print(f"dataset: {manifest['physical_packaging']['version']} "
          f"({manifest['candidate_count']} candidates)")
    row = runtime.execute(
        "SELECT candidate_id, patch_a, patch_b, patch_c, hold_pattern, auto_safe "
        "FROM candidates WHERE candidate_id = ?",
        (args.candidate,),
    ).fetchone()
    print("candidate:", row)
    tags = [r[0] for r in search.execute(
        "SELECT tag FROM candidate_tags WHERE candidate_id = ? ORDER BY tag",
        (args.candidate,),
    )]
    print("tags:", ", ".join(tags))
    print(f"nearest {args.top} to {args.candidate}:")
    for distance, other_id in nearest(search, args.candidate, args.top):
        print(f"  {other_id}  squared_distance={distance:.6f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
