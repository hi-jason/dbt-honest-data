-- This fixture's source has one row per listing_id, so the SELECT preserves
-- that grain. It does not deduplicate a source containing repeated snapshots.
select listing_id, source, upper(listing_id) as external_id
from {{ ref('listings_source') }}
