\timing
-- hack to make array_to_string immutble
CREATE OR REPLACE FUNCTION string_join(a text[])
RETURNS text AS $$
  SELECT ' ' || array_to_string(a, ' ');
$$ LANGUAGE sql IMMUTABLE
COST 1;

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
  patient_name(resource) ilike '%Jon%'
  -- AND patient_name(resource) ilike '%pen%'
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

--EXPLAIN ANALYSE
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
