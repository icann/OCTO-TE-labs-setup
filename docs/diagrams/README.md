# Diagrams

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This directory contains diagrams that support the OCTO-TE Labs Architecture & Engineering Handbook.

Diagrams summarize relationships and flows. The accompanying written documents remain authoritative for qualifications, limitations, ownership, and exact behavior.

---

# Diagrams

| Diagram | Responsibility |
|---|---|
| [`deployment-flow.md`](deployment-flow.md) | Repository publication, CloudFormation, EC2 bootstrap, orchestration, validation, and deletion |
| [`network-topology.md`](network-topology.md) | AWS host, backbone, shared services, group router, and group networks |

Participant-facing topology SVG files under `configs/www/` are operational web assets and are not substitutes for architecture diagrams.

---

# Conventions

- Mermaid is preferred for maintainable Handbook diagrams.
- Node names should match architecture/reference terminology.
- Exact addresses should be linked to reference documents when possible.
- Unverified or future relationships must be labeled.
- Diagrams should not include secrets or account-specific values.
- A diagram change should be reviewed with the written document it represents.

---

# Source-of-Truth Rule

If a diagram conflicts with written architecture or reference documentation, treat the diagram as stale and correct it.

---

# Review Status

**Current Status:** In Review

**Next Review:** When topology, lifecycle order, or capability composition changes.
