-- Even when two tables are present, every explicitly required table
-- must be found, and scanning the rest of the schema remains allowed.
{{ honest_data.column_name_denylist(
     schema=target.schema,
     include_tables=['public_safe', 'listings_source'],
     patterns=['%synthetic_forbidden_column_that_does_not_exist%']) }}
