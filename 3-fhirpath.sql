-- We need access deeply nested fields
-- this is where document model differs
-- from relations
-- path expressions

create extension
if not exists jsonknife;

/*
jsonknife is a postgres extension
which allow you to extract some fileds
by path expression, which encoded as json array
where items interpreted as:

* string  - get element by key from object
* number  - get element by index from array
* object  - filter by example

*/

\df knife*

SELECT knife_extract(
  resource, '[["name","given"]]'
)
FROM patient
limit 10
;

-- pattern
SELECT
  knife_extract(
    resource, '[["name", {"use": "official"}, "family"]]'
  ),
  resource->'name'
FROM patient
limit 10
;

-- index
SELECT
  knife_extract(
    resource, '[["name", 0, "use"]]'
  ),
  resource->'name'
FROM patient
limit 10
;

SELECT
    knife_extract_max_timestamptz(
    resource, '[["birthDate"]]'
    ),
resource->'name'
FROM patient
limit 10
;

SELECT knife_date_bound('2001', 'min');
SELECT knife_date_bound('2001', 'max');

-- eager search
-- max > min query
-- min < max query

SELECT resource->'birthDate'
FROM patient
WHERE
  knife_extract_max_timestamptz(
    resource, '[["birthDate"]]'
  ) > knife_date_bound('2001', 'min')
limit 10
;

-- ordering max desc, min asc

SELECT resource->'birthDate'
FROM patient
ORDER BY
knife_extract_min_timestamptz(
  resource, '[["birthDate"]]'
) asc
limit 5
;
