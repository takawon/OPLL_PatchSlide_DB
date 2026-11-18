-- Actual schema of the distributed patchslide_search.sqlite (PRAGMA user_version = 2).

-- Dumped from the patchslide-pruned-v1-compact release files for reference.

PRAGMA user_version = 2;



CREATE TABLE candidate_tags(
 candidate_id TEXT NOT NULL REFERENCES tagging_candidates(candidate_id),
 tag TEXT NOT NULL REFERENCES tags(tag),method TEXT NOT NULL,score REAL,
 PRIMARY KEY(candidate_id,tag)
) WITHOUT ROWID;

CREATE TABLE cluster_memberships(
 cluster_set_id TEXT NOT NULL,candidate_id TEXT NOT NULL REFERENCES search_vectors(candidate_id),cluster_id INTEGER NOT NULL,
 PRIMARY KEY(cluster_set_id,candidate_id),
 FOREIGN KEY(cluster_set_id,cluster_id) REFERENCES clusters(cluster_set_id,cluster_id)
) WITHOUT ROWID;

CREATE TABLE cluster_sets(
 cluster_set_id TEXT PRIMARY KEY,version TEXT NOT NULL,cluster_count INTEGER NOT NULL CHECK(cluster_count IN(16,64)),
 algorithm TEXT NOT NULL,distance_method TEXT NOT NULL,provenance_json TEXT NOT NULL,provenance_sha256 TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE clusters(
 cluster_set_id TEXT NOT NULL REFERENCES cluster_sets(cluster_set_id),cluster_id INTEGER NOT NULL,
 representative_candidate_id TEXT NOT NULL REFERENCES search_vectors(candidate_id),
 member_count INTEGER NOT NULL CHECK(member_count>0),statistics_json TEXT NOT NULL,statistics_sha256 TEXT NOT NULL,
 PRIMARY KEY(cluster_set_id,cluster_id)
) WITHOUT ROWID;

CREATE TABLE search_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) WITHOUT ROWID;

CREATE TABLE search_methods(
 method_id TEXT PRIMARY KEY,method_version TEXT NOT NULL,dimension INTEGER NOT NULL CHECK(dimension=768),
 vector_codec TEXT NOT NULL CHECK(vector_codec IN ('f64le_v1','f32le_v1')),
 config_json TEXT NOT NULL,config_sha256 TEXT NOT NULL,layout_json TEXT NOT NULL,layout_sha256 TEXT NOT NULL,
 implementation_sha256 TEXT NOT NULL,generator_version TEXT NOT NULL,generator_sha256 TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE search_vectors(
 candidate_id TEXT PRIMARY KEY,method_id TEXT NOT NULL REFERENCES search_methods(method_id),
 dimension INTEGER NOT NULL CHECK(dimension=768),codec TEXT NOT NULL,
 vector_blob BLOB NOT NULL,vector_sha256 TEXT NOT NULL,
 CHECK((codec='f64le_v1' AND length(vector_blob)=6144) OR (codec='f32le_v1' AND length(vector_blob)=3072))
) WITHOUT ROWID;

CREATE TABLE tagging_candidates(
 candidate_id TEXT PRIMARY KEY REFERENCES search_vectors(candidate_id),
 representative_note INTEGER,status TEXT NOT NULL,diagnostics_json TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE tagging_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) WITHOUT ROWID;

CREATE TABLE tags(
 tag TEXT PRIMARY KEY,ordinal INTEGER NOT NULL UNIQUE CHECK(ordinal>=0),
 status TEXT NOT NULL,method TEXT NOT NULL,reference_json TEXT NOT NULL
) WITHOUT ROWID;

CREATE INDEX candidate_tags_tag ON candidate_tags(tag,candidate_id);

CREATE INDEX membership_cluster ON cluster_memberships(cluster_set_id,cluster_id,candidate_id);
