-- Two groups, neither big enough to grade. Alarm must not go quiet.
select * from (values
    (cast('source_a' as varchar), cast(true as boolean)),
    ('source_b', false)
) as t(source, is_held)
