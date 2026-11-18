select listing_id from {{ ref('source_badly_split') }} where listing_id = 'c'
