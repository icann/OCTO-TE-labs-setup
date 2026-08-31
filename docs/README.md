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
- future design proposals;
- engineering history, backlog, roadmap, and accumulated knowledge.

Participant-facing exercises are maintained separately. The repository root [`README.md`](../README.md) is the operational deployment guide.

---

# Documentation Principles

The Handbook follows these principles:

- Architecture drives engineering.
- Capabilities drive architecture.
- Current behavior is documented from evidence.
- Current implementation, future design, and historical context remain separate.
- Significant decisions are preserved as ADRs.
- Known limitations are documented rather than hidden.
- Every document has one primary responsibility.
- Security, cleanup, reproducibility, and scalability are architecture concerns.

Detailed principles are in [`architecture/ENGINEERING-PRINCIPLES.md`](architecture/ENGINEERING-PRINCIPLES.md).

---

# Handbook Organization

| Section | Responsibility |
|---|---|
| [`architecture/`](architecture/README.md) | Conceptual architecture, deployment, orchestration, networks, capabilities, services, implementation, principles, and knowledge base |
| [`reference/`](reference/README.md) | Exact names, addresses, ports, AWS resources, software, container platform, and lab profiles |
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
5. [`architecture/04-network-topology.md`](architecture/04-network-topology.md)
6. [`architecture/08-implementation.md`](architecture/08-implementation.md)
7. [`architecture/KNOWLEDGE-BASE.md`](architecture/KNOWLEDGE-BASE.md)

## Operator preparing a lab

1. [`../README.md`](../README.md)
2. [`reference/lab-types.md`](reference/lab-types.md)
3. [`reference/dns-naming.md`](reference/dns-naming.md)
4. [`reference/network-addressing.md`](reference/network-addressing.md)
5. [`reference/ports.md`](reference/ports.md)
6. [`architecture/02-deployment-flow.md`](architecture/02-deployment-flow.md)

## Engineer planning a change

1. [`architecture/ENGINEERING-PRINCIPLES.md`](architecture/ENGINEERING-PRINCIPLES.md)
2. [`decisions/`](decisions/README.md)
3. [`development/engineering-backlog.md`](development/engineering-backlog.md)
4. [`architecture/KNOWLEDGE-BASE.md`](architecture/KNOWLEDGE-BASE.md)
5. [`design/`](design/README.md)
6. the affected implementation files

## Routing and RPKI recovery

1. [`architecture/06-routing-capabilities.md`](architecture/06-routing-capabilities.md)
2. [`reference/lab-types.md`](reference/lab-types.md)
3. [`design/future-routing.md`](design/future-routing.md)
4. [`development/engineering-backlog.md`](development/engineering-backlog.md)
5. [`reference/ports.md`](reference/ports.md)

---

# Current Verified Implementation Baseline

The 2026-08-31 reconciliation is based on the `nico` branch through implementation commit `b9ce623` and on end-to-end deployment tests completed during August 2026.

The verified baseline includes:

- CloudFormation provisioning of a dual-stack EC2 lab host;
- separate shared DNS roles for frontend, platform authority, exercise authority, and RPZ distribution;
- Lab Type 1 and Lab Type 2 deployment and internal redeployment;
- IPv4 and IPv6 DNS service;
- DNSSEC key generation, DS publication, external validation, and stack-delete cleanup;
- HTTPS and WebSSH publication;
- optional shared `labuser` password;
- DNS labels containing hyphens;
- an optional AMI pinning mechanism for deliberate stack updates; the template path is validated, while live update-change-set validation remains pending;
- resolver scalability testing at 60 groups;
- documentation of the original implementation's demonstrated operation above 100 groups.

Routing profiles, RPKI profiles, higher group counts, NAT64 lifecycle, WebSSH access control, credential hardening, and external dependency reproducibility remain active engineering work.

---

# Documentation Status

## Handbook Root

| Document | Status |
|---|---|
| Handbook README | In Review |
| [Handbook Changelog](CHANGELOG.md) | In Review |

## Architecture

| Document | Status |
|---|---|
| Architecture Map | In Review |
| Platform Overview | In Review |
| Deployment Flow | In Review |
| Orchestration Architecture | In Review |
| Network Topology | In Review |
| DNS Capabilities | In Review |
| Routing Capabilities | In Review |
| Platform Services | In Review |
| Current Implementation | In Review |
| Engineering Principles | In Review |
| Knowledge Base | In Review |

## Reference

| Document | Status |
|---|---|
| Acronyms | In Review |
| AWS Resources | In Review |
| AWS Services | In Review |
| Container Naming | In Review |
| DNS Naming | In Review |
| Laboratory Profiles and Types | In Review |
| Container Platform Reference | In Review |
| Network Addressing | In Review |
| Ports and Protocols | In Review |
| Software Stack | In Review |

## Decisions

| Document | Status |
|---|---|
| ADR-0001 - Architecture-Driven Engineering | In Review |
| ADR-0002 - Shared DNS Service Separation | In Review |

## Future Design

| Document | Status |
|---|---|
| Future Capabilities | Draft |
| Future Modularity | Draft |
| Future Orchestrator | Draft |
| Future Routing Architecture | Draft |

## Development and Diagrams

| Document | Status |
|---|---|
| Engineering Log | In Review |
| Engineering Backlog | In Review |
| Roadmap | In Review |
| Immediate To-do | In Review |
| Ideas | Draft |
| Deployment Flow Diagram | In Review |
| Network Topology Diagram | In Review |

Updated documents remain **In Review** until explicit approval. Future designs remain **Draft** until a proposal is reviewed and accepted through the appropriate decision process.

---

# Document Status Lifecycle

| Status | Meaning |
|---|---|
| Draft | Initial content or future design that is not yet accepted as the current reference |
| In Review | Technically developed and awaiting review or approval |
| Approved | Accepted as the current reference |
| Deprecated | Retained for historical reasons but no longer current |

ADRs additionally use `Superseded` and `Rejected` as described in [`decisions/README.md`](decisions/README.md).

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

For an implementation change:

1. establish current behavior from code and tests;
2. identify the architectural and security impact;
3. record or update relevant decisions and backlog items;
4. implement the smallest coherent change;
5. validate intended behavior, failure behavior, and cleanup;
6. update architecture, reference, log, backlog, and changelog as appropriate.

---

# Current Engineering Sequence

The agreed sequence after the August 2026 DNS and lifecycle validation is:

1. perform deployment and security hardening;
2. recover and quantify higher scalability;
3. continue routing and RPKI recovery;
4. advance capability-driven orchestration design.

The documentation reconciliation represented by Batches 1-4 is complete and establishes the baseline for the hardening phase. Baseline documents remain In Review until explicit technical approval; that governance review does not block beginning hardening. A production-blocking defect can still interrupt this sequence.

---

# Scope Boundaries

The Handbook intentionally distinguishes:

- **Architecture:** stable structure and relationships;
- **Implementation:** how the current branch realizes that architecture;
- **Reference:** exact names, addresses, ports, software, and profile mappings;
- **Design:** future proposals;
- **Decisions:** reviewed rationale and consequences;
- **Development:** chronology and work planning;
- **Training material:** participant exercises maintained outside this Handbook.

---

# Review Status

**Current Status:** In Review

**Next Review:** After the deployment and security hardening phase begins and the first resulting implementation changes are reconciled.
