-- Grain, key uniqueness and null checks may pass on ZERO observations.
select cast(null as integer) as order_id where 1=0
