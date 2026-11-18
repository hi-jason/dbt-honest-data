-- feed holds 4 of 5 (0.8, above the 0.5 ceiling: a rule firing on
-- everything); partner holds 0 of 4 (below the 0.1 floor: a rule that
-- stopped firing). One pooled share would be 4 of 9 = 0.44, inside the band.
select * from (
    values
        (cast('feed' as varchar), cast(true as boolean)),
        ('feed', true), ('feed', true), ('feed', true), ('feed', false),
        ('partner', false), ('partner', false), ('partner', false), ('partner', false)
) as t(source, is_held)
