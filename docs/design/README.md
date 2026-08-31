# Design

**Status:** Draft

**Last Updated:** 2026-08-31

---

# Purpose

This directory contains future architecture and engineering proposals for OCTO-TE Labs.

Design documents are not descriptions of current behavior. They identify target qualities, candidate models, migration approaches, open questions, and acceptance criteria.

---

# Documents

| Document | Responsibility |
|---|---|
| [`future-capabilities.md`](future-capabilities.md) | Candidate capability model, metadata, lifecycle, and profile composition |
| [`future-modularity.md`](future-modularity.md) | Target module boundaries, contracts, configuration separation, and migration |
| [`future-orchestrator.md`](future-orchestrator.md) | Candidate capability-driven planning and lifecycle orchestration model |
| [`future-routing.md`](future-routing.md) | Target routing/Anycast/RPKI architecture and recovery gates |

---

# Design Rules

A design document must:

- use Draft status until reviewed;
- distinguish required outcomes from optional implementation choices;
- reference current-state evidence and backlog items;
- define migration and backward-compatibility considerations;
- identify security, lifecycle, validation, and capacity requirements;
- avoid claiming that proposed behavior already exists.

A significant accepted design should normally be formalized through an ADR before becoming the architecture baseline.

---

# Design Lifecycle

```text
Engineering finding or idea
    -> Draft design
    -> review and experiments
    -> ADR or explicit rejection
    -> implementation plan
    -> validation
    -> architecture/reference update
```

---

# Current Direction

The current design direction is:

- preserve proven deployment and topology behavior;
- make security and cleanup explicit;
- compose labs from capabilities and named profiles;
- reduce global shell coupling through module contracts;
- recover routing and RPKI before claiming production support;
- recover higher scale through measurement rather than assumption.

---

# Review Status

**Current Status:** Draft

**Next Review:** During EPIC-003 after hardening and routing-recovery evidence is available.
