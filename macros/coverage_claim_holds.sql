{#-
    coverage_claim_holds
    ====================

    Some provenance values are not statements about the row they sit on.
    They describe the pipeline's coverage capabilities.

    "not_disclosed" is a fact about one posting: that employer did not
    publish a range. "no_parser_for_source" is a fact about the pipeline:
    it cannot read pay from this source at all. The second one is a claim
    with a scope -- it is asserted per row but it is only true or false
    per SOURCE. So it is falsifiable in a way per-row provenance is not:
    if any single row from that source ever yields a real value, the
    claim is wrong on every other row from that source, simultaneously.

    This is particularly important when a source parser is added. Some rows
    may begin carrying values while others retain an outdated claim that
    the source cannot be parsed. The test detects that inconsistency.

    The general shape: a provenance value that means "we structurally
    cannot do X for this scope" must not coexist with evidence that X was
    done for that scope.

    Args
    ----
    claim_value        (required) the provenance value that makes a
                       coverage claim, e.g. 'no_parser_for_source'.
    scope_column       (required) what the claim is scoped to, e.g.
                       'source'. The claim is true or false per distinct
                       value of this column, never per row.
    Null claimed scopes are invalid: a structural coverage claim cannot
    be evaluated if the record does not identify its claimed scope.
    value_column       (required) the column whose presence falsifies the
                       claim.
    evidence_relation  optional; where to look for falsifying evidence,
                       if it does not live on this model. Pass a rendered
                       ref, e.g. "{{ ref('fct_pay_observations') }}".
                       Defaults to the model under test.

    Usage
    -----
    models:
      - name: dim_jobs
        columns:
          - name: pay_absent_reason
            data_tests:
              - honest_data.coverage_claim_holds:
                  arguments:
                    claim_value: no_parser_for_source
                    scope_column: source
                    value_column: pay_min

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test coverage_claim_holds(model, column_name, claim_value, scope_column,
                             value_column, evidence_relation=none) %}

    {%- set evidence = evidence_relation if evidence_relation else model -%}

    select distinct
        cast(claimed.{{ scope_column }} as varchar) as failing_scope,
        {{ honest_data.sql_literal(claim_value) }} as claim,
        case
            when claimed.{{ scope_column }} is null
                then 'coverage claim has no scope'
            else 'a row in this scope carries a value, contradicting the claim'
        end as failure
    from {{ model }} as claimed
    where claimed.{{ column_name }} = {{ honest_data.sql_literal(claim_value) }}
      and (
          claimed.{{ scope_column }} is null
          or exists (
              select 1
              from {{ evidence }} as witness
              where witness.{{ scope_column }} = claimed.{{ scope_column }}
                and witness.{{ value_column }} is not null
          )
      )

{% endtest %}
