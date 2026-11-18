-- A synthetic marker inside a JSON-typed column; no real private data.
select cast('{"note":"fictional CANARY-DEMO-IN-JSON"}' as json) as payload
