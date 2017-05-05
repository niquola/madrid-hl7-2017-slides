\timing

-- extension for uuid
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- function for extension
SELECT gen_random_uuid();

DROP TABLE IF EXISTS patient;

CREATE TABLE IF NOT EXISTS patient (
  id text primary key DEFAULT gen_random_uuid(),
  txid bigint not null,
  ts timestamptz DEFAULT current_timestamp,
  resource_type text default 'Patient',
  status text not null,
  resource jsonb not null
)
;


DROP TABLE IF EXISTS patient_history;
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
,('created', 2, '{"name":[{"given":["Rene"], "family": ["Spronk"]}], "birthDate": "1970-03-05"}')
,('created', 3, '{"name":[{"given":["Grahame"], "family": ["Gieve"]}], "birthDate": "1975-02-05"}');
;

\x

-- select resources
SELECT * FROM patient
;

-- access attributes
SELECT resource#>'{name,0,given,0}' as first_name
       , age(
         (resource->>'birthDate')::timestamptz
       ) as birth_date
FROM patient
;


-- simple search
SELECT id
      ,resource->'name'
  FROM patient
 WHERE resource#>>'{name,0,given,0}' ilike '%rene%'
;

SELECT substring(id for 6) || '...'
       ,resource->'name'
  FROM patient
 WHERE
   (resource->>'birthDate')::date > '1978-01-01'::date
;

-- more interesting examples

-- load data from some fhir server
-- https://www.postgresql.org/docs/9.6/static/app-psql.html

\set bundle `curl http://test.fhir.org/r3/Patient/?_format=json\&_count=10000` 

-- https://www.postgresql.org/docs/9.5/static/functions-json.html


-- see bundle

SELECT count(*)
  FROM jsonb_array_elements((:'bundle'::jsonb)->'entry') e
;

SELECT
   e#>'{resource, id}'
  ,e#>>'{resource,meta,lastUpdated}'
  ,e#>'{resource, name}'
FROM jsonb_array_elements((:'bundle'::jsonb)->'entry') e
LIMIT 5
;

-- clear the table
TRUNCATE patient;

-- load patients
INSERT INTO patient (id, ts, txid, status, resource)
SELECT e#>>'{resource,id}',
       (e#>>'{resource,meta,lastUpdated}')::timestamptz ,
       5 ,
       'imported',
       e->'resource'
FROM jsonb_array_elements((:'bundle'::jsonb)->'entry') e
;

-- search by date
SELECT id
      ,ts as lastUpdated
      ,resource->'gender' as gender
      ,resource->>'birthDate' as birth_date
      ,resource#>>'{name,0,family}' as family
FROM patient
 WHERE (resource->>'birthDate')::date < '1940-01-01'::date
LIMIT 5 
;
