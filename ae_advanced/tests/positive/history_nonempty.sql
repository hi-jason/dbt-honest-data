select cast(1 as integer) as missing_history
where not exists (select 1 from {{ ref('history_good') }})
