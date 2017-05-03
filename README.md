## FHIR generic database

* Problem Statement
  * Requirements
    * Transactions
    * Search
    * Extensibility
    * Ad-hock queries and analytic
    * Migrations
  * Constraints
    * small-data

* Solutions
  * relational
  * document databases
  * hybrid (fhirbase solution)
  
* HS solution
  * metadata driven
  * history implementation
  * transactions implementation
  * search implimentation
    * parse parameters
    * dynamic query generation
    * collections :(
    * fhirpath
      * fixes for FHIR json representation
    * filter statement
      * strings
      * uri
      * date
      * tokens
      * quantity
    * indexing
    * include & rev-include (has)
    * sorting

## Who we are?

HealthSamurai - small startup, pioneering FHIR in Health IT

## Our Beliefs

* We believe, that FHIR eco-system is a future
* We believe in generic FHIR platform as an brick in this eco-system,
  which allow to focus on innovation
* We are proving this hypothesis with our clients, 
  which are in production or going to production soon


## Generic DataBase

Generic backend requires generic database to store and query
FHIR resources in a sofisticated way.

## Requirements

* CRUD for resources
* History
* ACID Transactions
* Sophisticated search

----

* Not big data

## Approaches

* Relational DB
* Document DB
* Tripple Store
* ~ Graph DB

## Relational 

* - a lot of tables ~ 1K tables (first version of fhirbase)
* - expensive and complicated insert ()
* - expensive and complicated search (joins)
* - extensibility is tricky
* + more familar
* + partial updates
* + flexible queries  (analytic)


## Document DBs

* + one to one match Resource <-> Document
* + most of Doc Db's distributed (do we really need it?)
* - no ACID transactions (mongo, rethink) - manual consistency
* - no sophisticated queries without materialization (no joins, window functions etc)

## Key-Value + Indexes  hybrids

* riak + elastic search
* + scale & availability
* - consistency

## Tripple store

* + extensibility flexible schema
* - performance
* - no mature/free implementations

## Graph DBs

If you know some experiments - please let me know

## RDBMs + Documents hybrid 

More RDBMs support json as native datatype.

Example:

```sql
-- pg jsonb datatype

```


## RDBMs + Documents hybrid 

* + one to one match Resource <-> Document column
* + sophisticated queries (using json field access functions)
* + indexes by expression/functional indexes
* + ACID
* - quite new technology
* - scale & availability

## SQL 2017

* fresh SQL standard include json type and functions on top of it
* it's based on Oracle implementation, but PostgreSQL started working on it
* so you could apply same approach to different RDBMs
* i will talk about PostgreSQL implementation

## CRUD implementation


```sql

create table patient (
  id text primary key default uuid_gen,
  version_id text,
  resource jsonb
);

create table patient_history (
  id text primary key default uuid_gen,
  resource jsonb
);

-- create

INSERT INTO Patient 
  (resource) 
  VALUES
  ('{"resourceType": "Patient", "name": [{"given": "Nikolai"}]}');


-- CTE for update

-- CTE for delete

-- UPSERT

-- READ

SELECT * FROM patient WHERE id = ?

-- History

SELECT * FROM patient_history WHERE id = ?

```

## Transaction

```


```

## Query

You could access jsonb document attributes
using special operators and use this expressions
in any SQL queries

```sql

SELECT 
  resource#>>'name,0',
  (resource->'birthDate')::timestamptz
FROM patient
  WHERE
  (resource->'birthDate')::timestamptz > '1980'::timestamptz
  ;

```

## Implementing FHIR Search


QueryString:

-> parse and validate params
-> get param metadata - type & path expression
-> get path pointing elements datatypes
-> build SQL query

## Organization.name & string search

## Extraction & FHIR path

* Simple subset a.b & a.where(c=j).c
* Turing complete

## JSON format fixes

* polymorphics
* refs
* extensions
* no primitive extensions :(

## Collections complication


```sql

SELECT 
  knife_extract(resource, '[["name"]]')
FROM patient;

SELECT 
  knife_extract_text(resource, '[["name", "given"], ["name", "family"]]')
FROM patient;

SELECT 
  join_string(
    knife_extract_text(resource, '[["name", "given"], ["name", "family"]]')
  ) as name_text
FROM patient
WHERE
  join_string(
    knife_extract_text(resource, '[["name", "given"], ["name", "family"]]')
  ) ilike '%Nikolai%'

```

## Token search

arrays

## date & number search

min/max

## reference search

## quantity search

jsquery

## chained params

joins 

## indexing

gin, gist, brin, btree etc

## Logical Transactions

## Patch problem

## Terminology implementation

* Concept table
* ValueSet as query
* Implementation problems (excludes :()

## Batch Loading

* insert ... select build_object

## Road Map

* json schema extension
* referencial consistency
