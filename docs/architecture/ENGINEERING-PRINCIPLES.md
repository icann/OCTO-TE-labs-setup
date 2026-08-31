# Engineering Principles

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document defines the engineering principles that guide the design, evolution, operation, and documentation of OCTO-TE Labs.

The principles are intended to remain more stable than individual scripts, package versions, Lab Types, or cloud-resource definitions.

---

# Principle 1 - Architecture Before Implementation

Architecture defines what responsibilities and relationships the platform requires.

Implementation defines how the current branch realizes them.

A temporary implementation detail must not become a permanent architectural constraint without an explicit decision.

---

# Principle 2 - Capabilities Drive the Architecture

The platform is organized conceptually around training domains and capabilities rather than products.

Current domains and capabilities include:

- DNS: Recursive DNS, Authoritative DNS, DNSSEC, DNS Monitoring, Universal Acceptance;
- Routing: BGP, Anycast, RPKI.

Profiles combine capabilities. Software roles implement them.

---

# Principle 3 - Understand Before Modifying

The normal workflow is:

1. establish current behavior;
2. identify ownership and dependencies;
3. document evidence and uncertainty;
4. design the smallest coherent change;
5. implement;
6. validate success, failure, and cleanup;
7. update documentation and engineering records.

---

# Principle 4 - Evidence Before Claims

A support claim must be based on one or more of:

- verified source behavior;
- successful deployment tests;
- measured operational evidence;
- an approved architectural decision.

Code presence alone does not prove that a profile works. Assumptions and intended behavior must be labeled explicitly.

---

# Principle 5 - Current, Future, and Historical Views Stay Separate

- Architecture documents describe stable structure.
- Implementation documents describe the current branch.
- Design documents describe proposals.
- The Engineering Log describes chronology.
- The Knowledge Base preserves durable lessons.
- ADRs preserve decisions and rationale.

This separation prevents planned work from being mistaken for current functionality.

---

# Principle 6 - Documentation Evolves with the Platform

Documentation is an engineering artifact, not an afterthought.

A significant implementation change should update the relevant:

- architecture document;
- reference document;
- ADR, when a decision changed;
- Knowledge Base, when a durable lesson emerged;
- Engineering Log and Backlog;
- Handbook Changelog.

Documentation debt is engineering debt.

---

# Principle 7 - Every Resource Has an Owner

Every cloud record, container, network, credential, file, firewall rule, and external state change must have a defined creator and cleanup owner.

Ownership determines:

- lifecycle order;
- deletion behavior;
- idempotency requirements;
- failure recovery;
- documentation location.

The DS cleanup custom resource is an example: the EC2-side deployment creates the DS, while a CloudFormation-owned custom resource removes it during stack deletion.

---

# Principle 8 - Security Is the Default, Not a Later Feature

Public interfaces and inherited credentials must be secure by construction.

Requirements include:

- no fixed bootstrap credentials in deployable templates;
- explicit authentication or access control on public web interfaces;
- least-privilege IAM;
- secrets excluded from logs;
- validated firewall and Security Group rules;
- safe key and certificate handling;
- security review of failure and partial-deployment states.

A feature that works but exposes a fixed credential or unprotected management interface is not complete.

---

# Principle 9 - Lifecycle Completeness Is Part of Correctness

A component is not complete until create, start, stop, validate, delete, and repeated cleanup behavior are defined where applicable.

Cleanup should be idempotent:

```text
resource exists     -> remove it
resource absent     -> succeed without harmful error
partial deployment  -> remove whatever was created
repeated cleanup    -> remain safe
```

---

# Principle 10 - Reproducibility Requires Controlled Dependencies

Runtime downloads from operating-system repositories, third-party package repositories, GitHub, RubyGems, and certificate services can change without a repository commit.

The platform should progressively adopt:

- version recording and pinning where appropriate;
- caching or prebaked templates;
- integrity checks;
- retry and failure policy;
- dependency inventories;
- regression tests against supported versions.

An unchanged repository must not be assumed to produce an unchanged deployment when external dependencies move.

---

# Principle 11 - Scalability Is Measured

Capacity claims require measurements.

Record at least:

- host CPU and memory;
- swap and storage;
- real instance count from the LXD API;
- running and stopped state counts;
- per-role memory;
- service-specific threads and objects;
- deployment time;
- failure point and cleanup state.

