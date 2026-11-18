-- Two sources, each with a held share inside the declared band
-- (feed 1 of 5 = 0.2, partner 1 of 4 = 0.25; band 0.1 to 0.5).
select * from (
    values
        (cast('feed' as varchar), cast(true as boolean)),
        ('feed', false), ('feed', false), ('feed', false), ('feed', false),
        ('partner', true), ('partner', false), ('partner', false), ('partner', false)
) as t(source, is_held)
