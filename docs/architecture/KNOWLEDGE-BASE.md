# Knowledge Base

**Status:** In Review

**Last Updated:** 2026-07-31

---

# Purpose

The Knowledge Base is the long-term engineering memory of the OCTO-TE Labs platform.

Unlike architecture documents, which describe how the platform is designed, or development documents, which describe ongoing work, the Knowledge Base preserves engineering knowledge that remains valuable over time.

It answers questions such as:

- What has been learned about the platform?
- Why does a component behave in a particular way?
- Which implementation details are important to preserve?
- Which architectural ideas are currently under evaluation?

The Knowledge Base is intended to become the institutional engineering memory of the project.

---

# Scope

The Knowledge Base records information that should remain useful independently of individual engineering sessions.

Typical entries include:

- architectural discoveries;
- implementation discoveries;
- historical context;
- engineering observations;
- long-term lessons learned;
- architecture candidates.

It does **not** replace:

- architecture documents;
- Architecture Decision Records;
- the Engineering Backlog;
- the Engineering Log.

Each of those artifacts has a separate purpose.

---

# Knowledge Categories

Knowledge Base entries use one of the following categories.

## Architecture Knowledge

Knowledge that improves understanding of the conceptual architecture of the platform.

Examples include:

- architectural models;
- relationships between major components;
- capability organization;
- platform boundaries.

---

## Implementation Knowledge

Knowledge that helps explain how the current implementation works.

Examples include:

- initialization order;
- dependencies between scripts;
- container lifecycle;
- network initialization;
- configuration generation.

Implementation knowledge should describe behavior rather than reproduce source code.

---

## Historical Knowledge

Knowledge that explains how or why the platform evolved.

Examples include:

- original design decisions;
- migration history;
- compatibility constraints;
- previous implementation approaches.

Historical context should be recorded when it helps future maintainers understand the current platform.

---

## Engineering Observation

Technical observations discovered during analysis.

Examples include:

- hidden dependencies;
- recurring design patterns;
- operational constraints;
- opportunities for simplification.

An observation does not, by itself, constitute an architectural decision.

---

# Architecture Candidates

Architecture Candidates are ideas that appear promising but have not been approved as architectural decisions.

Candidates remain open until they are either:

- approved through an Architecture Decision Record;
- deferred for later consideration;
- rejected after review.

---

## AC-0001 — Capability-Based Lab Composition

**Status**

Candidate

**Summary**

Future versions of the platform could compose laboratories from a selected set of capabilities instead of relying exclusively on predefined laboratory types.

Examples of selectable capabilities include:

- Recursive DNS;
- Authoritative DNS;
- DNSSEC;
- BGP;
- Anycast;
- RPKI.

This approach could increase flexibility and simplify the future orchestration model.

**Planned Review**

EPIC-003

**Related**

- `docs/architecture/00-architecture-map.md`
- `docs/development/engineering-backlog.md`

---

## AC-0002 — Capability Taxonomy

**Status**

Candidate

**Summary**

Capabilities could eventually be classified into categories such as:

- Core Capabilities;
- Security Capabilities;
- Operational Capabilities;
- Deployment Capabilities.

A capability taxonomy could improve documentation, discovery, composition, and future orchestration.

**Planned Review**

EPIC-003

**Related**

- AC-0001
- `docs/architecture/00-architecture-map.md`
- `docs/development/engineering-backlog.md`

---

## AC-0003 — Training Profiles

**Status**

Candidate

**Summary**

Training Profiles could provide an instructor-facing mechanism for composing laboratories from capabilities.

Instead of selecting an implementation-specific laboratory type, an instructor could select a profile such as:

- Recursive DNS Fundamentals;
- Authoritative DNS Operations;
- Secure Routing Fundamentals;
- Anycast Deployment;
- Advanced DNSSEC.

Each profile would activate the capabilities required for that training experience.

**Planned Review**

EPIC-003

**Related**

- AC-0001
- AC-0002
- `docs/development/engineering-backlog.md`

---

## AC-0004 — ADR Classification

**Status**

Candidate

**Summary**

If the number of Architecture Decision Records grows substantially, ADRs could be classified into categories such as:

- Foundational ADRs;
- Platform ADRs;
- Deployment ADRs;
- Capability ADRs.

This classification should only be introduced when the number and diversity of ADRs justify the additional organizational structure.

**Planned Review**

EPIC-003

**Related**

- ADR-0001
- `docs/decisions/README.md`
- `docs/development/engineering-backlog.md`

---

# Knowledge Entry Format

Every new Knowledge Base entry should use a stable identifier and follow this structure:

```text
## KB-XXXX — Short Title

**Date**

YYYY-MM-DD

**Category**

Architecture Knowledge | Implementation Knowledge |
Historical Knowledge | Engineering Observation

**Summary**

Concise description of the knowledge being preserved.

**Related**

- Related ADRs
- Related Architecture Candidates
- Related tasks
- Related documents

**Notes**

Optional additional context.
```

Identifiers are sequential and must never be reused.

---

# Engineering Knowledge

## KB-0001 — Capability-Driven Architecture

**Date**

2026-07-31

**Category**

Architecture Knowledge

**Summary**

The OCTO-TE Labs architecture is organized around training domains and capabilities rather than implementation technologies.

**Related**

- ADR-0001
- `docs/architecture/00-architecture-map.md`
- AC-0001

---

## KB-0002 — Architecture and Implementation Separation

**Date**

2026-07-31

**Category**

Architecture Knowledge

**Summary**

Architecture documentation intentionally remains independent from the current implementation.

The implementation may evolve while preserving the conceptual architectural model.

**Related**

- ADR-0001
- `docs/architecture/ENGINEERING-PRINCIPLES.md`
- `docs/architecture/00-architecture-map.md`

---

## KB-0003 — Lifecycle-Oriented Analysis

**Date**

2026-07-31

**Category**

Engineering Observation

**Summary**

The most effective way to understand the platform is to follow its complete lifecycle rather than reading individual scripts in isolation.

This principle guides the work performed during EPIC-001.

**Related**

- EPIC-001
- TASK-0010
- `docs/development/engineering-backlog.md`

---

## KB-0004 — Handbook as an Engineering Asset

**Date**

2026-07-31

**Category**

Architecture Knowledge

**Summary**

The Architecture & Engineering Handbook is considered part of the platform and evolves together with its architecture and implementation.

Documentation is maintained as a long-term engineering asset.

**Related**

- ADR-0001
- `docs/README.md`
- `docs/architecture/ENGINEERING-PRINCIPLES.md`

---

# Cross References

Whenever possible, Knowledge Base entries should reference related engineering artifacts.

Examples include:

- Architecture Decision Records;
- Architecture Candidates;
- engineering tasks;
- architecture documents;
- reference documents.

Cross-references help transform the Handbook into an interconnected engineering knowledge system rather than a set of isolated documents.

---

# Maintenance Policy

Knowledge is expected to accumulate throughout the lifetime of the project.

Existing entries should normally be refined rather than removed.

If an entry becomes obsolete, it should be marked appropriately and retain enough context to explain why it is no longer applicable.

Engineering knowledge is considered a long-term project asset.

---

# Review Status

**Current Status**

In Review

**Next Review**

After completion of EPIC-001.