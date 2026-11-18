-- Explicit quoted false permits one nullable exact identity.
select cast('a' as varchar) as record_id,
       cast(null as varchar) as external_id
