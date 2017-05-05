-- path expressions

create extension if not exists jsonknife;

\df knife*

SELECT knife_extract(
  resource, '[["name","given"], ["name","family"]]'
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
