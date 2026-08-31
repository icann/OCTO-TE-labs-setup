# Knowledge Base

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

The Knowledge Base is the long-term engineering memory of OCTO-TE Labs.

Architecture documents explain the current structure, reference documents record exact values, ADRs preserve significant decisions, and development documents track work. The Knowledge Base preserves lessons that should remain useful after an individual debugging session, deployment, or sprint has ended.

It records:

- durable architecture knowledge;
- implementation behavior worth preserving;
- historical context;
- operational lessons;
- measured engineering observations;
- architecture candidates that have not yet become decisions.

---

# Scope Boundaries

The Knowledge Base does not replace:

- [`02-deployment-flow.md`](02-deployment-flow.md);
- [`03-orchestrator.md`](03-orchestrator.md);
- [`08-implementation.md`](08-implementation.md);
- Architecture Decision Records under [`../decisions/`](../decisions/README.md);
- the [`Engineering Log`](../development/engineering-log.md);
- the [`Engineering Backlog`](../development/engineering-backlog.md).

A Knowledge Base entry should explain a durable lesson, not duplicate a complete implementation description.

---

# Knowledge Categories

| Category | Purpose |
|---|---|
| Architecture Knowledge | Stable relationships and boundaries in the platform |
| Implementation Knowledge | Verified behavior of the current implementation |
| Historical Knowledge | Context from earlier versions or migrations |
| Engineering Observation | Evidence-based operational or performance findings |

---

# Architecture Candidates

Architecture Candidates are promising ideas that have not been approved through an ADR.

## AC-0001 - Capability-Based Lab Composition

**Status:** Candidate

Future versions could compose labs from selected capabilities instead of relying only on numeric Lab Types.

Candidate capabilities include:

- Recursive DNS;
- Authoritative DNS;
- DNSSEC;
- Universal Acceptance;
- DNS Monitoring;
- BGP;
- Anycast;
- RPKI.

**Planned Review:** EPIC-003

**Related:** AC-0002, AC-0003, [`../design/future-capabilities.md`](../design/future-capabilities.md)

---

## AC-0002 - Capability Taxonomy

**Status:** Candidate

Capabilities could be classified into a stable taxonomy that separates training-domain capabilities from deployment, security, and operational capabilities.

**Planned Review:** EPIC-003

**Related:** AC-0001, [`00-architecture-map.md`](00-architecture-map.md)

---

## AC-0003 - Training Profiles

**Status:** Candidate

Instructor-facing Training Profiles could select a coherent capability set such as Recursive DNS Fundamentals, Authoritative DNS Operations, Secure Routing Fundamentals, Anycast Deployment, or Advanced DNSSEC.

**Planned Review:** EPIC-003

**Related:** AC-0001, AC-0002, [`../design/future-orchestrator.md`](../design/future-orchestrator.md)

---

## AC-0004 - ADR Classification

**Status:** Candidate

If the number of ADRs grows substantially, ADRs could be grouped into foundational, platform, deployment, and capability decisions. The additional classification should not be introduced before it provides clear navigation value.

**Planned Review:** EPIC-003

**Related:** [`../decisions/README.md`](../decisions/README.md)

---

# Engineering Knowledge Index

| Entry | Title | Category | Date |
|---|---|---|---|
| KB-0001 | Capability-Driven Architecture | Architecture Knowledge | 2026-07-31 |
| KB-0002 | Architecture and Implementation Separation | Architecture Knowledge | 2026-07-31 |
| KB-0003 | Lifecycle-Oriented Analysis | Engineering Observation | 2026-07-31 |
| KB-0004 | Handbook as an Engineering Asset | Architecture Knowledge | 2026-07-31 |
| KB-0005 | CloudFormation Completion Is Not Lab Readiness | Implementation Knowledge | 2026-08-30 |
| KB-0006 | Shared DNS Roles Must Remain Separated | Architecture Knowledge | 2026-08-23 |
| KB-0007 | DNS Record Ownership Defines Cleanup Responsibility | Implementation Knowledge | 2026-08-30 |
| KB-0008 | Resource Generation Must Follow Enabled Capabilities | Engineering Observation | 2026-08-31 |
| KB-0009 | LXD Memory Limits Are Ceilings, Not Reservations | Implementation Knowledge | 2026-08-23 |
| KB-0010 | The LXD API Is the Authoritative Instance Inventory | Engineering Observation | 2026-08-23 |
| KB-0011 | Prepared Underlay and On-Demand Group Resources Form a Hybrid Scale Model | Architecture Knowledge | 2026-08-23 |
| KB-0012 | The Original Platform Demonstrated More Than 100 Groups | Historical Knowledge | 2026-08-23 |
| KB-0013 | External Repositories Can Break an Unchanged Deployment | Engineering Observation | 2026-08-31 |
| KB-0014 | A Moving AMI Alias Can Replace an Existing EC2 Instance | Implementation Knowledge | 2026-08-30 |
| KB-0015 | Hyphenated Lab DNS Labels Are Supported End to End | Implementation Knowledge | 2026-08-31 |
| KB-0016 | Provisioned Containers and Exercise-Ready Services Are Different States | Implementation Knowledge | 2026-08-23 |
| KB-0017 | Apex DS and Group DS Records Use Different Control Paths | Implementation Knowledge | 2026-08-31 |
| KB-0018 | Fixed Bootstrap Credentials and an Unprotected WebSSH Frontend Are Priority Risks | Engineering Observation | 2026-08-31 |
| KB-0019 | dnsdist Backend Count Has a Material Resource Cost | Engineering Observation | 2026-08-31 |

