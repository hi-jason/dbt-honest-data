-- Missing pay with an empty non-NULL reason is still unexplained.
select cast('listing-2' as varchar) as job_key,
       cast(null as integer) as pay_min,
       cast('' as varchar) as pay_absent_reason
