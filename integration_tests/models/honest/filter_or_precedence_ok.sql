-- An unparenthesized OR in row_filter must not bypass the date predicate.
-- Both included dates are historic; the far-future row is excluded.
select * from (
    values
        (cast('historic_a' as varchar), cast('primary' as varchar), cast(date '2020-01-01' as date)),
        ('historic_b', 'secondary', date '2021-05-01'),
        ('excluded_future', 'excluded', date '2999-01-01')
) as t(record_id, scope, observed_on)
