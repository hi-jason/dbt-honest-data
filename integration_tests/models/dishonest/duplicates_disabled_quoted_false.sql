-- Quoted false must NOT enable duplicates.
select * from (values (cast('a' as varchar)),('a'),('b')) as t(record_id)
