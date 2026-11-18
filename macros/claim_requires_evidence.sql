{#-
    claim_requires_evidence
    =======================

    A row that claims something must carry the evidence for it, and a row
    that carries the evidence must make the claim. Both halves fail
    visibly; both halves are real defects.

    The failure this was built from is the empty redline. A diff feature
    labelled a posting "changed", the reader clicked through, and the
    panel rendered nothing -- because the change_class said material
    while the changed_dimensions list was empty. A claim without evidence
    misrepresents the change. Correcting the display alone cannot resolve
    the underlying inconsistency.

    The reverse case is also important. Evidence with no claim
    -- a populated pay_before/pay_after pair on a row whose dimension
    list never mentions pay -- is silently dropped by every consumer that
    filters on the claim. Nothing errors. The change simply never
    surfaces.

    Both directions come from one idea: a claim column and its evidence
    columns are two representations of the same fact. They must agree.

    Args
    ----
    claim         (required) SQL boolean expression. The assertion.
    evidence      (required) SQL boolean expression. What must be true
                  for the assertion to be supportable.
    relationship  'iff' (default) -- claim and evidence must agree in
                  both directions.
                  'implies' -- a claim requires its evidence, but the
                  evidence may exist without the claim. Use this only
                  where the looser direction is genuinely meaningful,
                  and say why in a comment.
    key_column    optional; echoed into failure rows.

    Both expressions are coalesced to false before comparison, so a NULL
    on either side reads as "not claimed" / "no evidence" rather than
    quietly passing the way a three-valued comparison would.

    Usage
    -----
    models:
      - name: int_job_content_changes
        data_tests:
          - honest_data.claim_requires_evidence:
              arguments:
                claim: "change_class = 'material'"
                evidence: "changed_dimensions is not null and changed_dimensions <> ''"
                key_column: job_key
          - honest_data.claim_requires_evidence:
              arguments:
                claim: "changed_dimensions like '%pay%'"
                evidence: "pay_before is not null"
                key_column: job_key

    Proof: integration_tests/README.md lists the fixtures this check must
    pass on and the planted errors it must fail on.
-#}

{% test claim_requires_evidence(model, claim, evidence,
                                relationship='iff', key_column=none) %}

    {%- if relationship not in ['iff', 'implies'] -%}
        {{ exceptions.raise_compiler_error(
            "honest_data.claim_requires_evidence: relationship must be 'iff' "
            ~ "or 'implies', got '" ~ relationship ~ "'") }}
    {%- endif -%}

    {%- set key_expr = key_column if key_column else 'null' -%}
    {%- set claim_bool = 'coalesce((' ~ claim ~ '), false)' -%}
    {%- set evidence_bool = 'coalesce((' ~ evidence ~ '), false)' -%}

    select
        cast({{ key_expr }} as varchar) as failing_key,
        {{ honest_data.sql_literal(claim) }} as claim,
        {{ honest_data.sql_literal(evidence) }} as evidence,
        case
            when {{ claim_bool }} then 'claimed, but the evidence is absent'
            else 'evidence present, but nothing claims it'
        end as failure
    from {{ model }}
    {% if relationship == 'iff' %}
    where {{ claim_bool }} <> {{ evidence_bool }}
    {% else %}
    where {{ claim_bool }} and not {{ evidence_bool }}
    {% endif %}

{% endtest %}
