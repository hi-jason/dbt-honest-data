-- An empty relation is invalid if the contract explicitly requires rows.
select cast(null as varchar) as job_id,
       cast(null as timestamp) as posted_at
where 1=0
