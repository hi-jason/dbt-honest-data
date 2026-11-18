-- Intentional blind-spot demonstration: totals match despite wrong identities.
{{ revenue_total(ref('ledger_source'), ref('mart_bad_offsets')) }}
