# Architecture

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This directory contains the conceptual and current-state architecture documentation for OCTO-TE Labs.

Architecture documents explain stable responsibilities and relationships. Exact values belong in [`../reference/`](../reference/README.md), significant decisions belong in [`../decisions/`](../decisions/README.md), and unimplemented proposals belong in [`../design/`](../design/README.md).

---

# Documents

| Document | Responsibility |
|---|---|
| [`00-architecture-map.md`](00-architecture-map.md) | Conceptual platform map and Handbook entry point |
| [`01-overview.md`](01-overview.md) | Purpose, goals, current scope, and audience |
| [`02-deployment-flow.md`](02-deployment-flow.md) | End-to-end deployment and deletion lifecycle |
| [`03-orchestrator.md`](03-orchestrator.md) | Current shell orchestration model |
| [`04-network-topology.md`](04-network-topology.md) | Backbone, group networks, addressing relationships, and scale model |
| [`05-dns-capabilities.md`](05-dns-capabilities.md) | DNS capabilities and verified current behavior |
| [`06-routing-capabilities.md`](06-routing-capabilities.md) | Routing, Anycast, and RPKI architecture and recovery state |
| [`07-platform-services.md`](07-platform-services.md) | Shared host and platform services |
| [`08-implementation.md`](08-implementation.md) | Map of the current `nico` branch implementation |
| [`ENGINEERING-PRINCIPLES.md`](ENGINEERING-PRINCIPLES.md) | Engineering and documentation rules |
| [`KNOWLEDGE-BASE.md`](KNOWLEDGE-BASE.md) | Durable engineering lessons and architecture candidates |

---

# Reading Order

For a first review:

1. Architecture Map;
2. Platform Overview;
3. Deployment Flow;
4. Orchestrator;
5. Network Topology;
6. DNS or Routing Capabilities;
7. Platform Services;
8. Current Implementation;
9. Knowledge Base.

---

# Source-of-Truth Boundaries

- Architecture documents define responsibilities and relationships.
- `08-implementation.md` describes the current branch.
- Reference documents define exact names and values.
- ADRs define reviewed decisions.
- Design documents define future proposals.
- The source code and deployment evidence remain authoritative for behavior not yet reconciled into the Handbook.

---

# Review Status

**Current Status:** In Review

**Next Review:** When hardening or routing recovery changes the architectural baseline.
