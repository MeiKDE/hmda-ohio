-- Origination volume and denial rate by county and year, for the map.

select
    activity_year,
    county_code,
    count(*)                                            as decisioned_applications,
    count(*) filter (where is_originated)               as originations,
    round(100.0 * count(*) filter (where is_denied) / count(*), 2) as denial_rate_pct,
    round(sum(loan_amount) filter (where is_originated) / 1e6) as originated_volume_musd,
    round(median(property_value))                       as median_property_value
from {{ ref('stg_lar') }}
where is_decisioned and county_code is not null
group by 1, 2
having count(*) >= 100
order by 1 desc, originations desc
