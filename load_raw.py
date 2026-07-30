"""Load the downloaded HMDA CSV extracts into DuckDB as a single raw table.

Run:  uv run python load_raw.py

Source: CFPB/FFIEC HMDA Data Browser, filtered to Ohio.
        https://ffiec.cfpb.gov/data-browser/
"""

from pathlib import Path

import duckdb

DB = Path("hmda.duckdb")
DATA = Path("data")


def main():
    files = sorted(DATA.glob("hmda_oh_*.csv"))
    if not files:
        raise SystemExit("no CSVs in data/ — run the download step first")

    con = duckdb.connect(str(DB))
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    # union_by_name so a year with a different column set still loads;
    # all_varchar so HMDA's "Exempt"/"NA" sentinels don't fail type inference.
    # They get cast deliberately in the staging model instead.
    con.execute(
        """
        CREATE OR REPLACE TABLE raw.lar AS
        SELECT * FROM read_csv_auto(?, union_by_name = true, all_varchar = true)
        """,
        [[str(f) for f in files]],
    )

    rows, years = con.execute(
        "SELECT count(*), count(DISTINCT activity_year) FROM raw.lar"
    ).fetchone()
    print(f"loaded {rows:,} rows across {years} years from {len(files)} files")

    print(
        con.execute(
            """
            SELECT activity_year, count(*) AS records
            FROM raw.lar GROUP BY 1 ORDER BY 1
            """
        ).df()
    )
    con.close()


if __name__ == "__main__":
    main()