---

# Engineering Knowledge

## KB-0001 - Capability-Driven Architecture

**Date:** 2026-07-31

**Category:** Architecture Knowledge

**Summary:** OCTO-TE Labs is organized conceptually around training domains and capabilities rather than around individual software products.

**Related:** [`../decisions/ADR-0001-architecture-driven-engineering.md`](../decisions/ADR-0001-architecture-driven-engineering.md), AC-0001

---

## KB-0002 - Architecture and Implementation Separation

**Date:** 2026-07-31

**Category:** Architecture Knowledge

**Summary:** Architecture describes intended structure. Implementation documents describe the current branch. Future-design documents describe proposed evolution. Keeping these layers separate prevents current shell details from becoming permanent architectural constraints.

**Related:** [`ENGINEERING-PRINCIPLES.md`](ENGINEERING-PRINCIPLES.md), [`08-implementation.md`](08-implementation.md)

---

## KB-0003 - Lifecycle-Oriented Analysis

**Date:** 2026-07-31

**Category:** Engineering Observation

**Summary:** The most reliable way to understand the platform is to trace its complete lifecycle from repository publication through CloudFormation, cloud-init, LXD orchestration, participant activation, internal redeployment, and stack deletion.

**Related:** [`02-deployment-flow.md`](02-deployment-flow.md)

---

## KB-0004 - Handbook as an Engineering Asset

**Date:** 2026-07-31

**Category:** Architecture Knowledge

**Summary:** The Handbook is part of the platform and must evolve with verified implementation behavior. Documentation debt is engineering debt.

**Related:** [`../README.md`](../README.md), [`ENGINEERING-PRINCIPLES.md`](ENGINEERING-PRINCIPLES.md)

---

## KB-0005 - CloudFormation Completion Is Not Lab Readiness

**Date:** 2026-08-30

**Category:** Implementation Knowledge

**Summary:** `CREATE_COMPLETE` confirms AWS resource creation, but the EC2 UserData deployment can still be running or can later fail. Operational readiness requires `cloud-init status --long` to report `done` with no errors and the orchestration log to reach `DEPLOY DONE`.

**Operational Consequence:** Operators must not use CloudFormation status alone as the lab readiness signal.

**Related:** [`02-deployment-flow.md`](02-deployment-flow.md), IMP-0043

---

## KB-0006 - Shared DNS Roles Must Remain Separated

**Date:** 2026-08-23

**Category:** Architecture Knowledge

**Summary:** The verified DNS architecture separates the public frontend, platform authority, exercise authority, and RPZ authority:

```text
dnsdist       100.64.0.53
ns1           100.64.0.54
auth-exercise 100.64.0.55-.57
auth-rpz      100.64.0.58
```

Each role has a different lifecycle and responsibility. Combining them would increase coupling and make exercises, policy service, and public dispatch harder to reason about.

**Related:** [`../decisions/ADR-0002-shared-dns-service-separation.md`](../decisions/ADR-0002-shared-dns-service-separation.md), [`05-dns-capabilities.md`](05-dns-capabilities.md)

---

## KB-0007 - DNS Record Ownership Defines Cleanup Responsibility

**Date:** 2026-08-30

**Category:** Implementation Knowledge

