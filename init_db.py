import os
import sqlite3

DB_PATH = "data/archivist.db"

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

con = sqlite3.connect(DB_PATH)
con.execute("PRAGMA foreign_keys = ON")
con.executescript(open("archivist/db/schema.sql").read())
con.commit()
con.close()
print("Database created.")