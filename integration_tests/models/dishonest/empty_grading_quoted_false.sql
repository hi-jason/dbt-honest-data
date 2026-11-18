-- Empty model must fail when only_when_model_has_rows is string 'false'.
select cast(null as varchar) as record_id,
       cast(null as date) as observed_at where 1=0
