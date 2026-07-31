# Engineering Roadmap

**Status:** In Review

**Last Updated:** 2026-07-31

---

# Purpose

The Engineering Roadmap describes the expected long-term evolution of the OCTO-TE Labs platform.

It provides strategic direction and identifies the major engineering stages required to understand, restore, improve, and extend the platform.

Detailed tasks and implementation activities are maintained separately in the Engineering Backlog.

---

# Roadmap Principles

The roadmap follows these principles:

- Understand the existing platform before modifying it.
- Preserve working behavior during architectural evolution.
- Restore required capabilities before introducing major redesigns.
- Separate architecture from implementation.
- Organize the platform around training domains and capabilities.
- Keep the Architecture & Engineering Handbook synchronized with the platform.

---

# Milestone M0 — Architecture Foundation

**Status**

Completed

**Objective**

Establish the engineering methodology and documentation foundation required for the long-term evolution of OCTO-TE Labs.

**Outcomes**

- Architecture & Engineering Handbook established.
- Engineering Principles documented.
- Architecture Map created.
- Knowledge Base introduced.
- Architecture Decision Records introduced.
- Engineering Log and Engineering Backlog established.
- Documentation standards and engineering identifiers defined.

---

# EPIC-001 — Understand the Current Architecture

**Status**

In Progress

**Objective**

Develop a complete and evidence-based understanding of the current OCTO-TE Labs platform.

**Expected Outcomes**

- Verified deployment lifecycle.
- Documented orchestration model.
- Current dependency graph.
- Documented network topology.
- Current implementation architecture.
- Platform services identified and documented.
- Engineering knowledge extracted from the implementation.

**Completion Criterion**

The current platform architecture and lifecycle can be understood through the Handbook without requiring the reader to inspect the source code directly.

---

# EPIC-002 — Recover Routing Capability

**Status**

Planned

**Objective**

Restore the routing and secure-routing laboratory functionality that existed in the original implementation.

**Expected Areas of Work**

- Group routers.
- Border router.
- BGP.
- Anycast.
- RPKI infrastructure.
- Participant command-line environments.
- Routing-specific network topology.
- Deployment without unnecessary DNS services.
- Compatibility with the current Ubuntu and container environment.

The detailed scope will be defined after EPIC-001 establishes the current implementation baseline.

---

# EPIC-003 — Platform Evolution

**Status**

Planned

**Objective**

Design the future architectural model of OCTO-TE Labs after the current implementation is fully understood and the required capabilities have been restored.

**Architecture Candidates for Evaluation**

- AC-0001 — Capability-Based Lab Composition.
- AC-0002 — Capability Taxonomy.
- AC-0003 — Training Profiles.
- AC-0004 — ADR Classification.

**Potential Outcomes**

- Capability-driven laboratory composition.
- Clear separation of training domains and platform services.
- Improved orchestration model.
- Explicit configuration of enabled capabilities.
- Reduced dependency on fixed laboratory types.

---

# EPIC-004 — Platform Modernization

**Status**

Planned

**Objective**

Improve maintainability, reliability, observability, and operational efficiency.

**Potential Areas of Work**

- Modular orchestration.
- Improved configuration management.
- Stronger validation and error handling.
- Improved logging.
- Automated testing.
- Deployment verification.
- Platform monitoring.
- Reduced technical debt.
- Improved developer and instructor workflows.

The scope will be refined based on findings from the preceding epics.

---

# Future Expansion

The platform architecture should support the addition of new training capabilities without requiring fundamental redesign.

Potential future capabilities may include:

## DNS

- Additional DNSSEC scenarios.
- DNS privacy technologies.
- Advanced monitoring and troubleshooting.
- Additional Universal Acceptance exercises.

## Routing

- Additional BGP operational practices.
- Advanced Anycast scenarios.
- Routing security practices beyond RPKI.
- Additional routing policy exercises.

## Additional Training Domains

New domains may be introduced when they align with the purpose of the platform and can be integrated through the capability-oriented architectural model.

---

# Roadmap Governance

The roadmap should be reviewed:

- after completion of each epic;
- when a major Architecture Decision Record is approved;
- when project priorities change;
- when new capabilities are formally proposed.

Changes to priorities or scope should be reflected in both the roadmap and the Engineering Backlog.

---

# Review Status

**Current Status**

In Review

**Next Review**

After completion of EPIC-001.