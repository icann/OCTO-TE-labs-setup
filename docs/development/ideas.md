# Engineering Ideas

**Status:** Draft

**Last Updated:** 2026-08-31

---

# Purpose

This document collects early ideas that are not yet mature enough to become backlog commitments, architecture candidates, or ADRs.

An idea may be promoted when it has:

- a clear problem statement;
- evidence that the problem matters;
- an identified owner or milestone;
- defined acceptance criteria;
- no unresolved conflict with an ADR.

Ideas are not promises and should not be documented as current behavior.

---

# IDEA-0001 - Versioned Deployment Release Manifest

Publish a small manifest with each S3 deployment containing:

- Git commit;
- rendered template checksum;
- Ubuntu AMI resolution;
- external repository channels and package versions;
- participant-instructions commit;
- deployment timestamp.

This could make two lab deployments comparable even when external dependencies move.

---

# IDEA-0002 - Dependency Snapshot or Mirror

Evaluate a controlled package/artifact cache for FRR, PowerDNS, BIND, FORT, Ruby gems, and instruction archives. The objective would be reproducible workshops without permanently forking every upstream repository.

---

# IDEA-0003 - Declarative Role Inventory

Create one machine-readable inventory describing:

- role name;
- template source;
- required capabilities;
- network attachments;
- addresses;
- packages;
- ports;
- memory limits;
- dependencies;
- validation checks.

Documentation, orchestration, diagrams, and tests could consume the same inventory.

---

# IDEA-0004 - Automated End-to-End Validation Runner

Build a validation tool that can run after deployment and report:

- cloud-init completion;
- expected LXD instances and states;
- service status;
- direct and public DNS tests;
- DNSSEC AD validation;
- HTTPS/WebSSH checks;
- Route 53 ownership and cleanup checks;
- resource usage snapshots.

A failure-injection mode could stop a deployment at selected phases and validate cleanup behavior.

---

# IDEA-0005 - Controlled Scale Test Harness

Automate progressive deployments at 3, 10, 30, 60, 80, 100, and higher group counts. Record CPU, memory, swap, storage, process/thread count, LXD state, dnsdist backends, and elapsed deployment time in a versioned result set.

---

# IDEA-0006 - Capacity-Aware Instance Recommendation

Use measured profile costs to recommend an EC2 instance type based on:

- Lab Type/capabilities;
- group count;
- RPKI mode;
- expected traffic;
- safety margin.

This should be evidence-based rather than a static rule copied into the README.

---

# IDEA-0007 - Immutable Base Templates

Instead of installing all base packages during every stack creation, publish versioned LXD images or an EC2 AMI containing validated base templates. Workshop-specific topology would remain dynamic.

The idea must be evaluated against image maintenance, security patching, region replication, and rollback complexity.

---

# IDEA-0008 - DNS Backend Transport Policy

Evaluate whether full DNS profiles need both IPv4 and IPv6 backend objects for every group server or whether selected training profiles could expose dual-stack frontends while using one internal transport family.

The current decision is to retain both backend families for Lab Type 2. Any alternative would require an explicit training and resilience rationale.

---

# IDEA-0009 - Dynamic ULA Allocation Service

Generate and persist a per-deployment RFC 4193 ULA prefix, then render addressing, routes, instructions, and diagrams from that value. Include collision checks and a stable way to recover the prefix during internal redeployment.

---

# IDEA-0010 - Structured Concurrency in Orchestration

Identify independent deployment phases that can run concurrently under bounded parallelism. Preserve deterministic logs, dependency ordering, failure cancellation, and cleanup.

This should be evaluated only after lifecycle functions become idempotent.

---

# IDEA-0011 - Generated Documentation from Verified Inventory

Generate selected reference tables and diagrams from a machine-readable inventory, while keeping explanatory architecture prose hand-maintained. This could reduce drift in addresses, ports, roles, and profile matrices.

---

# IDEA-0012 - Self-Service Lab Health Page

Publish an operator-only health page containing non-secret status for:

- cloud-init;
- LXD instance counts;
- shared services;
- certificate validity;
- DNSSEC chain;
- disk/memory pressure;
- last validation run.

The page must not expose credentials, internal tokens, or unnecessary network details.

---

# Review Policy

Review ideas during roadmap or architecture planning. Promote mature ideas into the Backlog or Architecture Candidates; mark rejected ideas with a brief rationale rather than silently deleting them.
