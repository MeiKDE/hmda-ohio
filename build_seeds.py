"""Fetch the two reference tables the marts join to, and write them as dbt seeds.

    uv run python build_seeds.py   # → seeds/ohio_counties.csv, seeds/lenders.csv

HMDA identifies counties by 5-digit FIPS code and lenders by LEI. Neither is
readable on a chart, so the names come from their official sources:

- counties: Census Bureau 2020 county reference file for Ohio
- lenders:  the CFPB's HMDA filer list, one per year; the latest name wins,
            and only lenders that actually appear in the Ohio file are kept
"""
import csv
import io
import json
import urllib.request

import duckdb

COUNTIES = "https://www2.census.gov/geo/docs/reference/codes2020/cou/st39_oh_cou2020.txt"
FILERS = "https://ffiec.cfpb.gov/v2/reporting/filers/{year}"
YEARS = (2022, 2023, 2024)


def fetch(url):
    with urllib.request.urlopen(url, timeout=60) as r:
        return r.read().decode("utf-8")


def counties():
    rows = csv.DictReader(io.StringIO(fetch(COUNTIES)), delimiter="|")
    out = [(r["STATEFP"] + r["COUNTYFP"], r["COUNTYNAME"].removesuffix(" County")) for r in rows]
    write("seeds/ohio_counties.csv", ("county_code", "county_name"), sorted(out))
    return len(out)


def lenders():
    names = {}
    for year in YEARS:  # ascending, so the latest year's name overwrites
        for inst in json.loads(fetch(FILERS.format(year=year)))["institutions"]:
            names[inst["lei"]] = inst["name"].strip()
    con = duckdb.connect("hmda.duckdb", read_only=True)
    in_file = {r[0] for r in con.sql("select distinct lei from raw.lar").fetchall()}
    out = sorted((lei, names[lei]) for lei in in_file if lei in names)
    write("seeds/lenders.csv", ("lender_lei", "lender_name"), out)
    return len(out), len(in_file)


def write(path, header, rows):
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)


if __name__ == "__main__":
    print(f"counties: {counties()}")
    named, total = lenders()
    print(f"lenders:  {named} of {total} named")
