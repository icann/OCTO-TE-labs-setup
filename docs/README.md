# OCTO-TE Labs Architecture & Engineering Handbook

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

The OCTO-TE Labs Architecture & Engineering Handbook is the primary engineering reference for the OCTO-TE Labs platform.

It documents:

- the conceptual architecture;
- the verified deployment and orchestration lifecycle;
- the current implementation;
- stable technical reference information;
- architecture decisions;
- future design;
- engineering history, backlog, and accumulated knowledge.

Participant-facing exercises are maintained separately. The repository root [`README.md`](../README.md) is the operational deployment guide.

---

# Documentation Principles

The Handbook follows these principles:

- Architecture drives engineering.
- Capabilities drive architecture.
- Documentation evolves with verified implementation behavior.
- Current behavior, future design, and historical work remain separate.
- Significant decisions are preserved as ADRs.
- Known limitations are documented rather than hidden.
- A document should have one primary responsibility.

Detailed principles are in [`architecture/ENGINEERING-PRINCIPLES.md`](architecture/ENGINEERING-PRINCIPLES.md).

---

# Handbook Organization

| Section | Responsibility |
|---|---|
| [`architecture/`](architecture/README.md) | Conceptual architecture, deployment, orchestration, networks, capabilities, services, implementation, and knowledge base |
| [`reference/`](reference/README.md) | Stable names, addresses, ports, AWS resources, software, and lab profile reference |
| [`decisions/`](decisions/README.md) | Architecture Decision Records |
| [`design/`](design/README.md) | Proposed future architecture that is not yet the current implementation |
| [`development/`](development/README.md) | Engineering log, backlog, roadmap, ideas, and immediate tasks |
| [`diagrams/`](diagrams/README.md) | Diagrams that support the written documentation |

---

# Recommended Reading Paths

## New maintainer

1. [`architecture/00-architecture-map.md`](architecture/00-architecture-map.md)
2. [`architecture/01-overview.md`](architecture/01-overview.md)
3. [`architecture/02-deployment-flow.md`](architecture/02-deployment-flow.md)
4. [`architecture/03-orchestrator.md`](architecture/03-orchestrator.md)
5. [`architecture/08-implementation.md`](architecture/08-implementation.md)
6. [`architecture/KNOWLEDGE-BASE.md`](architecture/KNOWLEDGE-BASE.md)

## Operator preparing a lab

1. [`../README.md`](../README.md)
2. [`reference/lab-types.md`](reference/lab-types.md)
3. [`reference/dns-naming.md`](reference/dns-naming.md)
4. [`reference/network-addressing.md`](reference/network-addressing.md)
5. [`reference/ports.md`](reference/ports.md)

## Engineer planning a change

1. [`architecture/ENGINEERING-PRINCIPLES.md`](architecture/ENGINEERING-PRINCIPLES.md)
2. [`decisions/`](decisions/README.md)
3. [`development/engineering-backlog.md`](development/engineering-backlog.md)
4. [`design/`](design/README.md)
5. the implementation files affected by the change

---

# Current Verified Implementation Baseline

The 2026-08-31 reconciliation is based on the `nico` branch through implementation commit `b9ce623` and on end-to-end deployment tests completed during August 2026.

The verified baseline includes:

- CloudFormation provisioning of a dual-stack EC2 lab host;
- separate shared DNS roles for frontend, platform authority, exercise authority, and RPZ distribution;
- Lab Type 1 and Lab Type 2 deployment and internal redeployment;
- IPv4 and IPv6 DNS service;
- DNSSEC key generation, DS publication, external validation, and stack-delete cleanup;
- HTTPS and WebSSH for the lab domain;
- optional shared `labuser` password;
- DNS labels containing hyphens;
- an optional AMI pinning mechanism for deliberate stack updates; the template path is validated, while live update-change-set validation remains pending;
- resolver scalability testing at 60 groups.

Routing profiles, RPKI profiles, higher group counts, NAT64 lifecycle, and deployment hardening remain active engineering work.

---

# Documentation Status

## Handbook Root

| Document | Status |
|---|---|
| Handbook README | In Review |
| Handbook Changelog | In Review |

## Architecture

| Document | Status |
|---|---|
| Architecture Map | In Review |
| Platform Overview | In Review |
| Deployment Flow | In Review |
| Orchestration Architecture | In Review |
| Network Topology | Draft |
| DNS Capabilities | Draft |
| Routing Capabilities | Draft |
| Platform Services | Draft |
| Current Implementation | In Review |
| Engineering Principles | In Review |
| Knowledge Base | In Review |

## Reference

| Document | Status |
|---|---|
| Acronyms | Draft |
| AWS Resources | Draft |
| AWS Services | Draft |
| Container Naming | Draft |
| DNS Naming | In Review |
| Laboratory Profiles and Types | In Review |
| Container Platform Reference | Draft |
| Network Addressing | Draft |
| Ports and Protocols | Draft |
| Software Stack | Draft |

## Decisions

| Document | Status |
|---|---|
| ADR-0001 - Architecture-Driven Engineering | In Review |
| ADR-0002 - Shared DNS Service Separation | Planned for the current documentation refresh |

## Design, Development, and Diagrams

The design documents remain proposals. Development records and diagrams are being reconciled with the verified implementation in subsequent documentation batches.

---

# Document Status Lifecycle

| Status | Meaning |
|---|---|
| Draft | Initial content or future design that is not yet accepted as the current reference |
| In Review | Technically developed and awaiting review or approval |
| Approved | Accepted as the current reference |
| Deprecated | Retained for historical reasons but no longer current |

Updated documents remain **In Review** until explicit approval.

---

# Engineering Workflow

```text
Idea
  -> Architecture
  -> Documentation
  -> Analysis
  -> Implementation
  -> Validation
  -> Knowledge Base
  -> Release
```

For an implementation change:

1. Establish current behavior from code and tests.
2. Identify the architectural impact.
3. Record or update the relevant decision and backlog entries.
4. Implement the smallest coherent change.
5. Validate both the intended behavior and cleanup/failure behavior.
6. Update architecture, reference, log, backlog, and changelog as appropriate.

---

# Current Engineering Sequence

The agreed work sequence after the August 2026 DNS and lifecycle validation is:

1. reconcile the Handbook with the verified implementation;
2. perform deployment and wipe hardening;
3. recover and quantify higher scalability;
4. continue routing and RPKI recovery;
5. advance capability-driven orchestration design.

This sequence can change when a production-blocking defect requires immediate attention.

---

# Scope Boundaries

The Handbook intentionally distinguishes:

- **Architecture:** stable structure and relationships;
- **Implementation:** how the current branch realizes that architecture;
- **Reference:** exact names, addresses, ports, and profile mappings;
- **Design:** future proposals;
- **Decisions:** accepted or reviewed rationale;
- **Development:** chronology and work planning;
- **Training material:** participant exercises maintained outside this Handbook.

---

# Review Status

**Current Status:** In Review

**Next Review:** After completion of the 2026-08-31 documentation reconciliation batches.
