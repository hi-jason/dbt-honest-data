-- No group big enough; fail_when_nothing_graded='false' is OFF.
select cast('small' as varchar) as source,
       cast(true as boolean) as is_held
