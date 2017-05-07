/*
## jsonb type

postgresql has jsonb data type
it's a binary json (no just set of functions on top of string)
, i.e. access json doc field is effective almost like accessing
tabl columns


*/

-- here is how we cast string litteral to jsonb

SELECT '{"a":1}'::jsonb;

-- jsonb   
-- ----------
-- {"a": 1}
-- (1 row)

-- we could access field using -> operator

SELECT ('{"a":{"b":[1,2]}}'::jsonb)->'a';

-- ?column?    
-- ---------------
-- {"b": [1, 2]}
-- (1 row)

-- we access deeply nested
-- fileds by path using #> operator

SELECT ('{"a":{"b":[1,2]}}'::jsonb)#>'{a,b,1}';

-- ?column? 
-- ----------
-- 1
-- (1 row)

-- we could unnest json array into relation
-- to apply 

SELECT jsonb_array_elements(doc#>'{a,b}')
 FROM ( SELECT '{"a":{"b":[{"d": 1},{"e": 2}]}}'::jsonb doc) _;

-- here is how we could simumate
-- document database

CREATE TABLE IF NOT EXISTS document (
  id serial primary key,
  doc jsonb
);

TRUNCATE document;

INSERT INTO document (doc)
VALUES ('{"a":2, "b": 1}');

INSERT INTO document (doc)
VALUES ('{"a":1, "b": 2}');

SELECT doc, doc->'a'
FROM document;

-- doc    | ?column? 
-- ----------+----------
-- {"a": 2} | 2
-- (1 rows)

SELECT doc
FROM document
WHERE (doc->>'a')::numeric = 1
;

SELECT d1.doc as d1, d2.doc as d2
FROM document d1, document d2
WHERE
  d1.doc->>'a' = d2.doc->>'b'
;


-- More about jsonb type and functions

-- * https://www.postgresql.org/docs/9.6/static/functions-json.html 
-- * https://www.postgresql.org/docs/9.6/static/datatype-json.html

