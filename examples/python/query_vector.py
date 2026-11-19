#!/usr/bin/env python3
"""Reference implementation: build a search query vector from fingerprints.

SPDX-License-Identifier: MIT

Implements the frozen method `B-frozen-acoustic-search-v1` using only the
Python standard library, exactly as specified by the JSON documents stored
in the databases themselves:

- `fingerprint_layouts.layout_json` in patchslide.sqlite (fp436 layout)
- `search_methods.config_json` / `layout_json` in patchslide_search.sqlite

Pipeline (per candidate, from its four fingerprints, note_index 1..4):
  1. Decode fp436_q16le_v1: uint16 LE x436; elements 0..51 scale 1/65535,
     spectral elements 52..435 scale 0.625/65535.
  2. Shape = elements 52..435: 8 frames of (harmonic[32], log_band[16]).
  3. Per frame, L2-normalize the harmonic block and the log-band block
     separately, with denominator max(norm, 4/65535).
  4. Divide the shape by 4.0 (shape_scale).
  5. Vector = [ sqrt(0.8) * mean over the 4 notes,
                sqrt(0.2) * population std over the 4 notes ]  (768 dims)

Verified against the distributed set: rebuilding every stored vector from
the fingerprints reproduces all 12,180 vectors with a worst-case absolute
difference of 5.551e-17 (float64 rounding level). See QUERY.md.

Usage:
    python query_vector.py --dir PATH --candidate slide_0_1_h1 [--top N]
    python query_vector.py --dir PATH --verify-all
"""

import argparse
import json
import math
import os
import pathlib
import sqlite3
import struct
import sys

EPSILON = 4.0 / 65535.0
SCALE_AMPLITUDE = 1.0 / 65535.0
SCALE_SPECTRAL = 0.625 / 65535.0
SHAPE_SCALE = 4.0
MEAN_WEIGHT = 0.8
STD_WEIGHT = 0.2
FRAMES = 8
HARMONIC_BINS = 32
BAND_BINS = 16
SHAPE_SIZE = FRAMES * (HARMONIC_BINS + BAND_BINS)  # 384
DIMENSION = 2 * SHAPE_SIZE  # 768


def decode_fingerprint(blob: bytes):
    if len(blob) != 436 * 2:
        raise ValueError("fingerprint blob must be 872 bytes")
    raw = struct.unpack("<436H", blob)
    values = [0.0] * 436
    for i in range(52):
        values[i] = raw[i] * SCALE_AMPLITUDE
    for i in range(52, 436):
        values[i] = raw[i] * SCALE_SPECTRAL
    return values


def normalized_shape(fingerprint):
    shape = fingerprint[52:436]
    out = [0.0] * SHAPE_SIZE
    block = HARMONIC_BINS + BAND_BINS
    for frame in range(FRAMES):
        base = frame * block
        for part, size in ((0, HARMONIC_BINS), (HARMONIC_BINS, BAND_BINS)):
            start = base + part
            norm = math.sqrt(sum(v * v for v in shape[start:start + size]))
            denom = norm if norm > EPSILON else EPSILON
            for j in range(size):
                out[start + j] = shape[start + j] / denom / SHAPE_SCALE
    return out


def build_query_vector(fingerprints):
    """fingerprints: the candidate's 4 decoded fingerprints, in note order."""
    if len(fingerprints) != 4:
        raise ValueError("exactly 4 fingerprints are required")
    shapes = [normalized_shape(fp) for fp in fingerprints]
    vector = [0.0] * DIMENSION
    mean_gain = math.sqrt(MEAN_WEIGHT)
    std_gain = math.sqrt(STD_WEIGHT)
    for i in range(SHAPE_SIZE):
        column = [s[i] for s in shapes]
        mean = sum(column) / 4.0
        variance = sum((v - mean) ** 2 for v in column) / 4.0
        vector[i] = mean_gain * mean
        vector[SHAPE_SIZE + i] = std_gain * math.sqrt(variance)
    return vector


def open_readonly(path: str) -> sqlite3.Connection:
    # as_uri() percent-encodes the path correctly (a hand-built "file:"
    # string breaks on paths containing '%', '#', '?' and similar).
    uri = pathlib.Path(os.path.abspath(path)).as_uri() + "?mode=ro&immutable=1"
    return sqlite3.connect(uri, uri=True)


def load_fingerprints(runtime: sqlite3.Connection, candidate_id: str):
    rows = runtime.execute(
        "SELECT fingerprint_blob FROM search_fingerprints "
        "WHERE candidate_id = ? ORDER BY note_index",
        (candidate_id,),
    ).fetchall()
    if len(rows) != 4:
        raise SystemExit(f"candidate not found or incomplete: {candidate_id}")
    return [decode_fingerprint(row[0]) for row in rows]


def stored_vector(search: sqlite3.Connection, candidate_id: str):
    row = search.execute(
        "SELECT vector_blob FROM search_vectors WHERE candidate_id = ?",
        (candidate_id,),
    ).fetchone()
    if row is None:
        raise SystemExit(f"unknown candidate: {candidate_id}")
    return struct.unpack(f"<{DIMENSION}d", row[0])


def squared_distance(a, b) -> float:
    return sum((x - y) ** 2 for x, y in zip(a, b))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", required=True, help="database directory")
    parser.add_argument("--candidate", default="slide_0_1_h1")
    parser.add_argument("--top", type=int, default=5)
    parser.add_argument("--verify-all", action="store_true",
                        help="rebuild every stored vector and report the worst difference")
    args = parser.parse_args()

    runtime = open_readonly(os.path.join(args.dir, "patchslide.sqlite"))
    search = open_readonly(os.path.join(args.dir, "patchslide_search.sqlite"))

    if args.verify_all:
        worst = 0.0
        worst_id = None
        count = 0
        ids = [r[0] for r in runtime.execute(
            "SELECT candidate_id FROM candidates ORDER BY candidate_no")]
        for candidate_id in ids:
            built = build_query_vector(load_fingerprints(runtime, candidate_id))
            stored = stored_vector(search, candidate_id)
            diff = max(abs(a - b) for a, b in zip(built, stored))
            if diff > worst:
                worst, worst_id = diff, candidate_id
            count += 1
        print(f"verified {count} candidates; worst max|diff| = {worst:.3e} at {worst_id}")
        return 0

    built = build_query_vector(load_fingerprints(runtime, args.candidate))
    stored = stored_vector(search, args.candidate)
    diff = max(abs(a - b) for a, b in zip(built, stored))
    print(f"{args.candidate}: rebuilt vs stored max|diff| = {diff:.3e}")
    results = []
    for other_id, blob in search.execute(
            "SELECT candidate_id, vector_blob FROM search_vectors"):
        if other_id == args.candidate:
            continue
        target = struct.unpack(f"<{DIMENSION}d", blob)
        results.append((squared_distance(built, target), other_id))
    results.sort(key=lambda item: (item[0], item[1]))
    print(f"nearest {args.top} (searched with the rebuilt vector):")
    for distance, other_id in results[:args.top]:
        print(f"  {other_id}  squared_distance={distance:.6f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
