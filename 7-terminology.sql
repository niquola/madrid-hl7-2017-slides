-- # Terminology
-- terminology as Concept resource
-- with cross search

\d concept

SELECT * FROM concept LIMIT 10
;

SELECT distinct(system) FROM concept;

SELECT count(concept) FROM concept;

SELECT *
FROM concept
WHERE display ilike '%urine%'
AND system = 'http://snomed.info/sct'
LIMIT 5;

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
LIMIT 10
;

-- nice integration of local terminology 
-- with FHIR database

VACUUM (analyze) concept;

SELECT id, resource#>>'{code,coding,0,code}'
FROM observation
LIMIT 10
;

SELECT resource#>>'{valueQuantity,value}',
       resource#>>'{valueQuantity,unit}',
       c.display,
       c.property->'system'
FROM observation o, concept c
WHERE
resource#>>'{code,coding,0,code}' = c.code
LIMIT 10
;