**Summary:** CloudFormation automatically removes records declared as `AWS::Route53::RecordSet`. The lab apex DS is created later by EC2-side automation and therefore requires an independent CloudFormation custom resource for deletion.

**Operational Consequence:** Cleanup must be external to the EC2 so it still works after a failed internal deployment or during EC2 removal.

**Validation:** Create, delete, and immediate recreate with the same DNS name succeeded. Cleanup was also verified from both CLI and console deletion paths.

**Related:** [`02-deployment-flow.md`](02-deployment-flow.md), commit `f37fc40`

---

## KB-0008 - Resource Generation Must Follow Enabled Capabilities

**Date:** 2026-08-31

**Category:** Engineering Observation

**Summary:** Lab Type 1 does not create group authoritative containers. Generating four `dnsdist` backend objects per group anyway created hundreds of nonexistent downstreams. Conditioning those objects on `StudentAuth=YES` removed the unnecessary resource cost.

**Operational Consequence:** Future orchestration should derive service objects from enabled capabilities rather than only from the group count.

**Related:** AC-0001, [`03-orchestrator.md`](03-orchestrator.md), IMP-0050

---

## KB-0009 - LXD Memory Limits Are Ceilings, Not Reservations

**Date:** 2026-08-23

**Category:** Implementation Knowledge

**Summary:** `limits.memory: 2GB` protects the host from one container consuming all memory. It does not reserve 2 GB for every instance. Actual capacity must be evaluated from measured usage, shared kernel behavior, workload, and role-specific limits.

**Operational Consequence:** Global RPKI validators and `dnsdist` can require higher role-specific ceilings without implying equivalent reservation.

**Related:** [`../reference/lxd.md`](../reference/lxd.md), IMP-0055

---

## KB-0010 - The LXD API Is the Authoritative Instance Inventory

**Date:** 2026-08-23

**Category:** Engineering Observation

**Summary:** Parsing the default CSV output of `lxc list` produced false counts because multiple address rows were mistaken for instances. The API endpoint `/1.0/instances` provides one canonical entry per instance.

**Recommended Method:**

```bash
lxc query /1.0/instances | jq 'length'
lxc query '/1.0/instances?recursion=1' | jq -r 'group_by(.status)[] | "\(.[0].status): \(length)"'
```

**Related:** TASK-0050, [`../reference/lxd.md`](../reference/lxd.md)

---

## KB-0011 - Prepared Underlay and On-Demand Group Resources Form a Hybrid Scale Model

**Date:** 2026-08-23

**Category:** Architecture Knowledge

**Summary:** The host prepares routes for a larger design capacity, while LXD bridges and containers are created only for selected groups. This preserves fast expansion without paying the runtime memory cost of pre-creating every container.

**Operational Consequence:** Route capacity, supported group limit, deployed group count, and actual container count are separate concepts and must not be represented by one variable.

**Related:** [`04-network-topology.md`](04-network-topology.md), EPIC-005

---

## KB-0012 - The Original Platform Demonstrated More Than 100 Groups

**Date:** 2026-08-23

**Category:** Historical Knowledge

**Summary:** The original implementation was tested with more than 100 complete groups, representing more than 700 containers, on a host with 128 GiB of RAM. It prepared host networking and high-scale kernel/LXC parameters, then created group bridges and containers during deployment.

**Operational Consequence:** Recovering 100+ group capacity is a demonstrated historical objective, not an arbitrary new target. The current implementation must still be re-benchmarked before claiming equivalent support.

**Related:** EPIC-005, [`../development/roadmap.md`](../development/roadmap.md)

---

## KB-0013 - External Repositories Can Break an Unchanged Deployment

**Date:** 2026-08-31

**Category:** Engineering Observation

**Summary:** An FRRouting repository index temporarily advertised `10.7.1` packages whose referenced files returned HTTP 404. A new deployment failed while the project code was unchanged; a later identical deployment succeeded after the upstream repository became consistent.

**Operational Consequence:** Runtime dependency resolution reduces reproducibility. Pinning, caching, prebaked images, retries, and explicit release manifests should be evaluated during hardening.

**Related:** TD-0041, IDEA-0002

---

## KB-0014 - A Moving AMI Alias Can Replace an Existing EC2 Instance

**Date:** 2026-08-30

**Category:** Implementation Knowledge

**Summary:** `LatestUbuntu` resolves a moving SSM parameter. When the target AMI changes, an unrelated stack update can mark the EC2 instance for replacement because `ImageId` changed.

