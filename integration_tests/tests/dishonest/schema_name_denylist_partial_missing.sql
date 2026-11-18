-- A partial include filter used to silently accept the one surviving
-- table while failing to inspect the other named object.
{{ honest_data.column_name_denylist(
     schema=target.schema,
     include_tables=['public_safe', 'synthetic_missing_table_9821'],
     patterns=['%synthetic_forbidden_column_that_does_not_exist%']) }}
