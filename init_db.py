import os
import sqlite3
from archivist.db.seed import seed_reference_data  # <-- Import your seeding function

DB_PATH = "data/archivist.db"

# Ensure the directory exists if it doesn't already
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

con = sqlite3.connect(DB_PATH)
con.execute("PRAGMA foreign_keys = ON")
con.executescript(open("archivist/db/schema.sql").read())

# Run your seed function (using a default seed like 1)
seed_reference_data(con, seed=1)

con.commit()
con.close()
print("Database created and seeded successfully.")