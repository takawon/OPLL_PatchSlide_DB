-- Actual schema of the distributed patchslide.sqlite (PRAGMA user_version = 1).

-- Dumped from the patchslide-pruned-v1-compact release files for reference.

PRAGMA user_version = 1;



CREATE VIEW v_auto_safe_candidates AS
SELECT *
FROM candidates
WHERE
    auto_safe = 1
    AND enabled = 1;

CREATE VIEW v_manual_candidates AS
SELECT *
FROM candidates
WHERE
    manual_use_allowed = 1
    AND enabled = 1;

CREATE TABLE candidates (
    candidate_id        TEXT PRIMARY KEY,
    candidate_no        INTEGER NOT NULL UNIQUE,

    change_count        INTEGER NOT NULL
                         CHECK(change_count IN (1,2)),

    patch_a             INTEGER NOT NULL
                         CHECK(patch_a BETWEEN 0 AND 14),

    patch_b             INTEGER NOT NULL
                         CHECK(patch_b BETWEEN 0 AND 14),

    patch_c             INTEGER
                         CHECK(patch_c BETWEEN 0 AND 14),

    hold_pattern        TEXT NOT NULL
                         CHECK(hold_pattern IN
                           ('h1','h2','h11','h12','h21','h22')),

    hold_a_steps        INTEGER NOT NULL
                         CHECK(hold_a_steps IN (1,2)),

    hold_b_steps        INTEGER
                         CHECK(hold_b_steps IN (1,2)),

    auto_safe           INTEGER NOT NULL
                         CHECK(auto_safe IN (0,1)),

    manual_use_allowed  INTEGER NOT NULL
                         CHECK(manual_use_allowed IN (0,1)),

    visibility          TEXT NOT NULL
                         CHECK(visibility IN
                           ('normal','manual_warning','hidden')),

    enabled             INTEGER NOT NULL
                         CHECK(enabled IN (0,1)),

    classifier_version  TEXT NOT NULL,

    predicted_partition TEXT
                         REFERENCES partition_codes(code),

    raw_different_count INTEGER
                         CHECK(raw_different_count BETWEEN 0 AND 6),

    human_pattern       TEXT
                         REFERENCES partition_codes(code),

    CHECK (
        (change_count = 1
         AND patch_c IS NULL
         AND hold_b_steps IS NULL)
        OR
        (change_count = 2
         AND patch_c IS NOT NULL
         AND hold_b_steps IS NOT NULL)
    )
);

CREATE TABLE db_meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE decision_policy (
    policy_version      TEXT PRIMARY KEY,

    rule_text           TEXT NOT NULL,
    config_json         TEXT NOT NULL,
    config_sha256       TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE fingerprint_layouts (
    fingerprint_version TEXT PRIMARY KEY,

    codec               TEXT NOT NULL,
    element_count       INTEGER NOT NULL,

    envelope_bins       INTEGER NOT NULL,
    spectrum_frames     INTEGER NOT NULL,
    harmonic_bins       INTEGER NOT NULL,
    log_band_bins       INTEGER NOT NULL,

    layout_json         TEXT NOT NULL,
    layout_sha256       TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE partition_codes (
        code TEXT PRIMARY KEY
    ) WITHOUT ROWID;

CREATE TABLE search_fingerprints (
    candidate_id        TEXT NOT NULL
                         REFERENCES candidates(candidate_id)
                         ON DELETE CASCADE,

    note_index          INTEGER NOT NULL
                         CHECK(note_index BETWEEN 1 AND 4),

    fingerprint_version TEXT NOT NULL
                         REFERENCES fingerprint_layouts(
                             fingerprint_version
                         ),

    fingerprint_codec   TEXT NOT NULL,

    fingerprint_blob    BLOB NOT NULL,
    fingerprint_sha256  TEXT NOT NULL,

    PRIMARY KEY(
        candidate_id,
        note_index,
        fingerprint_version
    )
) WITHOUT ROWID;

CREATE INDEX idx_runtime_auto_safe
ON candidates(auto_safe);

CREATE INDEX idx_runtime_hold
ON candidates(hold_pattern);

CREATE INDEX idx_runtime_patch
ON candidates(patch_a, patch_b, patch_c);
