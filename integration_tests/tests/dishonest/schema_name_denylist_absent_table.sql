-- Even a real schema is not sufficient when an inclusion filter
-- accidentally selects an absent table.
{{ honest_data.column_name_denylist(
     schema=target.schema,
     include_tables=['synthetic_table_that_does_not_exist_5832'],
     patterns=['%personal_columns%']) }}
