-- One clean row per HMDA loan application record.
--
-- The raw extract lands as all-varchar on purpose: HMDA uses "NA" and "Exempt"
-- as in-band sentinels in otherwise numeric columns, so letting a CSV reader
-- infer types either fails or silently coerces those to NULL without anyone
-- deciding to. Casting happens here, once, where it can be read and argued with.

with source as (

    select * from {{ source('raw', 'lar') }}

),

typed as (

    select
        activity_year::int                                  as activity_year,
        lei                                                 as lender_lei,
        nullif(county_code, 'NA')                           as county_code,
        nullif(census_tract, 'NA')                          as census_tract,
        nullif("derived_msa-md", 'NA')                      as msa_md,

        action_taken::int                                   as action_taken_code,
        loan_purpose::int                                   as loan_purpose_code,
        loan_type::int                                      as loan_type_code,
        occupancy_type::int                                 as occupancy_type_code,

        derived_race                                        as applicant_race,
        derived_ethnicity                                   as applicant_ethnicity,
        derived_sex                                         as applicant_sex,
        derived_loan_product_type                           as loan_product_type,
        derived_dwelling_category                           as dwelling_category,

        -- "NA"/"Exempt" -> NULL, then cast. try_cast keeps a stray unparseable
        -- value from failing the whole build; the schema tests catch volume.
        try_cast(nullif(nullif(loan_amount, 'NA'), 'Exempt') as double)           as loan_amount,
        try_cast(nullif(nullif(income, 'NA'), 'Exempt') as double)               as income_thousands,
        try_cast(nullif(nullif(property_value, 'NA'), 'Exempt') as double)       as property_value,
        try_cast(nullif(nullif(interest_rate, 'NA'), 'Exempt') as double)        as interest_rate,
        try_cast(nullif(nullif(loan_to_value_ratio, 'NA'), 'Exempt') as double)  as loan_to_value_ratio,

        nullif(nullif(debt_to_income_ratio, 'NA'), 'Exempt')                     as debt_to_income_band,
        nullif(nullif("denial_reason-1", 'NA'), '10')                            as denial_reason_code

    from source

),

labelled as (

    select
        *,

        case action_taken_code
            when 1 then 'Originated'
            when 2 then 'Approved, not accepted'
            when 3 then 'Denied'
            when 4 then 'Withdrawn by applicant'
            when 5 then 'Closed for incompleteness'
            when 6 then 'Purchased loan'
            when 7 then 'Preapproval denied'
            when 8 then 'Preapproval approved, not accepted'
        end as action_taken,

        case loan_purpose_code
            when 1  then 'Home purchase'
            when 2  then 'Home improvement'
            when 31 then 'Refinancing'
            when 32 then 'Cash-out refinancing'
            when 4  then 'Other'
            when 5  then 'Not applicable'
        end as loan_purpose,

        case loan_type_code
            when 1 then 'Conventional'
            when 2 then 'FHA'
            when 3 then 'VA'
            when 4 then 'USDA / RHS'
        end as loan_type,

        case denial_reason_code
            when '1' then 'Debt-to-income ratio'
            when '2' then 'Employment history'
            when '3' then 'Credit history'
            when '4' then 'Collateral'
            when '5' then 'Insufficient cash'
            when '6' then 'Unverifiable information'
            when '7' then 'Credit application incomplete'
            when '8' then 'Mortgage insurance denied'
            when '9' then 'Other'
        end as denial_reason,

        -- A "decisioned" application is one the lender actually ruled on.
        -- Withdrawals, incomplete files and purchased loans are excluded: a
        -- withdrawal is the applicant's decision, and a purchased loan was
        -- decisioned by some other institution in some other year. Including
        -- them is the most common way a HMDA denial rate comes out wrong.
        action_taken_code in (1, 2, 3) as is_decisioned,
        action_taken_code = 3          as is_denied,
        action_taken_code = 1          as is_originated

    from typed

)

select * from labelled
