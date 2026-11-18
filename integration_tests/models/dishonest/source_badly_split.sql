-- The input of a broken split. Self-contained on purpose: a dishonest
-- fixture that ref()s an honest model gets its failing test selected by
-- the honest run (dbt selects a test when any parent matches the path).
select * from (
    values
        (cast('a' as varchar), cast('feed' as varchar)),
        ('b', 'feed'),
        ('c', 'feed'),
        ('d', 'partner')
) as t(listing_id, source)
