-- create tables 
-- to store resources

\timing

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS patient_history;

CREATE TABLE IF NOT EXISTS patient (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Patient',
  status text not null,
  resource jsonb not null
)
;


CREATE TABLE patient_history (
  id text,
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Patient',
  status text not null,
  resource jsonb not null,
  PRIMARY KEY (id, txid)
)
;

\d patient

TRUNCATE patient;

INSERT INTO patient (status, txid, resource) VALUES
('created', 1, '{"name":[{"given":["Nikolai"], "family": ["Ryzhikov"]}], "birthDate": "1980-03-05"}')
     ;


INSERT INTO patient (status, txid, resource) VALUES
('created', 2, '{"name":[{"given":["Rene"], "family": ["Spronk"]}], "birthDate": "1970-03-05"}')
;

INSERT INTO patient (status, txid, resource) VALUES
('created', 3, '{"name":[{"given":["Grahame"], "family": ["Gieve"]}], "birthDate": "1975-02-05"}');
;

\x

SELECT * FROM patient
;

SELECT
   resource#>'{name,0,given,0}' as first_name
  , age(
     (resource->>'birthDate')::timestamptz
   ) as birth_date
FROM patient
;


SELECT id, resource->'name'
  FROM patient
 WHERE resource#>>'{name,0,given,0}' ilike '%rene%'
;

SELECT id, resource->'name'
  FROM patient
 WHERE (resource->>'birthDate')::date > '1978-01-01'::date
;

-- path expressions

create extension if not exists jsonknife;

SELECT knife_extract(resource, '[["name","given"], ["name","family"]]')
  FROM patient
;


-- more interesting examples

-- load data from some fhir server
-- https://www.postgresql.org/docs/9.6/static/app-psql.html

\set bundle `curl http://test.fhir.org/r3/Patient/?_format=json\&_count=10000` 
\set hapi `curl http://fhirtest.uhn.ca/baseDstu2/Patient?_count=1000`

-- https://www.postgresql.org/docs/9.5/static/functions-json.html


-- see bundle

SELECT count(*)
FROM jsonb_array_elements((:'bundle'::jsonb)->'entry') e
;

SELECT
  e#>'{resource, id}'
  ,e#>>'{resource,meta,lastUpdated}'
  ,e#>'{resource, name}'
FROM jsonb_array_elements((:'hapi'::jsonb)->'entry') e
LIMIT 5
;

-- clear the table
TRUNCATE patient;

