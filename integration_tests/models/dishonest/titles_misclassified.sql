-- One pinned case has moved ("Head of Data" is no longer leadership) and
-- one pinned row is gone from the model entirely ("Data Analyst"), which
-- an inner-join known-case test would pass on without checking it.
select * from (
    values
        (cast('Head of Data' as varchar), cast('analyst' as varchar)),
        ('Staff Engineer', 'engineering')
) as t(title, role_family)
