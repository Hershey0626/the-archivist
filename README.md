# The Archivist

A SQL detective game with a quiet, corporate-horror atmosphere. You are the newly hired Auditor of an archive that has no address, no visitors, and no one who can explain what it is for. Your job is simple: review the access logs. Your only tool is SQL.

**Stack:** Python · SQLite · PyTorch · `rich`

**Focus:** SQL (JOINs, CTEs, window functions, indexing), object-oriented design, anomaly detection

## Premise

You have been hired for a three-week project at the Library of Archives. The task is routine. The Archive is replacing its old novels, shelved alphabetically by author, with a new collection, catalogued alphabetically by title. Someone has to reconcile the two lists, flag discrepancies, and sign off. That someone is you.

You will never meet the staff. They are called Custodians, never employees, and the only contact you are permitted is ten messages per day. Directives arrive from The Office of Continuity, which sends memos but never signs them. Your inbox pings every five seconds. Some emails vanish before you can open them.

Everyone is polite. Nothing is ever busy. The Archive is always open.

Then you begin reading the logs, and the logs begin to read back.

## How the Game Works

1. **Receive a case.** Each phase opens with an Audit Report describing an irregularity.
2. **Investigate with SQL.** Query the Archive's database of logins, file access, and network traffic to find what happened and who is responsible.
3. **Spend your messages wisely.** You have 10 actions per in-game day. Every query and every request for a hint costs one, so you have to think before you type.
4. **Consult the Detector.** An anomaly-detection model flags suspicious activity. It is often right and sometimes wrong. Verify its leads before you file them, because a bad accusation costs you.
5. **File your finding.** Name the culprit and submit your evidence. You are scored on correctness, efficiency, and the quality of your queries.

Every game is procedurally generated, so the case you solve is never quite the one someone else solved.

## The Three Phases

| Phase | Case | What you investigate | SQL you will use |
|---|---|---|---|
| Week 1 | The Midnight Reader | Someone is hammering a login that should not exist | `ORDER BY`, `GROUP BY`, `HAVING`, `COUNT` |
| Week 2 | The Forged Invitation | A Custodian is in two places that should not be connected | Window functions (`LAG`), self-joins, date logic |
| Week 3 | The Quiet Curator | A trusted Custodian is copying something they should not touch | Multi-table `JOIN`s, CTEs, subqueries, anti-joins |

The difficulty rises by design: the first week teaches you to read the data, the last expects you to think in sets.

## Features

- Procedural case generation: a planted attack hidden in realistic background traffic
- Three attack types built on a shared, extensible case engine
- Query validator and scorer with `EXPLAIN` output and indexing feedback
- Per-day action budget as a core mechanic
- PyTorch autoencoder "Detector" with a trust score that rises and falls with its accuracy
- Atmospheric terminal interface built with `rich`

## Architecture

### Object-oriented case engine

- `Case` is an abstract base class. `BruteForceCase`, `PhishingCase`, and `InsiderExfilCase` each override `generate_attack()` (polymorphism).
- `CaseFactory` builds a case for a given difficulty (Factory pattern).
- `Detector` is an interface with swappable implementations, rule-based or neural (Strategy pattern).
- `LogGenerator`, `Player`, `Evidence`, and `Hint` keep each responsibility in its own class.

### Database (SQLite)

Normalized schema: `users`, `hosts`, `floors`, `login_events`, `file_access`, `files`, `network_flows`, `books`, `cases`. See `archivist/db/schema.sql` and the design rationale in `docs/`.

### Machine learning (PyTorch)

An autoencoder trained on normal behavior (hour of day, location, failed attempts, bytes transferred). High reconstruction error means "suspicious." Evaluated with precision, recall, and a confusion matrix on imbalanced data.

## Project Structure

```
the-archivist/
├── archivist/
│   ├── cases/        # Case base class + attack types
│   ├── db/           # schema and queries
│   ├── detectors/    # rule-based and ML detectors
│   └── game/         # game loop, player, scoring
├── tests/
├── data/
├── docs/             # class diagram, schema notes, lore
├── main.py
└── requirements.txt
```

## Getting Started

```bash
git clone https://github.com/Hershey0626/the-archivist.git
cd the-archivist
python -m venv venv
source venv/bin/activate        # Windows (cmd): venv\Scripts\activate.bat
pip install -r requirements.txt
python main.py
```

## Inspiration

SQL-as-gameplay has a proud history, notably the Knight Lab's *SQL Murder Mystery*. The Archivist differs by generating a new case every time, framing the work as realistic security-log analysis, and pairing the player with a fallible ML assistant.

## Design Notes

The setting, recurring motifs, and hidden story are documented in [`docs/LORE.md`](LORE.md). **It contains spoilers.**

## License

MIT