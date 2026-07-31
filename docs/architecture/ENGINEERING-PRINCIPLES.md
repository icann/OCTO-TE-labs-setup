# Engineering Principles

**Status:** In Review

**Last Updated:** 2026-07-31

---

# Purpose

This document defines the engineering principles that guide the design, evolution, and maintenance of the OCTO-TE Labs platform.

These principles are intended to remain stable over time and provide a common engineering philosophy for all future development.

---

# Principle 1 — Architecture Before Implementation

Architecture defines **what** the platform is.

Implementation defines **how** the platform is built.

Implementation may evolve over time without requiring fundamental architectural changes.

---

# Principle 2 — Capabilities Drive the Architecture

The platform is organized around **training domains** and **capabilities**, rather than around implementation technologies.

Current training domains include:

- DNS
- Routing

Each domain is composed of one or more capabilities.

Examples:

## DNS

- Recursive DNS
- Authoritative DNS
- DNSSEC
- Universal Acceptance
- DNS Monitoring

## Routing

- BGP
- Anycast
- RPKI

Additional domains and capabilities may be introduced as the platform evolves.

---

# Principle 3 — Documentation Evolves with the Platform

Documentation is considered part of the engineering process.

Every significant architectural or implementation change should be reflected in the Architecture & Engineering Handbook.

Documentation is never treated as an afterthought.

---

# Principle 4 — Understand Before Modifying

No implementation should be modified until its current behavior has been understood.

The engineering workflow is:

1. Understand
2. Document
3. Design
4. Implement
5. Validate
6. Update Documentation

---

# Principle 5 — Architecture Is Independent from the Current Implementation

The architecture describes the intended structure of the platform.

Implementation documents describe the current implementation.

Future design documents describe the desired evolution.

This separation allows the platform to evolve without losing architectural consistency.

---

# Principle 6 — Documentation Must Be Evidence-Based

Architecture documentation should be supported by one of the following:

- verified implementation;
- approved architectural decisions;
- documented engineering design.

Assumptions should never be documented as facts.

Whenever uncertainty exists, it should be explicitly stated.

---

# Principle 7 — Every Document Has a Single Responsibility

Each document in the Handbook should have a clearly defined purpose.

Information should not be duplicated across multiple documents.

Instead, documents should reference each other whenever appropriate.

---

# Principle 8 — Engineering Knowledge Is a Project Asset

Knowledge accumulated during the evolution of the platform is considered an engineering asset.

The Knowledge Base should continuously capture:

- architectural discoveries;
- implementation details worth preserving;
- engineering rationale;
- important observations;
- lessons learned.

This allows future contributors to understand not only how the platform works, but also why it was designed that way.

---

# Principle 9 — Architecture Should Enable Growth

The architecture should facilitate the addition of new capabilities without requiring major redesign.

New training domains, capabilities, deployment models, and technologies should integrate naturally into the existing architecture.

Scalability of the architecture is considered more important than optimization of the current implementation.

---

# Principle 10 — Engineering Documentation Language

The Architecture & Engineering Handbook is written in English.

Training materials, laboratory instructions, and participant-facing documentation may be produced in multiple languages according to the target audience.

---

# Engineering Workflow

The standard engineering workflow adopted for OCTO-TE Labs is:

```text
Idea
    ↓
Architecture
    ↓
Documentation
    ↓
Analysis
    ↓
Implementation
    ↓
Validation
    ↓
Knowledge Base
    ↓
Release
```

---

# Long-Term Vision

The objective of the Architecture & Engineering Handbook is to become the authoritative engineering reference for OCTO-TE Labs.

It should allow engineers to understand the platform, its architecture, its evolution, and the rationale behind engineering decisions without requiring prior knowledge of the implementation.

---

# Documentation Standards

## Document Status

Every document shall use one of the following status values:

- Draft
- In Review
- Approved
- Deprecated

Documents are promoted to **Approved** only after technical review.

---

## Engineering Identifiers

The Handbook uses stable identifiers to facilitate traceability.

| Prefix | Purpose |
|---|---|
| ADR | Architecture Decision Record |
| KB | Knowledge Base Entry |
| EPIC | Engineering Epic |
| TASK | Engineering Task |
| AC | Architecture Candidate |
| TD | Technical Debt |
| BUG | Bug |
| IMP | Improvement |
| FEAT | Feature |

Identifiers are never reused.

---

## Cross References

Whenever possible, engineering artifacts should reference related artifacts.

Examples include:

- ADRs;
- Knowledge Base entries;
- Tasks;
- Architecture documents.

The objective is to build a connected engineering knowledge system instead of isolated documents.

---

## Document Creation

A new document should normally be created only when there is enough stable content to justify its existence.

A placeholder document may be created in advance when its future purpose and planned scope are already clear.

Placeholder documents must:

- use the `Draft` status;
- describe their intended purpose;
- define their planned scope;
- identify the engineering work during which they are expected to be completed;
- never remain completely empty.

The Handbook should remain compact and well organized.
