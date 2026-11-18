-- Whitespace-only identity is not a usable exact identifier.
select cast('key-b' as varchar) as listing_key,
       cast('  ' as varchar) as external_id
