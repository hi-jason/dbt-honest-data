-- An absent schema used to pass a privacy denylist without scanning a thing.
{{ honest_data.column_name_denylist(
     schema='synthetic_schema_that_does_not_exist_5832',
     patterns=['%personal_columns%']) }}
