import sqlite3
from archivist.db.seed import seed_reference_data

conn = sqlite3.connect(":memory:")
conn.execute("PRAGMA foreign_keys = ON")
conn.executescript(open("archivist/db/schema.sql").read())
seed_reference_data(conn, 1)

print(conn.execute("SELECT COUNT(*) FROM floors").fetchone())
print(conn.execute("SELECT floor_id FROM floors WHERE is_official = 0").fetchall())
print(conn.execute("SELECT COUNT(*) FROM hosts").fetchone())
print(conn.execute("SELECT COUNT(*) FROM hosts WHERE floor_id IN (0, 13)").fetchone())
print(conn.execute("SELECT COUNT(*) FROM users").fetchone())
print(conn.execute("SELECT COUNT(*) FROM users WHERE role = 'auditor'").fetchone())
print(conn.execute("SELECT COUNT(*) FROM users WHERE hr_record_id IS NULL").fetchone())
print("Total books:", conn.execute("SELECT COUNT(*) FROM books").fetchone())
print("Books with catalog_no 1024:", conn.execute("SELECT * FROM books WHERE catalog_no = 1024").fetchall())