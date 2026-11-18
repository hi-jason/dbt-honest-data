-- Exactly one future timestamp belongs to the selected OR filter.
select * from (
    values
        (cast('historic_a' as varchar), cast('primary' as varchar), cast(date '2020-01-01' as date)),
        ('future_b', 'secondary', date '2999-01-01'),
        ('excluded_future', 'excluded', date '2999-01-01')
) as t(record_id, scope, observed_on)
