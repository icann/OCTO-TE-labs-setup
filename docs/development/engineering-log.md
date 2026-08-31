# Engineering Log

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

The Engineering Log records the chronological evolution of OCTO-TE Labs. It preserves objectives, completed work, validation evidence, implementation commits, and the next engineering step.

The Knowledge Base stores durable lessons. The Backlog stores work still to be done. This log records what happened and when.

---

# Entry S-0001 - Architecture Foundation

**Date:** 2026-07-31

**Sprint:** Sprint 0 - Architecture Foundation

**Status:** Completed

## Objective

Establish the engineering methodology and create the Architecture & Engineering Handbook.

## Work Completed

- Created the documentation hierarchy under `docs/`.
- Established Architecture, Reference, Design, Development, Decisions, and Diagrams sections.
- Defined engineering principles and the architecture-driven workflow.
- Established English as the Handbook language.
- Added stable engineering identifiers and document status rules.
- Created ADR-0001, the Knowledge Base, Engineering Log, Engineering Backlog, and initial roadmap.
- Recorded AC-0001 through AC-0004 for later evaluation.

## Outcome

The Handbook became the primary engineering reference and EPIC-001 began with a lifecycle-first analysis of the current platform.

---

# Entry S-0002 - DNS Architecture Restoration and Validation

**Date:** 2026-08-23

**Sprint:** Sprint 1 - Current Implementation Baseline

**Status:** Completed

## Objective

Restore and verify the DNS platform roles before continuing the broader architecture and scalability review.

## Work Completed

- Confirmed `dnsdist` as the public DNS frontend at `100.64.0.53`.
- Restored `ns1` as the platform authoritative service at `100.64.0.54`.
- Separated exercise authority into `auth-exercise` at `.55-.57`.
- Added `auth-rpz` at `.58` and validated RPZ transfer to `resolv1`.
- Preserved the participant-authoritative roles `grpN-soa`, `grpN-ns1`, and `grpN-ns2` for full DNS profiles.
- Verified IPv4 and IPv6 SOA responses through direct group servers and the public frontend.
- Verified RPZ policies including NXDOMAIN, NODATA, local-data rewrite, and DROP.
- Confirmed that participant DNS daemons are activated separately through `do-dns-lab.sh`.

## Validation Evidence

Lab Type 2 was verified with three groups, and `do-dns-lab.sh 2` was used to activate and test Group 2 independently without rebuilding the EC2 host.

## Engineering Decisions

The shared frontend, platform authority, exercise authority, and RPZ authority are separate architectural roles. This decision is formalized in ADR-0002.

## Next Work

Compare current capacity behavior with the original implementation and establish a measurable scalability baseline.

---

# Entry S-0003 - Scalability Audit and 60-Group Baseline

**Date:** 2026-08-23

**Sprint:** Sprint 1 - Current Implementation Baseline

**Status:** Completed

## Objective

Understand the original high-scale design, measure the current implementation, and identify the principal capacity constraints before raising the 64-group limit.

## Historical Comparison

The original implementation:

- prepared host interfaces, routes, kernel limits, and LXC parameters for high scale;
- created per-group bridges and containers during deployment;
- retained the `extra` network;
- was tested with more than 100 full groups and more than 700 containers on a 128 GiB host.

The current implementation retains prepared routes through group 200 but limits orchestration to 64 groups.

## Test Environment

- 8 vCPU threads;
- approximately 59 GiB RAM;
- 10 GiB swap;
- approximately 495 GiB root filesystem;
- Lab Type 1 with 60 groups.

## Verified Final State

- 247 real LXD instances;
- 244 running;
- 3 stopped base templates;
- approximately 30 GiB memory used and 29 GiB available;
- negligible swap use.

The correct instance count was obtained through the LXD API rather than by parsing repeated address rows from default `lxc list` output.

## Key Finding

`dnsdist` incorrectly created 240 group-authoritative downstream objects for a resolver-only profile. With the platform backend, the total was 241 `newServer()` objects, approximately 6.1 GiB RSS, and 263 threads.

## Outcome

The host demonstrated that a 60-group resolver deployment fits in the current test instance, but the result could not be used as a final scale limit because the `dnsdist` configuration was incorrect and full DNS/RPKI profiles have different costs.

## Next Work

Make `dnsdist` generation profile-aware, then repeat controlled scale tests.

---

# Entry S-0004 - CloudFormation Lifecycle Hardening

**Date:** 2026-08-30

**Sprint:** Sprint 1 - Current Implementation Baseline

**Status:** Completed

## Objective

Make concurrent stacks and stack deletion safe, including deployments that fail after CloudFormation reports success.

## Work Completed

### IAM role collision

Removed the fixed `RoleName` from the IPv6 Lambda role so multiple stacks no longer collide on a global IAM role name.

**Commit:** `58d8884` - Avoid IAM role name conflict across lab stacks

### DS cleanup

Added a CloudFormation custom resource that deletes the lab apex DS created by EC2-side automation.

The cleanup is idempotent:

- delete the DS when present;
- return success when absent;
- operate independently of the EC2 instance.

**Commit:** `f37fc40` - Clean up lab DS record on stack deletion

## Validation Evidence

