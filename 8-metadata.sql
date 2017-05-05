-- metadata for search

DROP TABLE searchparameter;

CREATE TABLE IF NOT EXISTS searchparameter (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Encounter',
  status text not null,
  resource jsonb not null
)
;

\set sps `curl http://build.fhir.org/search-parameters.json`

TRUNCATE searchparameter;

INSERT INTO searchparameter (id, txid, status, resource)
SELECT e#>>'{resource,id}', 6, 'imported', e->'resource'
FROM jsonb_array_elements((:'sps'::jsonb)->'entry') e
;


select
  -- resource->'base',
  resource->'name' as "name",
  resource->'type' as "search type",
  resource->'expression' as "expr"
from searchparameter
where
  knife_extract_text(resource, '[["base"]]') && ARRAY['Patient']
  AND resource->>'name' = 'name'
limit 10
;


-- metadata for search

DROP TABLE structuredef;

CREATE TABLE IF NOT EXISTS structuredef (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Encounter',
  status text not null,
  resource jsonb not null
)
;

\set sds `curl http://build.fhir.org/profiles-resources.json`

TRUNCATE structuredef;

INSERT INTO structuredef (id, txid, status, resource)
SELECT e#>>'{resource,id}', 6, 'imported', e->'resource'
FROM jsonb_array_elements((:'sds'::jsonb)->'entry') e
;

CREATE TABLE IF NOT EXISTS elements (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Encounter',
  status text not null,
  resource jsonb not null
)
;

TRUNCATE elements;

INSERT INTO elements (id, txid, status, resource)
SELECT e.el->>'id', 6, 'imported', e.el
FROM (
  SELECT
    jsonb_array_elements(resource#>'{snapshot,element}') as el
  from structuredef
  where resource->>'resourceType' = 'StructureDefinition'
) e
;

select count(*)
from elements;

select id
  -- , resource->'max'
  -- , resource->'min'
  , knife_extract_text(resource, '[["type", "code"]]')
from elements
where id ilike 'Patient%'
order by id
limit 100
;
