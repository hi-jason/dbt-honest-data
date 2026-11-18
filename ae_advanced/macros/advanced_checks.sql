{# Reusable synthetic examples. Caller owns grain, null policy and source quality. #}
{% macro history_no_overlaps(relation) %}
with bad_intervals as (
  select account_id, version_id from {{ relation }}
  where account_id is null or version_id is null or valid_from is null
     or (valid_to is not null and valid_to <= valid_from)
),
overlap_pairs as (
  select a.account_id, a.version_id
  from {{ relation }} a
  join {{ relation }} b
    on a.account_id = b.account_id
   and a.version_id < b.version_id
   and a.valid_from < coalesce(b.valid_to, cast('9999-12-31' as timestamp))
   and b.valid_from < coalesce(a.valid_to, cast('9999-12-31' as timestamp))
)
select account_id, version_id from bad_intervals
union all select account_id, version_id from overlap_pairs
{% endmacro %}

{% macro history_one_current(relation) %}
select account_id
from {{ relation }}
group by account_id
having sum(case when valid_to is null then 1 else 0 end) <> 1
{% endmacro %}

{% macro revenue_by_key(source_relation, target_relation) %}
with source_key as (
  select order_id, count(*) as n, sum(net_amount) as amount
  from {{ source_relation }} group by order_id
),
target_key as (
  select order_id, count(*) as n, sum(net_amount) as amount
  from {{ target_relation }} group by order_id
)
select coalesce(s.order_id,t.order_id) as order_id
from source_key s full outer join target_key t on s.order_id=t.order_id
where s.order_id is null or t.order_id is null
   or s.n <> 1 or t.n <> 1
   or s.amount is distinct from t.amount
{% endmacro %}

{% macro revenue_total(source_relation, target_relation) %}
select cast(1 as integer) as total_mismatch
where (select count(*) from {{ source_relation }}) = 0
   or (select count(*) from {{ target_relation }}) = 0
   or (select sum(net_amount) from {{ source_relation }})
      is distinct from (select sum(net_amount) from {{ target_relation }})
{% endmacro %}


{# Separate version-key contract: interval self-joins assume version IDs are unique. #}
{% macro history_unique_versions(relation) %}
select account_id, version_id
from {{ relation }}
group by account_id, version_id
having count(*) > 1
{% endmacro %}
