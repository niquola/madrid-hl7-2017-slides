-- more complicated search - quanities

CREATE TABLE IF NOT EXISTS observation (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Encounter',
  status text not null,
  resource jsonb not null
)
;

\set obs `curl http://test.fhir.org/r3/Observation/?_format=json\&_count=10000` 

TRUNCATE observation;

INSERT INTO observation (id, txid, status, resource)
SELECT e#>>'{resource,id}', 8, 'imported', e->'resource'
FROM jsonb_array_elements((:'obs'::jsonb)->'entry') e
;

SELECT resource->'valueQuantity'
FROM observation
LIMIT 10
;

-- if not collection
SELECT
  id,
  resource#>'{subject,reference}',
  resource->'valueQuantity'
FROM observation
WHERE
  resource#>>'{valueQuantity,unit}' = 'mg/dL'
AND
  (resource#>>'{valueQuantity,value}')::numeric >= 10
LIMIT 10
;

-- https://github.com/postgrespro/jsquery

DROP EXTENSION IF EXISTS jsquery;

CREATE EXTENSION IF NOT EXISTS jsquery;


SELECT resource->'valueQuantity'
FROM observation
WHERE
 resource @@ 'valueQuantity(unit = "mg/dL" and value >= 10)'
LIMIT 10
;

-- search in components
SELECT
  id,
  resource#>'{subject,reference}',
  knife_extract(resource, '[["component", "code", "coding","code"]]'),
  knife_extract(resource, '[["component", "valueQuantity", "value"]]')
FROM observation
WHERE
  knife_extract(resource, '[["component", "valueQuantity", "value"]]') is not null
  AND 
  resource @@ 'component.#(
    code.coding.#.code = "8480-6"
    and valueQuantity.value > 107
  )'
LIMIT 100
;