**Mitigation:** The optional `AmiOverride` parameter can pin an existing stack to its current AMI during an exceptional update. The change set must still be reviewed for other replacement causes.

**Validation Boundary:** Template validation passed. A live disposable-stack update test remains pending.

**Related:** IMP-0042, [`../reference/aws-resources.md`](../reference/aws-resources.md)

---

## KB-0015 - Hyphenated Lab DNS Labels Are Supported End to End

**Date:** 2026-08-31

**Category:** Implementation Knowledge

**Summary:** A lab created with `DnsName=dns-test` completed CloudFormation and cloud-init, loaded the BIND zone, published A/AAAA/NS/DS records, obtained HTTPS certificates, served WebSSH, validated DNSSEC through 1.1.1.1 and 8.8.8.8, and deleted cleanly.

**Operational Consequence:** Hyphens are supported when the label starts and ends with an alphanumeric character. The CloudFormation parameter now enforces that rule.

**Related:** [`../reference/dns-naming.md`](../reference/dns-naming.md)

---

## KB-0016 - Provisioned Containers and Exercise-Ready Services Are Different States

**Date:** 2026-08-23

**Category:** Implementation Knowledge

**Summary:** The platform deployment creates participant DNS containers and topology. The instructor later runs `do-dns-lab.sh` to install and configure BIND, Unbound, and NSD for the exercise.

**Operational Consequence:** A successful Lab Type 1 or Type 2 platform deployment is not proof that every participant DNS daemon is already listening on port 53.

**Related:** [`../reference/lab-types.md`](../reference/lab-types.md)

---

## KB-0017 - Apex DS and Group DS Records Use Different Control Paths

**Date:** 2026-08-31

**Category:** Implementation Knowledge

**Summary:** The DS for the lab apex is written to the parent Route 53 zone. Group DS records are maintained inside the lab's own authoritative zone by `cdsupdate.pl` using authenticated `nsupdate` against `ns1`.

**Operational Consequence:** Route 53 cleanup applies to the lab apex DS, not to group DS records stored inside the deleted lab zone.

**Related:** [`../reference/aws-services.md`](../reference/aws-services.md), [`05-dns-capabilities.md`](05-dns-capabilities.md)

---

## KB-0018 - Fixed Bootstrap Credentials and an Unprotected WebSSH Frontend Are Priority Risks

**Date:** 2026-08-31

**Category:** Engineering Observation

**Summary:** `hostX` is built with `sysadm:icannws`; `rtrX` also creates `rtradm:icannws`. Rotation is not uniform for every copied role. The active `webssh.<DOMAIN>` nginx virtual host also lacks `auth_basic` even though an htpasswd file is generated.

**Operational Consequence:** These are high-priority hardening items and must be fixed before broader production exposure or routing/RPKI recovery.

**Related:** BUG-0040, BUG-0041, [`07-platform-services.md`](07-platform-services.md)

---

## KB-0019 - dnsdist Backend Count Has a Material Resource Cost

**Date:** 2026-08-31

**Category:** Engineering Observation

**Summary:** In the 60-group resolver deployment, the incorrect 241-backend configuration reached about 6.1 GiB RSS and 263 threads. After the profile-aware fix, a 3-group Lab Type 1 deployment used one backend, 23 threads, and about 38 MiB RSS. The same host redeployed as Lab Type 2 used 13 backends, 35 threads, and about 350 MiB RSS.

**Caution:** These measurements demonstrate a strong relationship but do not define a linear per-backend cost or a maximum supported scale.

**Related:** IMP-0050, TASK-0051

---

# Entry Format

New entries use sequential, non-reusable identifiers:

```text
## KB-XXXX - Short Title

**Date:** YYYY-MM-DD

**Category:** Architecture Knowledge | Implementation Knowledge |
Historical Knowledge | Engineering Observation

**Summary:** Durable lesson.

**Operational Consequence:** Optional practical effect.

**Related:** ADRs, tasks, architecture candidates, or documents.
```

---

# Maintenance Policy

- Refine entries when evidence improves; do not silently erase historical context.
- Mark obsolete knowledge as superseded and identify the replacement.
- Move formal decisions into ADRs.
- Move actionable work into the Engineering Backlog.
- Keep measurements tied to their exact test conditions.

---

# Review Status

**Current Status:** In Review

**Next Review:** After the hardening milestone and the next controlled 60/80/100-group benchmark series.