Historical success above 100 groups is valuable evidence, but current support must be revalidated on the current implementation and host class.

---

# Principle 12 - Limits and Reservations Are Different

A container memory limit is a ceiling, not a reservation.

Documentation and capacity planning must distinguish:

- configured maximum;
- current use;
- peak use;
- shared host overhead;
- workload-specific exceptions.

---

# Principle 13 - Changes to Active Stacks Require an Explicit Plan

CloudFormation updates can replace resources unexpectedly, including the EC2 host when a moving AMI alias changes.

For an active stack:

- create a change set;
- pin the existing AMI when necessary;
- inspect all replacements;
- preserve or export required state;
- execute only after review.

The normal lab lifecycle remains create, operate, and delete.

---

# Principle 14 - Preserve Working Behavior During Evolution

Refactoring should not casually discard proven operational behavior from the original platform.

Examples include:

- prepared network underlay;
- on-demand group resources;
- the `extra` network;
- high-scale host tuning;
- internal wipe and redeploy;
- dual-stack operation;
- public testing of selected DNS roles.

Recovery work should compare the current branch with the original implementation and preserve useful behavior deliberately.

---

# Principle 15 - Prefer the Smallest Coherent Change

A change should be large enough to be internally consistent and small enough to review and validate.

Unrelated fixes should not be bundled merely because they were discovered together. Confirmed findings should be recorded in the backlog when deferred.

---

# Principle 16 - One Document, One Primary Responsibility

Avoid copying the same detailed facts into many documents.

Use:

- architecture for relationships;
- reference for exact values;
- decisions for rationale;
- design for proposals;
- development for chronology and planning;
- Knowledge Base for durable lessons.

Cross-reference instead of duplicating when practical.

---

# Principle 17 - Engineering Knowledge Is a Project Asset

Knowledge gathered during debugging, scaling, deployment, and review must survive the individual session.

The Knowledge Base should capture:

- architectural discoveries;
- implementation behavior worth preserving;
- operational lessons;
- historical context;
- measured observations;
- unresolved architecture candidates.

---

# Principle 18 - Engineering Documentation Language

The Architecture & Engineering Handbook is written in English.

Participant-facing material may be multilingual according to the audience.

Commands, scripts, filenames, variables, and code comments use English.

---

# Engineering Workflow

```text
Idea
    -> Architecture or Design
    -> Documentation
    -> Analysis
    -> Implementation
    -> Validation
    -> Knowledge Base
    -> Release
```

Urgent production fixes can alter the order, but evidence, validation, and documentation still remain required.

---

# Documentation Standards

## Document status

General Handbook documents use:

- Draft;
- In Review;
- Approved;
- Deprecated.

ADRs additionally use:

- Superseded;
- Rejected.

Documents become Approved only after explicit technical review.

## Engineering identifiers

| Prefix | Purpose |
|---|---|
| ADR | Architecture Decision Record |
| KB | Knowledge Base entry |
| EPIC | Engineering epic |
| TASK | Engineering task |
| AC | Architecture Candidate |
| TD | Technical debt |
| BUG | Confirmed defect |
| IMP | Improvement |
| FEAT | Feature |

Identifiers are never reused.

## Dates

- Current-state documents use `Last Updated`.
- ADRs use the original decision `Date` and may add `Last Reviewed`.
- Historical entries retain the date of the event or observation.

## Cross references

Engineering artifacts should reference related ADRs, Knowledge Base entries, backlog items, and architecture/reference documents.

## Placeholder policy

A placeholder is permitted only when:

- its future responsibility is known;
- it has Draft status;
- it contains purpose and planned scope;
- its completion work is identified;
- it is not empty.

The 2026-08-31 reconciliation replaced the initial architecture placeholders with substantive content.

---

# Source-of-Truth Order

When documents conflict, resolve the discrepancy using:

1. current verified implementation and deployment evidence;
2. approved ADRs;
3. current In Review architecture/reference documentation;
4. Draft future design;
5. historical notes.

Then correct the stale artifact rather than preserving the contradiction.

---

# Review Status

**Current Status:** In Review

**Next Review:** After the first hardening implementation cycle tests these principles against concrete security and lifecycle changes.
