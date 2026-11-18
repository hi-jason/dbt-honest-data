-- A JSON-typed payload is explicitly serialized for inspection.
select cast('{"text":"a fictional, safe reference"}' as json) as payload
