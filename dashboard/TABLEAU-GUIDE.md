# Tableau lesson: rebuild the Ohio mortgage dashboard from scratch

**Goal:** you can build this dashboard yourself, in your own browser, and explain each step out loud in an interview.
**Live reference:** https://public.tableau.com/app/profile/mei.data.analyst.zhang/viz/OhioMortgageDenials20222024/Dashboard1
**Tool:** Tableau Public **web authoring** (in the browser, no download). Interview tip: say "Tableau"; the concepts are identical in Tableau Desktop.
**Time:** about 90 minutes across 2 sessions. Do lessons 1–3 first; 4–6 the next day.

---

## Vocabulary to use in an interview (learn these 8)
| Word | Meaning | Where you'll see it |
|---|---|---|
| **Data source** | The file or table Tableau reads | Lesson 1 |
| **Dimension** (blue) | A category you slice by: race, county, year | Data pane, top |
| **Measure** (green) | A number you aggregate: denial rate, count | Data pane, bottom |
| **Shelf** | Where you drop fields: Columns, Rows, Filters | Every sheet |
| **Marks card** | Controls Color, Label, Tooltip, Size, mark type | Left of the chart |
| **Aggregation** | SUM / AVG / COUNT applied to a measure | Right-click a green pill |
| **Filter** | Limits which rows the chart uses | Filters shelf |
| **Dashboard** | A page that arranges several sheets together | Lesson 5 |

One-line pitch to memorise: *"Each sheet answers one question; the dashboard arranges them so the headline reads in 10 seconds, with caveats right under the title."*

---

## Lesson 1. Load the data (10 min)
Files are in `dashboard/`: `income_gap.csv`, `denial_reasons.csv`, `counties.csv`, `lenders.csv` (one row per year × group, already aggregated by the SQL pipeline).

1. Sign in at public.tableau.com → your profile → **Create → Web Authoring**.
2. **Upload from computer** → `income_gap.csv`.
3. Add the other three as **separate data sources**: menu **Data → New Data Source → Files → Upload** for each CSV.
   - **Don't drag them together into one source.** Relating 4 tables that share no clean key caused a "Data Source Error" on our first build. Separate sources = one per chart.
4. Check: the Data pane shows 4 sources. Click each and look at the field list.

**Say in interview:** "The data was pre-aggregated in SQL, so Tableau only does presentation. That keeps the numbers testable."

## Lesson 2. Sheet "Gap by income" (headline chart, 20 min)
1. Rename the sheet tab (double-click it) → `Gap by income`. Data source: `income_gap`.
2. Drag `income_band` → **Columns**; `denial_rate_pct` → **Rows**. Right-click the green pill → Measure → **Average**.
3. Sort the bands in order: right-click `income_band` → **Sort → By Field → band_order → Ascending**.
4. **Filters:**
   - Drag `race` → Filters → tick only *White* and *Black or African American*.
   - Drag `year` → Filters. It may treat year as a number: choose **All values → Range of values → 2024 to 2024**.
5. **Side-by-side bars by race:** open **Show Me** (top right) → **side-by-side bars**. Then drag `race` onto the colour pill on the Marks card.
   - *Gotcha:* dropping straight onto the Color tile sometimes doesn't register in the browser. Show Me first, then swap the pill.
6. Drag `denial_rate_pct` → **Label** so each bar shows its %.
7. Title (double-click the title): *Denial rate by income band, 2024: the gap holds at every level*.

**Check:** $250k+ → White 13.5%, Black 26.0%; < $50k → 38.4% vs 51.6%.

## Lesson 3. Sheet "Why denied" (15 min)
1. New sheet → `Why denied`, source `denial_reasons`.
2. `denial_reason` → **Rows**, `pct_of_denials` → **Columns** (Average).
3. Filters: year 2024 (range), race = White + Black; `denial_reason` = Credit history, Debt-to-income ratio, Collateral, Other.
4. Show Me → side-by-side bars → `race` on the colour pill. `pct_of_denials` on Label.
5. Title: *Credit history, not debt-to-income, is where they differ*.

**Check:** Credit history 38.0% (Black) vs 34.0% (White); DTI 27.6% vs 28.4%.

## Lesson 4. Sheet "Counties" — a map (15 min)
1. New sheet → `Counties`, source `counties`.
2. In the Data pane, click the type icon next to `county` → **Geographic Role → County**. Do the same for `state` → **State/Province**.
3. **Double-click** `county` → Tableau draws points. Show Me → **filled map**.
4. Drag `denial_rate_pct` onto **Color** (or onto the existing colour pill).
5. `year` → Filters → range 2024; right-click the filter → **Show Filter** so viewers can change year.
6. Tooltip: drag `originations` and `median_property_value` onto **Tooltip**.

**Check:** colours range roughly 16.6% to 36.7%.
**Say in interview:** "Geographic roles tell Tableau the field is a place, so it can look up the shapes itself."

## Lesson 5. Sheet "Lenders" + reference line (15 min)
1. New sheet → `Lenders`, source `lenders`.
2. `lender` → Rows, `denial_rate_pct` → Columns (Average).
3. Filters: year 2024; `decisioned_applications` → **At least 1,000** (72 lenders remain).
4. Sort: right-click `lender` → Sort → By Field → `decisioned_applications` → Descending.
5. **Reference line:** open the **Analytics** pane (tab beside Data) → drag **Reference Line** onto the chart → Value = `state_denial_rate_pct` (Average) → Label = custom "Ohio average".
6. Title, neutral: *Denial rate by lender vs. the Ohio average, 2024*. No judgment words.

**Check:** Ohio 23.5%; JPMorgan Chase 12.4%.

## Lesson 6. Dashboard + publish (20 min)
1. Click the **New Dashboard** icon (bottom). Size → **Automatic** (or 1200 × 900).
2. Drag sheets from the left list: Gap by income on top (wide); Why denied (left) and Counties (right) below; Lenders at the bottom.
3. Drag a **Text** object above the charts. Title: *Ohio mortgage denials, 2022–2024: income doesn't explain the gap*. Under it, smaller: *1.45M public HMDA applications, Ohio 2022–2024. Decided applications only. HMDA has no credit scores, so this can't show why the gap exists.*
4. Footer text: *Data: CFPB/FFIEC HMDA · Pipeline: github.com/MeiKDE/hmda-ohio*.
5. **File → Publish As** → name it (use a practice name so it doesn't overwrite the live one) → tick **Show sheets as tabs** → Publish. In web authoring, *publishing is saving*.

**Say in interview:** "I put the caveat under the title on purpose. The data can show a gap, not its cause, and the reader should know that before they look at the charts."

---

## Likely interview questions about this dashboard
- *Why a bar chart and not a pie?* Comparing values across many groups: bars put them on one shared axis.
- *How did you make sure the numbers were right?* The SQL pipeline has tests; I checked every chart against the README figures above.
- *What would you add next?* A year-over-year trend line, and a parameter to switch which race is compared.
- *Desktop or web?* I built it in Tableau Public's web editor; the shelves, Marks card and dashboards work the same in Desktop.

## If a number doesn't match
It's almost always a filter: check **year = 2024** and the **race** selection first, then the **aggregation** (AVG, not SUM).
