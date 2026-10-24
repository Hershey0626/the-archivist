-- ============================================================
-- The Archivist: database schema (SQLite)
-- NOTE: SQLite does not enforce foreign keys unless you run
--       PRAGMA foreign_keys = ON;   on every new connection.
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- BUILDING
-- ------------------------------------------------------------
-- Floors officially run 1-12. Floors 0 and 13 exist in the data
-- but are flagged as unofficial (is_official = 0).
CREATE TABLE floors (
    floor_id     INTEGER PRIMARY KEY,          -- the floor number itself (0, 1..12, 13)
    label        TEXT    NOT NULL,
    is_official  INTEGER NOT NULL DEFAULT 1 CHECK (is_official IN (0, 1))
);

CREATE TABLE hosts (
    host_id      INTEGER PRIMARY KEY,
    hostname     TEXT    NOT NULL UNIQUE,
    floor_id     INTEGER NOT NULL REFERENCES floors(floor_id),
    is_server    INTEGER NOT NULL DEFAULT 0 CHECK (is_server IN (0, 1))
);

-- ------------------------------------------------------------
-- PEOPLE
-- ------------------------------------------------------------
-- HR data lives in its own table. A "ghost Custodian" is a user
-- whose hr_record_id is NULL (an anti-join target).
CREATE TABLE hr_records (
    hr_id        INTEGER PRIMARY KEY,
    legal_name   TEXT NOT NULL,
    hired_on     TEXT NOT NULL,                -- ISO date, 'YYYY-MM-DD'
    status       TEXT NOT NULL CHECK (status IN ('active', 'retired', 'terminated'))
);

CREATE TABLE users (
    user_id        INTEGER PRIMARY KEY,
    username       TEXT NOT NULL UNIQUE,
    role           TEXT NOT NULL CHECK (role IN ('auditor', 'custodian', 'service')),
    department     TEXT,
    hr_record_id   INTEGER REFERENCES hr_records(hr_id)   -- NULL = no HR record (ghost)
);

-- ------------------------------------------------------------
-- CATALOG
-- ------------------------------------------------------------
-- The reconciliation job: old books sorted by author, new by title.
CREATE TABLE books (
    book_id      INTEGER PRIMARY KEY,
    catalog_no   INTEGER NOT NULL UNIQUE,      -- one number (1024) is deliberately never used
    author       TEXT,                         -- NULL = author removed from the record
    title        TEXT NOT NULL,
    status       TEXT NOT NULL CHECK (status IN ('old', 'new', 'missing'))
);

CREATE TABLE files (
    file_id           INTEGER PRIMARY KEY,
    book_id           INTEGER REFERENCES books(book_id),
    filename          TEXT    NOT NULL,
    sensitivity_level INTEGER NOT NULL CHECK (sensitivity_level BETWEEN 1 AND 5),
    created_at        TEXT    NOT NULL,
    deleted_at        TEXT                     -- NOT NULL = deleted (files that "open themselves")
);

-- ------------------------------------------------------------
-- EVENT LOGS (the evidence)
-- ------------------------------------------------------------
-- event_id is NOT AUTOINCREMENT on purpose: the generator deletes
-- rows to create gaps (the "vanishing emails").
CREATE TABLE login_events (
    event_id            INTEGER PRIMARY KEY,
    session_id          TEXT,                                 -- links a login to its logout
    event_type          TEXT    NOT NULL CHECK (event_type IN ('login', 'logout')),
    user_id             INTEGER REFERENCES users(user_id),    -- NULL when the username does not exist
    username_attempted  TEXT    NOT NULL,                     -- real logs record what was typed
    host_id             INTEGER NOT NULL REFERENCES hosts(host_id),
    ts                  TEXT    NOT NULL,                     -- ISO timestamp
    ip_address          TEXT    NOT NULL,
    country             TEXT,
    success             INTEGER NOT NULL CHECK (success IN (0, 1))
);

CREATE TABLE file_access (
    access_id    INTEGER PRIMARY KEY,
    user_id      INTEGER NOT NULL REFERENCES users(user_id),
    file_id      INTEGER NOT NULL REFERENCES files(file_id),
    action       TEXT    NOT NULL CHECK (action IN ('read', 'write', 'copy', 'delete')),
    bytes        INTEGER NOT NULL DEFAULT 0,
    ts           TEXT    NOT NULL
);

CREATE TABLE network_flows (
    flow_id        INTEGER PRIMARY KEY,
    src_host_id    INTEGER NOT NULL REFERENCES hosts(host_id),
    dst_address    TEXT    NOT NULL,
    dst_hostname   TEXT,                       -- a name with no match in hosts = the Floor 13 host
    bytes_out      INTEGER NOT NULL,
    ts             TEXT    NOT NULL,
    is_heartbeat   INTEGER NOT NULL DEFAULT 0 CHECK (is_heartbeat IN (0, 1))   -- the 01:11 pings
);

-- ------------------------------------------------------------
-- GAME STATE
-- ------------------------------------------------------------
CREATE TABLE cases (
    case_id          INTEGER PRIMARY KEY,
    case_type        TEXT    NOT NULL CHECK (case_type IN ('brute_force', 'phishing', 'insider_exfil')),
    difficulty       INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 3),
    week             INTEGER NOT NULL CHECK (week BETWEEN 1 AND 3),
    seed             INTEGER NOT NULL,         -- reproducible generation
    culprit_user_id  INTEGER REFERENCES users(user_id),
    solved           INTEGER NOT NULL DEFAULT 0 CHECK (solved IN (0, 1))
);

-- Every query or hint costs one action. 10 per in-game day.
CREATE TABLE player_actions (
    action_id    INTEGER PRIMARY KEY,
    case_id      INTEGER NOT NULL REFERENCES cases(case_id),
    game_day     INTEGER NOT NULL,
    action_type  TEXT    NOT NULL CHECK (action_type IN ('query', 'hint', 'accusation')),
    query_text   TEXT,
    cost         INTEGER NOT NULL DEFAULT 1,
    created_at   TEXT    NOT NULL
);

-- ------------------------------------------------------------
-- INDEXES: intentionally commented out for now.
-- Benchmark your slow queries FIRST, then enable these and
-- record the speedup. That before/after is a resume bullet.
-- ------------------------------------------------------------
-- CREATE INDEX idx_login_user_ts   ON login_events(user_id, ts);
-- CREATE INDEX idx_login_ip        ON login_events(ip_address);
-- CREATE INDEX idx_access_user_ts  ON file_access(user_id, ts);
-- CREATE INDEX idx_flows_host_ts   ON network_flows(src_host_id, ts);
