-- Scan the full schema, but require an explicitly named export table.
-- A nonempty schema is not evidence that the required export exists.
{{ honest_data.column_name_denylist(
     schema=target.schema,
     required_tables=['synthetic_missing_export_9821'],
     patterns=['%synthetic_forbidden_column_that_does_not_exist%']) }}
