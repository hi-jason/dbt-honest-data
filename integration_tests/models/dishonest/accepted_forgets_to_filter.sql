-- The accepted side forgot to exclude what the quarantine holds (c is in
-- both), and its key filter dropped a row that is in neither (a).
select listing_id from {{ ref('source_badly_split') }} where listing_id in ('b', 'c', 'd')
