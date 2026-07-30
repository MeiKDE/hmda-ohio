-- Denial rate by applicant race and year — the headline fair-lending cut.
--
-- Denominator is decisioned applications only (see stg_lar). "Race Not
-- Available" is kept as its own row rather than dropped: it is ~22% of the
-- file, and hiding it would overstate how complete the demographic picture is.

select
    activity_year,
    applicant_race,
    count(*)                                            as decisioned_applications,
    count(*) filter (where is_denied)                   as denials,
    count(*) filter (where is_originated)               as originations,
    round(100.0 * count(*) filter (where is_denied) / count(*), 2) as denial_rate_pct,
    round(median(income_thousands))                     as median_income_thousands,
    round(median(loan_amount))                          as median_loan_amount
from {{ ref('stg_lar') }}
where is_decisioned
group by 1, 2
order by 1 desc, decisioned_applications desc
