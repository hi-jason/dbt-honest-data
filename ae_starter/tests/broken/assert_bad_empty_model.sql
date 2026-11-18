{{ config(tags=['ae_starter_negative']) }}
-- This MUST return a failure row: otherwise empty models pass quality gates.
select cast(1 as integer) as missing_population
where not exists (select 1 from {{ ref('bad_empty_model') }})
