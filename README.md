# Generic database for FHIR

## Who we are?

I'm Ryzhikov Nikolai 

CTO & Co-founder of HealthSamurai

We are startup, 
pioneering FHIR in Health IT

* niquola (on twitter, github)
* nicola (RIO) (on fhir chat)


## Our Beliefs

* We believe, that FHIR eco-system is a future
* We believe, tat generic FHIR platform 
  as a useful brick in this eco-system
* We are proving this hypothesis with our clients, 
  which are in production or going to production soon
  
  
  
  
  

## Problem/ Challenged


Generic server needs 
Generic Database








## Minimal Requirements

* Transactions (ACID)
* History tracking
* Sophisticated query (FHIR Search, Analytic etc)
* Extensibility (Extensions, Search Params, Compartments)



## Approaches

* Relational DB
* Document DB
* Tripple Store
* ~ Graph DB
* Plygot
* Hybryd



## Relational 

* + more traditional (tools like ORM)
* + flexible queries  (analytic)
* + partial updates
* - a lot of tables ~ 1K tables 
    (first version of fhirbase)
* - expensive and complicated insert 
    (resource -> ~10 tables)
* - expensive and complicated search 
    (joins are not for free)
* - extensibility is tricky (dynamic schema)




## Document DBs

* + one to one match Resource <-> Document
* + most of Doc Db's distributed and available 
* - no ACID transactions (mongo, rethink) 
    manual consistency is a hell
* - support queries thro different Resource Types 
    (joins, window functions etc)


## Polyglot: Key-Value + Indexes 

For example: 
 casandre or riak + elastic

* + scale & availability
* + flexible
* - complexity
* - consistency



## Tripple store

Like datomic

* + extensibility
* + semantic
* - popular implementations
* - performance




## Graph DBs

If you know some experiments - please let me know







## Our solution - hybrid

Hybrid relational & document storage,
using databases json support (especially PostgreSQL)

* fhirbase
* aidbox





## Overview

* store FHIR resources in json column
* use `fhirpath` functions for access to fields 
* use functional indexes to speedup queries

---

* Transactions
* Expressive power of SQL
* Advanced features of PostgreSQL
  indexing, extensions etc




## What if not a postgres

SQL standard 2016
includes *json* type and utility *functions*

* mysql
* oracle
* mssql


## Demo time

* CRUD
* History
* Search
* Indexes
* Terminology

code is available on github.com/niquola/madrid-2017-slides
