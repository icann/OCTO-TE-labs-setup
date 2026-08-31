# Architecture Decisions

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This directory contains Architecture Decision Records (ADRs) for significant decisions that affect the long-term structure, responsibilities, boundaries, or evolution of OCTO-TE Labs.

An ADR explains:

- the context and problem;
- the decision;
- alternatives or boundaries;
- positive and negative consequences;
- validation and related engineering artifacts.

Implementation details that can change without architectural impact normally belong in implementation or reference documents rather than a new ADR.

---

# ADR Status Values

| Status | Meaning |
|---|---|
| Draft | Initial decision proposal |
| In Review | Technically developed and awaiting approval |
| Approved | Accepted as the current architectural decision |
| Superseded | Replaced by a later ADR, with history retained |
| Rejected | Considered but not adopted |

Updated ADRs remain In Review until explicit approval.

---

# Decision Index

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](ADR-0001-architecture-driven-engineering.md) | Architecture-Driven Engineering | In Review | 2026-07-31 |
| [ADR-0002](ADR-0002-shared-dns-service-separation.md) | Shared DNS Service Separation | In Review | 2026-08-31 |

---

# When an ADR Is Required

Create or update an ADR when a change:

- establishes or changes a durable component boundary;
- changes ownership of data or lifecycle responsibilities;
- affects multiple capabilities or deployment profiles;
- constrains future implementation choices;
- requires a trade-off that future maintainers must understand.

A bug fix does not automatically require an ADR. It may only be restoring behavior already implied by an existing decision.

---

# ADR Naming

```text
ADR-NNNN-short-title.md
```

Identifiers are sequential and never reused.

---

# ADR Template

```text
# ADR-NNNN - Title

**Status:** Draft | In Review | Approved | Superseded | Rejected

**Date:** YYYY-MM-DD

# Context

# Decision

# Scope and Boundaries

# Consequences

## Positive

## Trade-offs and Risks

# Validation

# Related Documents

# Review Criteria
```

---

# Governance

- Preserve old ADRs for traceability.
- A superseding ADR must reference the decision it replaces.
- Keep status consistent with the Handbook index.
- Link ADRs to related Knowledge Base and Backlog items.
- Do not describe an In Review ADR as approved architecture.
