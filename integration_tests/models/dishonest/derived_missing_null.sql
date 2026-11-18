-- A source null key must not be silently discarded.
select cast(null as varchar) as listing_id where 1 = 0
