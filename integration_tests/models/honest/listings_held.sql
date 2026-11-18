-- The other side: the one listing the quarantine holds.
select listing_id from {{ ref('listings_source') }} where listing_id = 'd'
