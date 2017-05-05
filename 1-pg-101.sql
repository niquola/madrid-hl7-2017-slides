-- https://www.postgresql.org/docs/9.6/static/functions-json.html 

-- jsonb type
SELECT '{"a":1}'::jsonb;

-- access field
SELECT ('{"a":{"b":[1,2]}}'::jsonb)->'a';

-- access by path
SELECT ('{"a":{"b":[1,2]}}'::jsonb)#>'{a,b,0}';

-- unnest array
SELECT jsonb_array_elements(doc#>'{a,b}')
 FROM ( SELECT '{"a":{"b":[{"d": 1},{"e": 2}]}}'::jsonb doc) _;

CREATE TABLE document (
  id serial primary key,
  doc jsonb
);

INSERT INTO document (doc) VALUES ('{"a":1}');

SELECT doc, doc->'a' FROM document;
