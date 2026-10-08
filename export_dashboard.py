"""Export the marts as tidy tables for the Tableau Public dashboard.

    uv run --with openpyxl python export_dashboard.py

Writes dashboard/*.csv (committed — small, and diffable) and
dashboard/hmda_ohio.xlsx (one sheet per table, for upload; not committed).
"""
from pathlib import Path

import duckdb

OUT = Path("dashboard")

TABLES = {
    # The headline chart: denial rate by income band, by race. Band order is
    # carried as a number so the chart sorts low → high, not alphabetically.
    "income_gap": """
        select activity_year as year,
               case income_band when '< $50k' then 1 when '$50–100k' then 2
                                when '$100–150k' then 3 when '$150–250k' then 4
                                when '$250k+' then 5 end as band_order,
               income_band, applicant_race as race,
               decisioned_applications, denials, denial_rate_pct
        from mart_denial_by_income_band
        where income_band <> 'Not reported'
        order by year, band_order, race
    """,
    "counties": """
        select activity_year as year, county_code as fips, county_name || ' County' as county,
               'Ohio' as state, decisioned_applications, originations,
               denial_rate_pct, originated_volume_musd, median_property_value
        from mart_county_trend
        order by year, county
    """,
    # Lender table. Specialist lenders (home equity, manufactured housing) deny
    # far more often because of what they lend, so the state rate rides along
    # for a reference line and the dashboard says so in its caption.
    "lenders": """
        with state as (
            select activity_year, round(100.0 * avg(is_denied::int), 2) as state_denial_rate_pct
            from stg_lar where is_decisioned group by 1
        )
        select m.activity_year as year, lender_name as lender, lender_lei,
               decisioned_applications, originations, denials, denial_rate_pct,
               state_denial_rate_pct, originated_volume_musd, median_interest_rate
        from mart_lender_summary m join state using (activity_year)
        order by year, decisioned_applications desc
    """,
    "denial_reasons": """
        select activity_year as year, applicant_race as race, denial_reason, denials, pct_of_denials
        from mart_denial_reasons
        order by year, race, denials desc
    """,
}


def main():
    OUT.mkdir(exist_ok=True)
    con = duckdb.connect("hmda.duckdb", read_only=True)
    frames = {}
    for name, sql in TABLES.items():
        df = con.sql(sql).df()
        df.to_csv(OUT / f"{name}.csv", index=False)
        frames[name] = df
        print(f"{name:15} {len(df):>5} rows")
    with __import__("pandas").ExcelWriter(OUT / "hmda_ohio.xlsx") as xl:
        for name, df in frames.items():
            df.to_excel(xl, sheet_name=name, index=False)


if __name__ == "__main__":
    main()
