-- A classifier's output, with the hand-checked cases in it.
select * from (
    values
        (cast('Data Analyst' as varchar), cast('analyst' as varchar)),
        ('Head of Data', 'leadership'),
        ('Data Center Technician', cast(null as varchar)),
        ('Staff Engineer', 'engineering')
) as t(title, role_family)
