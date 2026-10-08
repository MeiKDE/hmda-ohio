-- Per-lender activity and denial rate, Ohio.
--
-- Restricted to lenders with enough volume for the rate to mean anything.

select
    l.activity_year,
    l.lender_lei,
    n.lender_name,
    count(*)                                            as decisioned_applications,
    count(*) filter (where is_originated)               as originations,
    count(*) filter (where is_denied)                   as denials,
    round(100.0 * count(*) filter (where is_denied) / count(*), 2) as denial_rate_pct,
    round(sum(loan_amount) filter (where is_originated) / 1e6) as originated_volume_musd,
    round(median(interest_rate), 3)                     as median_interest_rate
from {{ ref('stg_lar') }} l
left join {{ ref('lenders') }} n using (lender_lei)
where l.is_decisioned
group by 1, 2, 3
having count(*) >= 250
order by 1 desc, decisioned_applications desc
