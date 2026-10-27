import random
import re
from datetime import date

from faker import Faker

DEPARTMENTS = ["Cataloguing", "Preservation", "Reading Room", "Acquisitions", "Records"]
AUDITOR_HIRE_DATE = "2026-03-02"

def seed_reference_data(conn, seed):
    rng = random.Random(seed)  # own random generator 
    Faker.seed(seed)           # seeds Faker's randomness
    fake = Faker()   

    seed_floors(conn) 
    seed_hosts(conn, rng)
    seed_people(conn, rng, fake)
    seed_books(conn, rng, fake)
    conn.commit()

def seed_floors(conn):
    tuple = [
        (0, "Floor 0", 0),
        (1, "Floor 1", 1),
        (2, "Floor 2", 1),
        (3, "Floor 3", 1),
        (4, "Floor 4", 1),
        (5, "Floor 5", 1),
        (6, "Floor 6", 1),
        (7, "Floor 7", 1),
        (8, "Floor 8", 1),
        (9, "Floor 9", 1),
        (10, "Floor 10", 1),
        (11, "Floor 11", 1),
        (12, "Floor 12", 1),
        (13, "Floor 13", 0)
    ]

    conn.executemany(
        "INSERT INTO floors (floor_id, label, is_official) VALUES (?, ?, ?)",
        tuple,
    )

def seed_hosts(conn, rng):
    tuple = []

    for floor in range (1, 13):
        how_many = rng.randint(3, 5)
        for n in range (1, how_many + 1):
            hostname = f"fl{floor:02d}-ws-{n:02d}"
            tuple.append((hostname, floor, 0))

    # servers
    tuple.append(("cat-srv-01", 1, 1))
    tuple.append(("file-srv-01", 2, 1))
    tuple.append(("auth-srv-01", 1, 1))

    conn.executemany(
        "INSERT INTO hosts (hostname, floor_id, is_server) VALUES (?, ?, ?)",
        tuple,
    )

def make_username(first, last, used):
    base = re.sub(r"[^a-z]", "", (first[0] + last).lower())
    username = base
    counter = 2
    while username in used:
        username = f"{base}{counter}"
        counter += 1
    used.add(username)
    return username

def add_person(conn, legal_name, hired_on, status, username, role, department):
    cur = conn.execute(
        "INSERT INTO hr_record (legal_name, hired_on, status) VALUES (?, ?, ?)",
        (legal_name, hired_on, status),
    )
    hr_id = cur.lastrowid
    conn.execute(
        "INSERT INTO users (username, role, department, hr_record_id) VALUES (?, ?, ?, ?)",
        (username, role, department, hr_id),
    )



def seed_people(conn, rng, fake):
    used = set()

    for i in range(40):
        first = fake.first_name()
        last = fake.last_name()
        hired_on = fake.date_between(
            start_date=date(2005,1,1), end_date=date(2024,12,31)
        ).isoformat()
        status = "retired" if i < 3 else "active"
        username = make_username(first, last, used)
        department = rng.choice(DEPARTMENTS)
        add_person(conn, f"{first} {last}", hired_on, status, username, "custodian", department)

    # the player
    used.add("auditor")
    add_person(conn, "The Auditor", AUDITOR_HIRE_DATE, "active", "auditor", "auditor", "Audit")

def seed_books(conn, rng, fake):
    tuple = []
    used_cats = set()

    for i in range (1, 61):
        cat_no = rng.randint(1000, 1100)
        while cat_no == 1024 or cat_no in used_cats:
            cat_no = rng.randint(1000, 1100)

        used_cats.add(cat_no)
        
        author = fake.name()
        title_words = fake.words(nb=rng.randint(2, 5))
        title = " ".join(title_words).title()

        status = rng.choice(["old"] * 85 + ["new"] * 15)
        tuple.append((cat_no, author, title, status))

    conn.executemany(
        "INSERT INTO books (catalog_no, author, title, status) VALUES (?, ?, ?, ?)",
        tuple,
    )
        
