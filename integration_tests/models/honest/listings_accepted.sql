-- One side of a clean split: everything the quarantine does not hold.
select listing_id from {{ ref('listings_source') }} where listing_id <> 'd'