INSERT INTO patient (id, ts, txid, status, resource)
SELECT
  e#>>'{resource,id}',
  (e#>>'{resource,meta,lastUpdated}')::timestamptz ,
  5 ,
  'imported',
  e->'resource'
FROM jsonb_array_elements((:'bundle'::jsonb)->'entry') e
;


SELECT
 id
 ,ts as lastUpdated
 ,resource->'gender' as gender
 ,resource->>'birthDate' as birth_date
 ,resource#>>'{name,0,family}' as family
FROM patient
WHERE (resource->>'birthDate')::date < '1940-01-01'::date
-- LIMIT 20
;

-- hack to make array_to_string immutble
CREATE OR REPLACE FUNCTION string_join(a text[])
RETURNS text AS $$
  SELECT ' ' || array_to_string(a, ' ');
$$ LANGUAGE sql IMMUTABLE
COST 1;

-- hack to make array_to_string immutble
CREATE OR REPLACE FUNCTION
patient_name(resource jsonb)
RETURNS text AS $$
  SELECT string_join(
    knife_extract_text(resource, '[["name","given"], ["name","family"]]')
  )
$$ LANGUAGE sql IMMUTABLE
COST 1;


-- name search
--EXPLAIN ANALYSE
SELECT
  id,
  patient_name(resource)
FROM patient
WHERE
  patient_name(resource) ilike '%Mars%'
LIMIT 20
;

-- do exlain analyze

-- les'ts speed up seach by indexes
-- https://www.postgresql.org/docs/9.6/static/pgtrgm.html

CREATE EXTENSION If NOT EXISTS pg_trgm; 

CREATE INDEX patient_name_ilike_idx
ON patient using gin (
  string_join(
    knife_extract_text(resource, '[["name","given"], ["name","family"]]')
  )
gin_trgm_ops);

DROP INDEX patient_name_ilike_idx;

-- https://www.postgresql.org/docs/9.6/static/sql-vacuum.html
VACUUM (FULL,ANALYZE) patient;

EXPLAIN ANALYSE
SELECT
  id,
  patient_name(resource)
FROM patient
WHERE
  string_join(
    knife_extract_text(resource, '[["name","given"], ["name","family"]]')
  ) ilike '%mar%'
LIMIT 20
;

-- associations


CREATE TABLE IF NOT EXISTS encounter (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Encounter',
  status text not null,
  resource jsonb not null
)
;

\set encs `curl http://test.fhir.org/r3/Encounter/?_format=json&_count=10000` 

-- https://www.postgresql.org/docs/9.5/static/functions-json.html


TRUNCATE encounter;

CREATE EXTENSION plv8;

INSERT INTO encounter (id, txid, status, resource)
  SELECT e#>>'{resource,id}', 6, 'imported', e->'resource'
  FROM jsonb_array_elements((:'encs'::jsonb)->'entry') e
;

SELECT
   e.id,
   e.resource#>'{subject,reference}',
   p.resource#>'{name,0,family}' as name
  FROM encounter e, patient p
  WHERE ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
limit 100
;


-- number of encounters

SELECT
  p.resource#>'{name,0,family}' as name,
  count(e.id)
FROM encounter e, patient p
WHERE ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
GROUP BY p.id
ORDER BY count(e.id) DESC
limit 100
;


-- search patient by encounter

\set hspcode '[["hospitalization", "admitSource", "coding", {"system": "http://snomed.info/sct"}, "code"]]'

SELECT 
  p.resource#>'{name, 0, family}',
  e.resource->'serviceProvider',
  knife_extract_text(e.resource, :'hspcode')
FROM encounter e, patient p
WHERE
  ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
  AND
  knife_extract_text(e.resource, :'hspcode') && ARRAY['305997006']
limit 100
;


-- search encounter by patient

SELECT
  e.id,
  e.ts,
  e.resource->'serviceProvider'
FROM encounter e, patient p
WHERE
('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
AND
  string_join(
    knife_extract_text(p.resource, '[["name","given"], ["name","family"]]')
  ) ilike '%heuv%'
limit 100
;


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

-- https://github.com/postgrespro/jsquery

DROP EXTENSION IF EXISTS jsquery;

CREATE EXTENSION IF NOT EXISTS jsquery;

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

-- js in postgres

CREATE EXTENSION IF NOT EXISTS plv8;

DROP FUNCTION patient_name(pt jsonb);

-- lets create name formating function
CREATE OR REPLACE FUNCTION patient_name(pt jsonb)
RETURNS text AS $$
  var res = {};
  return (pt.name || []).map(function(nm) {
     return [].concat(
      (nm.prfix || []),
      [nm.text],
      (nm.given || []),
      (nm.middle || []),
      [nm.family],
      (nm.sufix || [])
     ).filter(function(x){return x;}
     ).join(" ")
  }).join("; ");
$$ LANGUAGE plv8 IMMUTABLE STRICT;

-- use it
SELECT patient_name(resource)
FROM patient
LIMIT 100
;


-- fix references
DROP FUNCTION fix_encounter(enc jsonb);
CREATE OR REPLACE FUNCTION fix_encounter(enc jsonb)
RETURNS jsonb AS $$
   if(enc.subject && enc.subject.reference){
      var ref = enc.subject.reference;
      var parts = ref.split("/");
      enc.subject.id = parts[parts.length - 1];
      enc.subject.resourceType = parts[parts.length - 2];
   }
   return enc;
$$ LANGUAGE plv8 IMMUTABLE STRICT;

-- test
SELECT fix_encounter(resource)->'subject'
FROM encounter
LIMIT 100
;

-- apply
UPDATE encounter
SET resource = fix_encounter(resource)
;

-- use
select patient_name(p.resource), e.resource->'hospitalization'
from encounter e, patient p 
where
  e.resource#>>'{subject,id}' = p.id
;


-- How we fix in aidbox

-- * {reference: ".."} => {id: "...", "resourceType": "..."}
-- where encounter#>'{subject,id}' = ....

-- * {valueQuantity: {..}} => {value: {Quantity: {...}}}
-- where observaion#>'{Quantity,value}' = ....

-- * {extension: [{url/propName..., value/...}]} => {propName: value}
-- where patient->'race' = ....

-- # Terminology

\d concept

SELECT *
FROM concept
LIMIT 10
;

SELECT *
FROM concept
WHERE display ilike '%urine%'
AND system = 'http://snomed.info/sct'
LIMIT 10;



SELECT *
FROM concept
WHERE display ilike '%heart%failur%'
LIMIT 10
;


SELECT code, display
FROM concept
WHERE code ilike 'I50%'
LIMIT 10
;

-- we preserve properties of terminology
SELECT property
FROM concept
where system ilike '%loinc%'
LIMIT 10
;


SELECT code, display
FROM concept
where
property->>'system' =  'Heart'
LIMIT 100
;

-- nice integration of local terminology 
-- with FHIR database

VACUUM (analyze) concept;

SELECT id, resource#>>'{code,coding,0,code}'
FROM observation
LIMIT 10
;

SELECT
resource#>>'{valueQuantity,value}',
resource#>>'{valueQuantity,unit}',
c.display,
c.property->'system'
from observation o, concept c
where
resource#>>'{code,coding,0,code}' = c.code
LIMIT 10
;
