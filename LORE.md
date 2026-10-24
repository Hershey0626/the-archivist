# The Archives: The Lore

**SPOILERS. Design reference for the author.**

---

## 1. Institution

The Archives is a private repository with no address, no public catalog, and no visitors. It stores "materials of continuing interest." No one on staff can say whose interest.

- **The Office of Continuity** runs it. It issues memos, never signs them, and has never been seen.
- **Custodians** staff it. They are never called employees.
- **The Auditor** (the player) is hired to review the access logs.
- **Handbook Rule #1:** *The Archive is always open. The Archive is never busy.*
- The building officially has **floors 1 to 12**. Nobody has ever seen its exterior.

**Tone rules**

- Everyone is polite. Nothing is ever explained.
- Dread comes from calm, not gore. The worse it gets, the more courteous the language.
- Rules exist without reasons. Numbers matter without explanation.
- Never use show-specific names or imagery from other works. Keep the vocabulary your own.

## 2. The mundane job

The Auditor is assigned a **three-week reconciliation project**:

- **Old collection:** novels shelved alphabetically by **author**
- **New collection:** novels catalogued alphabetically by **title**
- The Auditor reconciles the two lists and signs off

This is the tutorial layer and a real `books` table (`author`, `title`, `catalog_no`, `status`: `old` / `new` / `missing`). The mystery hides underneath it.

**The twist to plan toward:** the shelving task and the security investigation turn out to be the same mystery. The "new" books are the old ones, retitled, and the authors are being removed from the record, not replaced. Alphabetizing by title instead of author is how the Archive forgets who wrote what.

## 3. The player's constraints

- **10 messages per day** to Custodians, which is also the **action budget** (queries and hints each cost one).
- **Inbox pings every 5 seconds.** Some emails vanish when opened, which corresponds to **gaps in the audit log** (see section 5).
- The Auditor is **never permitted to meet a Custodian**. Every interaction is mediated.

## 4. The numbers (dread system)

Recurring figures are the core of the unease. Plant them across *different* tables so the player discovers them independently, then realizes they connect.

| Motif | Details | Where it hides |
|---|---|---|
| **01:11 "Quiet Hours"** | Every night at exactly 01:11 a heartbeat event fires on all hosts, with the same byte count every time | `network_flows`, `login_events` |
| **Floor 13 and Floor 0** | Floors officially run 1 to 12. Sessions originate from both | `hosts`, `login_events` |
| **The Tally (1024)** | The total bytes of all "ghost" sessions is always a multiple of 1024 (2048, 4096, ...). No one can explain it | derived by `SUM` over ghost sessions |
| **Catalog 1024** | Catalog numbers run 1022, 1023, 1025, 1026. **1024 is never mentioned, ever** | `files`, `books` |

## 5. The hidden layer: scary things as SQL puzzles

Each anomaly is a deliberate data-integrity violation.

| In-world event | What is planted in the data | SQL concept |
|---|---|---|
| **Ghost Custodians:** accounts that work every night with no HR record | `login_events.user_id` with no matching `users` row | `LEFT JOIN ... WHERE ... IS NULL` (anti-join) |
| **Sessions that never end:** logged in 11 years ago, never logged out | login with no corresponding logout | `NOT EXISTS` |
| **Vanishing emails / missing event IDs** | `event_id` jumps from 8812 to 8815 | `LAG`, gaps-and-islands |
| **The Floor 13 host** | a host in `network_flows` absent from `hosts` | `EXCEPT`, join mismatch |
| **The Auditor before you** | your own account active a year before you were hired | date filtering |
| **Files that open themselves** | `file_access` on manuscripts with `deleted_at` set | `JOIN` with a date condition |
| **The pattern:** every anomaly lands within 1 second of 01:11 | a hidden recurring timestamp | time-bucket `GROUP BY`, CTEs |

**The best twist:** the logs show the player's own account active long before they were hired. The role has been filled before. It costs a few rows to build.

## 6. The three phases (narrative arc)

**Week 1: *The Midnight Reader* (brute force, easy)**
Someone hammers the login for an account that does not exist in `users`. The player finds the attacker's IP (`GROUP BY` / `HAVING`). The first reveal: the target account was a ghost, so the Archive's own staff list is incomplete.

**Week 2: *The Forged Invitation* (phishing, medium)**
A Custodian clicks a fake "rare book auction" email, and their credentials are then used in two places that should not be connected, such as Floor 4 and Floor 13 within minutes (`LAG`). The second reveal: Floor 13 exists, and someone has been maintaining it.

**Week 3: *The Quiet Curator* (insider exfiltration, hard)**
A trusted Custodian copies a manuscript at 01:11 and sends it out. The file's catalog number is the one that was never mentioned: 1024. The final reveal is the ending, below.

## 7. Tone and UI voice (`rich`)

- Palette: muted teal and beige, wide spacing, clinical boxes
- Success: `The Office thanks you for your diligence.`
- Filed answer: `Your finding has been filed.`
- Wrong answer: `This finding is not consistent with the record. Please reconsider.`
- Out of actions: `You have reached today's allotment. Please rest.`
- Rare unprompted line: `You are doing well. Do not look at Floor 13.`

## 8. The ending (undecided, pick one later)

All three options pay off the same clues, so the data does not need to change much.

1. **The Archive is recruiting.** The "attacks" were tests. The Auditor was selected because they were good at finding things. The final case is their own onboarding, and the player's final query is the one that offers them a Custodian account.
2. **The Auditor is the culprit.** The "Auditor before you" is the player. Timestamps show the player's account did every crime in earlier "weeks" that the player does not remember.
3. **The Archive is a loop.** Catalog 1024 is the Auditor's own file. Each Auditor replaces the last, and the three-week project is how new Auditors are made.

## 9. Schema hooks (for when we design the tables)

- `floors` table with a row for floor 0 and floor 13 that is "not supposed to exist"
- `books`: `book_id`, `author`, `title`, `catalog_no`, `status`, `deleted_at`
- `users.hr_record_id` nullable, so ghosts are representable
- `login_events` allows `user_id` values with no FK match in a separate "raw" staging table (or deliberately weaken the FK for planted ghost rows)
- A `heartbeats` or flagged-event concept for the 01:11 pings
- Planted rows added **after** the normal generator works. Theme is the last 10%, mechanics come first.