- DS existence was verified directly in Route 53 and through validating resolvers.
- Stack deletion removed DS, NS, glue, and `ec2-` records.
- The same `DnsName` was recreated immediately and published a new valid DS.
- Deletion worked from both the AWS CLI and the CloudFormation console.
- Cleanup also succeeded for a stack whose internal cloud-init failed before completion. That failure occurred before DS publication, validating the no-DS idempotent path.

## Additional Finding

A change set against an older stack attempted to replace the EC2 instance because the `LatestUbuntu` SSM target had moved to a newer AMI.

## Next Work

Provide an optional AMI pinning parameter and continue profile-aware deployment fixes.

---

# Entry S-0005 - Profile-Aware dnsdist, DNS Labels, and AMI Pinning

**Date:** 2026-08-31

**Sprint:** Sprint 1 - Current Implementation Baseline

**Status:** Completed

## Objective

Remove unnecessary resolver-profile resources, support valid DNS labels containing hyphens, and provide a safe AMI override for exceptional stack updates.

## dnsdist Fix

Group authoritative pools are now generated only when `StudentAuth=YES`.

**Commit:** `6cce2d6` - Skip group authoritative dnsdist pools when disabled

### Validation

Lab Type 1, 3 groups:

- 1 `newServer()`;
- 23 threads;
- 39,024 KiB RSS;
- 142,467,072 bytes cgroup memory.

The same EC2 host redeployed internally as Lab Type 2, 3 groups:

- 13 `newServer()` objects;
- 35 threads;
- 358,872 KiB RSS;
- 472,236,032 bytes cgroup memory.

The expected formula for Type 2 is four group backends per group plus one platform backend.

## Hyphenated DNS Names

CloudFormation now accepts lowercase DNS labels containing interior hyphens and rejects invalid leading or trailing hyphens.

**Commit:** `482c8e4` - Allow hyphens in lab DNS names

A `dns-test` stack validated:

- CloudFormation and cloud-init;
- BIND zone loading;
- public A, AAAA, NS, and DS;
- external DNSSEC validation through 1.1.1.1 and 8.8.8.8;
- HTTPS and WebSSH;
- complete Route 53 cleanup.

## AMI Pinning

Added optional `AmiOverride`. It is empty for normal creation and can pin an existing stack to its current AMI during an exceptional update.

**Commit:** `b9ce623` - Allow pinning AMI for stack updates

The template path was validated. A live disposable-stack change-set test remains pending because no suitable existing stack was available.

## Next Work

Reconcile the Handbook with the verified implementation and record the hardening backlog.

---

# Entry S-0006 - Handbook Reconciliation and Hardening Discovery

**Date:** 2026-08-31

**Sprint:** Sprint 1 - Current Implementation Baseline

**Status:** In Progress

## Objective

Replace July placeholders with evidence-based architecture, reference, development, and decision documentation.

## Completed Documentation Batches

### Batch 1 - Core deployment and architecture

**Commit:** `bdf70b3` - Refresh core deployment and architecture documentation

Updated:

- repository operational README;
- Handbook README and changelog;
- deployment flow;
- orchestration architecture;
- current implementation;
- DNS naming;
- Lab Type reference.

### Batch 2 - Network and platform services

**Commit:** `44fd0e5` - Refresh network and platform service documentation

Updated:

- network topology;
- DNS capabilities;
- platform services;
- deployment and network diagrams;
- AWS, LXD, naming, addressing, ports, and software references.

### Batch 3 - Institutional memory and decisions

Updated:

- Knowledge Base;
- Engineering Log;
- Engineering Backlog;
- Roadmap;
- immediate To-do;
- Ideas;
- decisions index;
- ADR-0002.

The batch was validated for metadata, relative links, code fences, identifier consistency, and required engineering evidence.

## Hardening Findings Registered

The documentation audit confirmed:

- no nginx Basic Authentication on the active `webssh.<DOMAIN>` virtual host;
- fixed bootstrap credentials `sysadm:icannws` and `rtradm:icannws` with incomplete rotation;
- invalid TAYGA teardown behavior and non-idempotent iptables cleanup;
- hard-coded WireGuard DNAT on UDP/36456 despite `VPNlistenPort`;
- missing WireGuard ingress in the CloudFormation security group;
- Lab Type 3 `StudentAuthServers`/`StudentAuth` mismatch;
- `RPKIfortX`/`fortX` mismatch in group validator creation;
- excessive and secret-bearing deployment logs;
- external dependency reproducibility risks;
- Jekyll/Bundler/Sass technical debt;
- SOA serials starting at `1`;
- legacy `%KSK_ARN%` workflow substitution;
- group delegations generated even when participant authority is disabled.

## Current Work

Batch 4 will complete navigation, remaining architecture and future-design documents, and final cross-document consistency.

---

# Engineering Log Index

| Entry | Date | Summary | Status |
|---|---|---|---|
| S-0001 | 2026-07-31 | Architecture foundation | Completed |
| S-0002 | 2026-08-23 | DNS architecture restoration and validation | Completed |
| S-0003 | 2026-08-23 | Scalability audit and 60-group baseline | Completed |
| S-0004 | 2026-08-30 | CloudFormation lifecycle hardening | Completed |
| S-0005 | 2026-08-31 | dnsdist, DNS-label, and AMI improvements | Completed |
| S-0006 | 2026-08-31 | Handbook reconciliation and hardening discovery | In Progress |

---

# Review Status

**Current Status:** In Review

**Next Review:** After completion of Batch 4 and the first hardening implementation cycle.
