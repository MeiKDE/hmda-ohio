-- Denial rate by applicant income band, split by race.
--
-- The point of this cut: a raw denial gap can often be explained by income mix.
-- Holding income roughly constant is the first honest check on whether it is.

with banded as (

    select
        *,
        case
            when income_thousands is null   then 'Not reported'
            when income_thousands <  50     then '< $50k'
            when income_thousands < 100     then '$50–100k'
            when income_thousands < 150     then '$100–150k'
            when income_thousands < 250     then '$150–250k'
            else '$250k+'
        end as income_band
    from {{ ref('stg_lar') }}
    where is_decisioned

)

select
    activity_year,
    income_band,
    applicant_race,
    count(*)                                            as decisioned_applications,
    count(*) filter (where is_denied)                   as denials,
    round(100.0 * count(*) filter (where is_denied) / count(*), 2) as denial_rate_pct
from banded
group by 1, 2, 3
having count(*) >= 100          -- suppress cells too small to read anything into
order by 1 desc, 2, decisioned_applications desc
