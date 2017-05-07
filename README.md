# Generic database for FHIR

## Who we are?

HealthSamurai - we are startup, 
pioneering FHIR in Health IT

## Our Beliefs

* We believe, that FHIR eco-system is a future
* We believe, tat generic FHIR platform 
  as a useful brick in this eco-system
* We are proving this hypothesis with our clients, 
  which are in production or going to production soon

## Problem/ Challenged


Generic server needs Generic Database


## Minimal Requirements

* Transactions (ACID)
* History tracking
* Sophisticated query (FHIR Search, Analytic etc)
* Extensibility (Extensions, Search Params, Compartments)


> HealthIT mostly are not big data!

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
