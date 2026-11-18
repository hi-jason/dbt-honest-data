-- Synthetic text with no matches for the configured canary patterns.
select * from (
    values
        (cast('a' as varchar), cast('Remote-friendly; two openings' as varchar),
         cast('https://example.com/jobs/1?id=77' as varchar)),
        ('b', 'Posting names two locations', 'https://example.com/jobs/2')
) as t(listing_id, note, url)
