-- Every column NAME here is innocent. The leak is in the values: a
-- canary token in a note, and a tracking parameter in a URL.
select * from (
    values
        (cast('a' as varchar), cast('reviewed; ref CANARY-7f3a' as varchar),
         cast('https://example.com/jobs/1?utm_source=newsletter' as varchar))
) as t(listing_id, note, url)
