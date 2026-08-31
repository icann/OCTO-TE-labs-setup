# ADR-0001 - Architecture-Driven Engineering

**Status:** In Review

**Date:** 2026-07-31

**Last Reviewed:** 2026-08-31

---

# Context

OCTO-TE Labs has evolved through multiple implementations and operational requirements.

The platform must support additional training capabilities, large workshops, changing software, current cloud environments, and safe operational lifecycles without allowing every implementation change to redefine the architecture.

The project also needs durable engineering memory so future contributors can understand not only how the platform works, but why decisions were made.

---

# Decision

The project adopts an **Architecture-Driven Engineering** approach.

The Architecture & Engineering Handbook is the primary engineering reference for the project.

Architectural concepts and decisions define the intended long-term structure. Implementation work realizes that structure and provides evidence for future refinement.

---

# Principles Established

## Architecture before implementation

Architecture defines responsibilities, relationships, boundaries, and desired qualities.

Implementation defines the current technologies, scripts, resources, and configuration used to realize them.

## Capability-oriented design

The platform is organized around training domains and capabilities rather than products or numeric Lab Types.

Current fixed profiles remain valid implementation and compatibility mechanisms, but they do not define the final architecture.

## Evidence-based engineering

Claims and decisions are supported by source analysis, deployment evidence, measurements, requirements, or reviewed design.

Assumptions and intended behavior are labeled explicitly.

## Documentation as an engineering artifact

Documentation evolves with implementation, validation, decisions, and accumulated knowledge.

## Separation of concerns

Current architecture, current implementation, exact reference values, future design, decisions, and development history are maintained in separate document classes.

## Lifecycle, security, and scalability

Create/delete ownership, failure cleanup, public access control, credential handling, dependency reproducibility, and measured capacity are architectural concerns rather than optional implementation polish.

---

# Consequences

## Positive

- A stable conceptual model can survive implementation changes.
- Current behavior and future proposals are less likely to be confused.
- Significant decisions remain traceable.
- Onboarding and review become easier.
- Operational discoveries can become durable project knowledge.
- Security, lifecycle, and scalability findings have a defined place in engineering work.
- The original implementation can be compared with the current branch without treating either as the architecture itself.

## Trade-offs

- Documentation and cross-reference maintenance require sustained effort.
- Changes can require updates to several engineering artifacts.
- Incomplete evidence can delay strong support claims.
- Future designs remain Draft until they receive review and, when appropriate, an ADR.
- Architecture discipline can feel slower than direct script modification, but reduces long-term drift and rework.

---

# Implementation of the Decision

The Handbook now contains:

- architecture documents;
- exact technical references;
- ADRs;
- future-design proposals;
- Engineering Log and Backlog;
- Roadmap, To-do, and Ideas;
- Knowledge Base;
- diagrams and section indexes.

The 2026-08-31 reconciliation demonstrated the intended workflow by:

- deriving current behavior from code and deployment tests;
- documenting confirmed defects rather than hiding them;
- separating verified DNS support from unverified routing support;
- formalizing shared DNS-service separation in ADR-0002;
- recording deferred hardening work in the backlog;
- preserving measured scalability evidence and uncertainty.

---

# Alternatives Considered

## Implementation-driven documentation

Document only the current scripts and allow their structure to define the platform.

Rejected because temporary shell and cloud details would become accidental architecture.

## Documentation only after major releases

Rejected because long debugging and refactoring periods would create undocumented behavior and lost engineering knowledge.

## Minimal operational README only

Rejected because operational steps alone cannot preserve architecture, rationale, future design, technical debt, and measured evidence.

---

# Related Documents

- [`../README.md`](../README.md)
- [`../architecture/ENGINEERING-PRINCIPLES.md`](../architecture/ENGINEERING-PRINCIPLES.md)
- [`../architecture/00-architecture-map.md`](../architecture/00-architecture-map.md)
- [`../architecture/KNOWLEDGE-BASE.md`](../architecture/KNOWLEDGE-BASE.md)
- [`ADR-0002-shared-dns-service-separation.md`](ADR-0002-shared-dns-service-separation.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)
- [`../development/engineering-log.md`](../development/engineering-log.md)

---

# Related Knowledge

- KB-0001 - Capability-Driven Architecture
- KB-0002 - Architecture and Implementation Separation
- KB-0003 - Lifecycle-Oriented Analysis
- KB-0004 - Handbook as an Engineering Asset

---

# Review Criteria

Promote this ADR to Approved only after:

- maintainers explicitly accept the Handbook as the engineering reference;
- status and artifact responsibilities are reviewed;
- the hardening phase demonstrates continued synchronization between code, evidence, backlog, and documentation;
- no conflicting engineering-governance model remains in active use.

---

# Future Reviews

Review this ADR when:

- the project adopts a substantially different governance model;
- capability-driven orchestration is formalized through a later ADR;
- the Handbook is replaced by another authoritative engineering system.

Implementation changes alone do not require revisiting the decision.
