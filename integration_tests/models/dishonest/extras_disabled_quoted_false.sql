-- Quoted false must NOT authorize an invented derived key.
select * from (values (cast('a' as varchar)),('z')) as t(record_id)
