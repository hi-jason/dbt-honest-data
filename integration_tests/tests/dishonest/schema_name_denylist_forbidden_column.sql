-- Expected to FAIL: public_leaky exists and contains a denied column name.
-- It must fail because that column is found, not because the table is
-- missing (a missing required table also fails this check).
{{ honest_data.column_name_denylist(
     schema=target.schema,
     required_tables=['public_leaky'],
     patterns=['%internal_note%']) }}
