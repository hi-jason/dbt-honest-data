-- Empty model must not fail if fail_on_empty is quoted 'false'.
select cast(null as varchar) as record_id,
       cast(null as date) as observed_at where 1=0
