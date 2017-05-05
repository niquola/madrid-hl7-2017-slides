# Generic database for FHIR

## Who we are?

HealthSamurai - small startup, pioneering FHIR in Health IT

## Our Beliefs

* We believe, that FHIR eco-system is a future
* We believe in generic FHIR platform 
  as a useful brick in this eco-system
* We are proving this hypothesis with our clients, 
  which are in production or going to production soon

## Problem/ Challenged

* Generic server 
  needs Generic Database

## Minimal Requirements

* Transactions (ACID)
* History tracking
* Sophisticated query (FHIR Search, Analytic etc)
* Extensibility (Extensions, Search Params, Compartments)

----

Note: we are not big data!

## Approaches

* Relational DB
* Document DB
* Tripple Store
* ~ Graph DB
* Plygot

## Relational 

* + more traditional (tools like ORM)
* + flexible queries  (analytic)
* + partial updates
* - a lot of tables ~ 1K tables (first version of fhirbase)
* - expensive and complicated insert (resource -> ~10 tables)
* - expensive and complicated search (joins)
* - extensibility is tricky (dynamic schema)


## Document DBs

* + one to one match Resource <-> Document
* + most of Doc Db's distributed (do we really need it?)
* - no ACID transactions (mongo, rethink) - manual consistency
* - support queries thro different Resource Types (joins, window functions etc)

## Polyglot: Key-Value + Indexes 

* + scale & availability
* + flexible
* - consistency
* - complexity

## Tripple store

* + extensibility
* + semantic
* - popular implementations
* - performance

## Graph DBs

If you know some experiments - please let me know


## Hybryd

Hybryd relational & document storage,
using databases json support (especially PostgreSQL)

* fhirbase
* aidbox

## Overview

* store FHIR resources in json column
* use `fhirpath` functions for access to fields 
* use functional indexes to speedup queries

---

* Native transactions
* Expressive power of SQL
* Advanced features of PostgreSQL


## What if not a postgresql

SQL standard 2016
includes *json* type and utility *functions*


## Let's implement it now

* CRUD
* History
* Search
* Indexes
* Terminology


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
