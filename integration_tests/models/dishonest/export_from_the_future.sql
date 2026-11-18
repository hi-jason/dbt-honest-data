-- One export has a date far in the future. This can distort checks that
-- compare other records with max(export_date).
select * from (
    values
        (cast('e1' as varchar), cast(date '2026-08-01' as date)),
        ('e2', date '2999-01-01')
) as t(export_id, export_date)
