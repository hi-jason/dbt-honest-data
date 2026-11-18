-- Two rows with no identity cannot certify uniqueness. They group together
-- under a null identity, and must be labelled as missing an identity, not
-- as two rows sharing one.
select cast('key-a' as varchar) as listing_key,
       cast(null as varchar) as external_id
union all
select cast('key-b' as varchar), cast(null as varchar)
