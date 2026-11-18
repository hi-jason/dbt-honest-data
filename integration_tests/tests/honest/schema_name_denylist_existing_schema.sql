-- Synthetic integration only. A live schema must contain some columns.
-- All forbidden patterns below are fictional and match no fixture column.
{{ honest_data.column_name_denylist(
     schema=target.schema,
     patterns=['%synthetic_nonexistent_column_marker_5832%']) }}
