-- Valid numeric columns can encode an invalid business fact.
select cast(701 as integer) as order_id,
       cast(100.00 as numeric(12,2)) as gross_amount,
       cast(10.00 as numeric(12,2)) as discount_amount,
       cast(95.00 as numeric(12,2)) as net_amount
