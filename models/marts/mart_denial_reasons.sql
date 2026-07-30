-- Why applications were denied — primary reason only, by year and race.
-- Reported denial reasons are optional for some filers, so nulls are expected
-- and kept visible rather than quietly dropped.

select
    activity_year,
    applicant_race,
    coalesce(denial_reason, 'Not reported')             as denial_reason,
    count(*)                                            as denials,
    round(100.0 * count(*) / sum(count(*)) over (partition by activity_year, applicant_race), 2)
                                                        as pct_of_denials
from {{ ref('stg_lar') }}
where is_denied
group by 1, 2, 3
order by 1 desc, 2, denials desc
