{#-
    one_row_per_identity
    ====================

    No more than one row may represent the same exact business identity.

    `unique` on the key column passes while the same entity sits in the
    table twice, because the two copies have different keys: one arrived
    from a feed and one was entered by hand; one came through an
    aggregator and one from the origin; a re-keyed record kept its old
    row. The duplicate then costs more than a count: the entity is
    scored twice, shown twice, and any "missing value" report shows an
    incomplete copy beside a more complete record. That last symptom
    is how the original defect was found -- a field reported missing on a
    row whose twin had it.

    Define the identity using a defensible exact key or stable normalized
    identifier (for example, a canonical source URL). The test fails
    when multiple rows share that exact identity.

    Use this test only with an exact identity. Probabilistic name/title
    matches should be modeled separately with confidence information.

    Args
    ----
    identity      (required) SQL expression for "the same real thing".
    key_column    optional; the two keys are echoed so a failure names
                  the pair.
    row_filter    optional SQL boolean limiting the rows.
    null_identity_is_failure  true by default. An unidentifiable singleton
                  cannot certify uniqueness; disable only if null or
                  blank identities are explicitly allowed. With this
                  opt-out, unknown/blank identities are EXCLUDED from
                  uniqueness checks, including when multiple such rows
                  exist: they cannot be asserted equal to each other.

    Usage
    -----
    models:
      - name: dim_listings
        data_tests:
          - honest_data.one_row_per_identity:
              arguments:
                identity: "split_part(listing_key, ':', 3)"
                key_column: listing_key
                row_filter: "not is_closed"

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test one_row_per_identity(model, identity, key_column=none, row_filter=none, null_identity_is_failure=true) %}

    {%- set key_expr = key_column if key_column else 'null' -%}
    {%- set fail_missing_identity = honest_data.boolean_argument(null_identity_is_failure, 'one_row_per_identity.null_identity_is_failure') -%}

    with identities as (
        select
            cast({{ identity }} as varchar) as shared_identity,
            cast({{ key_expr }} as varchar) as entity_key
        from {{ model }}
        {% if row_filter %}where {{ row_filter }}{% endif %}
    ), grouped as (
        select
            shared_identity,
            count(*) as rows_sharing_it,
            min(entity_key) as one_key,
            max(entity_key) as another_key
        from identities
        group by 1
    )
    select
        case
            -- Check the missing identity first: several rows without an
            -- identity group together, and are not one shared identity.
            when shared_identity is null or trim(shared_identity) = ''
                then 'row has no usable exact identity'
            else 'more than one row for the same identity'
        end as failure,
        shared_identity,
        rows_sharing_it,
        one_key,
        another_key
    from grouped
    where (rows_sharing_it > 1
           and shared_identity is not null
           and trim(shared_identity) <> '')
       {% if fail_missing_identity %}
       or shared_identity is null
       or trim(shared_identity) = ''
       {% endif %}

{% endtest %}
