-- associations

DROP TABLE encounter;

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

TRUNCATE encounter;

INSERT INTO encounter (id, txid, status, resource)
  SELECT e#>>'{resource,id}', 6, 'imported', e->'resource'
  FROM jsonb_array_elements((:'encs'::jsonb)->'entry') e
;

SELECT id,
       resource#>'{subject,reference}'
FROM encounter
limit 100
;

-- let's  join with patients

SELECT e.id,
       e.resource#>'{subject,reference}',
       p.resource#>'{name,0,family}' as name
  FROM encounter e, patient p
  WHERE ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
limit 5
;


-- do some analytic
-- number of encounters

SELECT p.resource#>'{name,0,family}' as name,
       count(e.id) as "number of visits"
FROM encounter e, patient p
WHERE ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
GROUP BY p.id
ORDER BY count(e.id) DESC
limit 10
;

-- search patient by encounter

\set hspcode '[["hospitalization", "admitSource", "coding", {"system": "http://snomed.info/sct"}, "code"]]'

SELECT knife_extract_text(resource, :'hspcode')
FROM encounter
limit 10
;

SELECT p.resource#>'{name, 0, family}',
       e.resource->'serviceProvider',
       knife_extract_text(e.resource, :'hspcode')
FROM encounter e, patient p
WHERE
  ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
  AND
  knife_extract_text(e.resource, :'hspcode') && ARRAY['305997006']
limit 10
;


-- search encounter by patient

SELECT e.id, e.ts, e.resource->'serviceProvider'
FROM encounter e, patient p
WHERE
  -- this is ugly :/
  ('Patient/' || p.id)  = e.resource#>>'{subject,reference}'
AND
  string_join(
    knife_extract_text(p.resource, '[["name","given"], ["name","family"]]')
  ) ilike '%heuv%'
limit 100
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
LIMIT 5
;

-- fix references
-- {reference: "Patient/1"} => {resourceType: "Patient", "id": "1"}
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
SELECT
  fix_encounter(resource)->'subject' as pt
FROM encounter
LIMIT 5
;

-- apply
UPDATE encounter
SET resource = fix_encounter(resource)
;

-- use
SELECT patient_name(p.resource),
       e.resource->'hospitalization'
FROM encounter e, patient p 
WHERE e.resource#>>'{subject,id}' = p.id
;

-- How we fix in aidbox

-- * {reference: ".."} => {id: "...", "resourceType": "..."}
-- where encounter#>'{subject,id}' = ....

-- * {valueQuantity: {..}} => {value: {Quantity: {...}}}
-- where observaion#>'{Quantity,value}' = ....

-- * {extension: [{url/propName..., value/...}]} => {propName: value}
-- where patient->'race' = ....

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
  resource->'base',
  resource->'name',
  resource->'expression'
from searchparameter
where
  knife_extract_text(resource, '[["base"]]') && ARRAY['Patient']
  -- AND
  -- resource->>'name' = 'name'
limit 10
;
