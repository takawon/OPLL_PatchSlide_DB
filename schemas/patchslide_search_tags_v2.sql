PRAGMA foreign_keys=ON;
PRAGMA user_version=2;
CREATE TABLE tags(
 tag TEXT PRIMARY KEY,ordinal INTEGER NOT NULL UNIQUE CHECK(ordinal>=0),
 status TEXT NOT NULL,method TEXT NOT NULL,reference_json TEXT NOT NULL
) WITHOUT ROWID;
CREATE TABLE tagging_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) WITHOUT ROWID;
CREATE TABLE tagging_candidates(
 candidate_id TEXT PRIMARY KEY REFERENCES search_vectors(candidate_id),
 representative_note INTEGER,status TEXT NOT NULL,diagnostics_json TEXT NOT NULL
) WITHOUT ROWID;
CREATE TABLE candidate_tags(
 candidate_id TEXT NOT NULL REFERENCES tagging_candidates(candidate_id),
 tag TEXT NOT NULL REFERENCES tags(tag),method TEXT NOT NULL,score REAL,
 PRIMARY KEY(candidate_id,tag)
) WITHOUT ROWID;
CREATE INDEX candidate_tags_tag ON candidate_tags(tag,candidate_id);
UPDATE search_meta SET value='2' WHERE key='schema_version';
