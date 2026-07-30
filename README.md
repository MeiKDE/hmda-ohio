# Ohio mortgage lending, 2022–2024

An end-to-end analysis of the public **HMDA Loan Application Register** for Ohio — 1.45 million
loan application records — built with DuckDB and dbt.

The question it sets out to answer: **how much of the denial-rate gap between racial groups is
explained by income?** The short answer, for Ohio, is *very little* — and that's the finding
this repository is organised around.

```
CFPB Data Browser  →  DuckDB  →  dbt (staging → marts, tested)  →  BI / notebook
```

---

## The finding

**2024, decisioned applications, Ohio:**

| Applicant race | Applications | Denial rate | Median income |
|---|---:|---:|---:|
| White | 243,680 | **21.6%** | $87k |
| Black or African American | 26,437 | **35.9%** | $70k |
| Asian | 9,994 | 21.8% | $115k |
| American Indian or Alaska Native | 1,137 | 38.6% | $65k |
| Race not available | 51,677 | 26.3% | $86k |

A 14-point gap, and Black applicants do report lower median income — so the obvious hypothesis is
that the gap is an income-mix effect. **It mostly isn't.** Holding income roughly constant by
comparing applicants inside the same band:

| $50–100k income band, 2024 | Applications | Denial rate |
|---|---:|---:|
| White | 96,105 | **21.3%** |
| Black or African American | 11,840 | **33.1%** |
| Asian | 2,882 | 23.7% |

The gap narrows from 14.3 points to 11.8 — so income mix accounts for roughly **one sixth** of it.
The rest sits somewhere else.

Where? The reported denial reasons point at credit history rather than affordability:

| Primary denial reason, 2024 | Black applicants | White applicants |
|---|---:|---:|
| Credit history | **38.0%** | 34.0% |
| Debt-to-income ratio | 27.6% | 28.4% |

Debt-to-income — the affordability measure — is essentially identical between the two groups.
Credit history is where they diverge.

**What this does and does not show.** HMDA does not include credit score, so this cannot separate
"applicants presented different credit profiles" from "similar credit profiles were treated
differently." No conclusion about discrimination is available from this data alone, and none is
drawn here. What it does establish is that the standard first explanation — income — accounts for
much less of the gap than its prominence in the conversation suggests, and it points the next
question at credit-history underwriting.

---

## Running it

Requires [uv](https://docs.astral.sh/uv/). No database server — DuckDB is a file.

```bash
./download.sh                       # ~520MB of CSV from the CFPB Data Browser
uv run python load_raw.py           # → raw.lar in hmda.duckdb
DBT_PROFILES_DIR=. uv run dbt build # staging + marts + tests
```

The full build takes well under a minute on a laptop after the download.

## Layout

| | |
|---|---|
| `download.sh` | Pulls the Ohio LAR extracts, 2022–2024, from the CFPB Data Browser API |
| `load_raw.py` | Lands the CSVs in DuckDB as `raw.lar`, verbatim and all-varchar |
| `models/staging/stg_lar.sql` | Types, labels, and defines what counts as a *decisioned* application |
| `models/marts/` | Five analysis tables (below) |

**Marts**

| Model | What it answers |
|---|---|
| `mart_denial_by_race` | Denial rate and median income by applicant race and year |
| `mart_denial_by_income_band` | The same cut, holding income band constant — the control |
| `mart_denial_reasons` | Which reason drove each denial, by race |
| `mart_lender_summary` | Per-lender volume, denial rate, median rate (≥250 applications) |
| `mart_county_trend` | Origination volume, denial rate, median property value by county |

## Two decisions worth explaining

Both are the kind of thing that quietly makes published HMDA numbers disagree with each other.

**What counts as a denial rate.** The denominator here is *decisioned* applications only —
originated, approved-but-not-accepted, and denied. Withdrawals and incomplete files are excluded
because those are the applicant's decision, not the lender's, and purchased loans are excluded
because they were decisioned by a different institution in a different year. Leaving purchased
loans in is the most common way a HMDA denial rate comes out wrong; in this file they are 130,000
records, about 9% of the total.

**"NA" and "Exempt" are values, not nulls.** HMDA uses both as in-band sentinels in otherwise
numeric columns. The raw table is deliberately loaded all-varchar so no CSV reader silently
coerces them, and the casting happens once in `stg_lar` where it can be read and argued with.
Around 164,000 records report no income and 25,000 are exempt from the debt-to-income field.
"Race not available" is 22% of the file and is kept as its own row throughout rather than dropped —
dropping it would overstate how complete the demographic picture is.

## Source

[CFPB / FFIEC HMDA Data Browser](https://ffiec.cfpb.gov/data-browser/) — the public modified Loan
Application Register, filtered to Ohio. The modified LAR is privacy-protected at source.
Data for 2022–2024; 1,449,359 records.
