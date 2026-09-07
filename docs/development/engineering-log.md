# Engineering Log

**Status:** In Review

**Last Updated:** 2026-09-07

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

**Status:** Completed

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

**Commit:** `d273970` - Refresh engineering records and add DNS service ADR

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

### Batch 4 - Architecture completion, future design, and navigation

Updated:

- Architecture Map and Platform Overview;
- Routing Capabilities;
- Engineering Principles;
- ADR-0001 review metadata and cross references;
- future capability, modularity, orchestrator, and routing designs;
- section navigation READMEs;
- acronym reference;
- Handbook status and changelog summaries.

The complete Handbook was validated for global metadata, relative links, code fences, placeholder removal, index coverage, identifier consistency, and current-phase state.

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

## Outcome

The four-batch Handbook reconciliation is complete. Current-state documents are substantive and remain In Review pending technical approval; future-design documents remain Draft. The resulting baseline is sufficient to begin deployment and security hardening.

## Current Work

EPIC-004 deployment and security hardening is now the active engineering phase, beginning with WebSSH access control and elimination of fixed bootstrap credentials.

---

# Entry S-0007 - Integrated Instructions and CloudFormation Operator UX

**Date:** 2026-09-01

**Sprint:** EPIC-004 - Deployment and Security Hardening

**Status:** Completed

## Objective

Make integrated participant instructions optional, improve the CloudFormation creation experience, clarify DNS-name validation, and verify the complete lifecycle before beginning the primary EPIC-004 security work.

## Work Completed

- Added `IntegratedInstructions=YES/NO` independently of numeric Lab Type.
- Preserved the integrated archive source as the separate `labInstructions` parameter.
- Made `NO` omit the group-page link, skip the Jekyll pipeline, and remove the reserved per-group instruction path.
- Added backward-compatible defaulting to `YES` for older configuration files.
- Grouped and labeled all twelve CloudFormation parameters by operator task.
- Verified a Quick Create path with editable `LAB-YYYYMMDD-LOCATION` prefill; the URL does not encode a stack region, so the active CloudFormation console region controls deployment.
- Clarified the 3-32 character `DnsName` policy and complete constraint message.

## Implementation Commits

- `0a8832c` - Add optional integrated lab instructions.
- `6793da4` - Group CloudFormation deployment parameters.
- `51e3d71` - Clarify DNS name validation guidance.
- `dc719a4` - Include DNS name length in validation message.

## Validation Evidence

### IntegratedInstructions=NO

A three-group Lab Type 1 deployment completed with `cloud-init` status `done` and no errors. The generated configuration contained `IntegratedInstructions="NO"`; no group instruction directories or links existed, and the instruction/Jekyll log markers were absent.

### IntegratedInstructions=YES

A matching three-group Lab Type 1 deployment completed cleanly. All three group instruction directories and links existed, and the instruction-generation start and completion markers appeared in the cloud-init log.

### Lifecycle and DNS

The lab deployment for `testing.te-labs.training` was deleted and recreated with the same DNS name. The new deployment restored A, AAAA, NS, DS, HTTPS, and a valid DNSSEC chain. A workstation resolver briefly returned AAAA but no A before converging; 1.1.1.1, 8.8.8.8, and the authoritative trace were correct. The test did not isolate the resolver's internal caching mechanism.

### DnsName and Console UX

- `in` was rejected by the 3-character minimum.
- `-testing` was rejected by the label syntax.
- `in-nico` was accepted.
- The final message describes length, allowed characters, and start/end requirements.
- Quick Create displayed the grouped form and pre-filled `LAB-YYYYMMDD-LOCATION`.

## Additional Findings

- `--deploy` performs `wipe` before the empty enabled-instruction source check inside `deploy()`.
- `IntegratedInstructions=NO` removes the per-group instruction path without an ownership marker.
- The publication workflow declares S3 region `us-east-2`, while the current `nico` bucket reports `us-east-1`.

## Documentation

**Commit:** `9e37720` - Document integrated instructions and deployment UX

The operational README and current-state architecture/reference documents were updated before this institutional-record batch.

## Outcome

The optional instruction capability and CloudFormation operator UX are validated. The newly discovered lifecycle and publication issues are registered for EPIC-004 rather than hidden by the successful functional tests.

## Next Work

Begin EPIC-004 with the agreed critical security work: protect the active WebSSH endpoint and eliminate fixed bootstrap credentials. Address destructive preflight ordering as part of lifecycle hardening.

---

# Entry S-0008 - Identity Platform Foundation and Deployment Reporting Policy

**Date:** 2026-09-07

**Sprint:** EPIC-004 - Deployment and Security Hardening

**Status:** Completed

## Objective

Create and validate the isolated `identity-platform` foundation before installing identity software, and define the deployment-reporting and software-freshness policy that will govern reproducible Foundation 1B installations.

## Architecture Decisions

- Added ADR-0003 for unified lab identity and access.
- Reserved `identity-platform` at `100.64.0.60` and `fd89:59e0:0::60`.
- Preserved `webssh.<DOMAIN>` as a separate virtual host.
- Added ADR-0004 for complete deployment reporting, software/image freshness checks, preserved failure status, secret exclusion, and non-mutating update guidance.
- Fixed the generic update recommendation as: `Test available updates in a dedicated disposable VM before updating the pinned versions.`

## Implementation Commits

- `9e29b7e` - Add unified lab identity architecture decision.
- `4a97447` - Add identity platform foundation lifecycle.
- `cfe4c5b` - Harden identity platform foundation.

## Foundation 1A Work Completed

- Created `identityX` directly from the clean local Ubuntu image instead of inheriting `hostX`.
- Created `identity-platform` as a shared LXC instance with static IPv4 and IPv6 addresses.
- Integrated create, validate, start, stop, delete, wipe, and redeploy lifecycle behavior.
- Enforced the 2 GB LXD memory ceiling inherited from the default profile.
- Locked and expired the image-provided `ubuntu` account, set `nologin`, removed supplementary groups and sudoers access, removed active authorized keys, masked SSH service and socket activation, and verified TCP/22 remains closed.
- Reapplied the hardening baseline after clone-specific cloud-init execution.
- Added explicit validation failure propagation so create/start cannot report false success.

## Validation Evidence

A disposable three-group Lab Type 1 stack with integrated instructions disabled validated:

- fresh CloudFormation and cloud-init completion with no errors;
- `identityX` stopped and `identity-platform` running;
- 21 LXD instances, including the template and shared identity service;
- correct hostname, IPv4, IPv6, default routes, netplan, effective `eth0`, and 2 GB memory limit;
- absence of inherited `sysadm` and `rtradm` accounts;
- positive and deliberately induced negative hardening-validation paths;
- rejection of an active SSH authorized key;
- idempotent stop/start;
- complete wipe with `identityX` preserved;
- internal redeploy with automatic recreation and re-hardening;
- nginx, HTTPS, public A/AAAA, and `IntegratedInstructions=NO` regression checks.

Known TAYGA/NAT64 and repeated iptables cleanup warnings remained unrelated legacy backlog items.

## Foundation 1B Discovery

The identity container baseline was confirmed as Ubuntu 24.04 amd64 with approximately 2 GiB of memory. Redis and SQLite were absent, while required download and checksum tools were present. The candidate Ubuntu packages and the exact Authelia and OAuth2 Proxy release artifacts were inspected, and both external archives passed SHA-256 verification before installation.

## Outcome

Foundation 1A is approved on `nico-auth`. The stable `nico` branch remains unchanged. Foundation 1B can now introduce a canonical version manifest and reproducible software installation without nginx authentication cutover.

## Next Work

Create `configs/identity/versions.env`, install the verified identity software baseline with services disabled, and then implement ADR-0004 version checks and deployment reporting incrementally.

---

# Engineering Log Index

| Entry | Date | Summary | Status |
|---|---|---|---|
| S-0001 | 2026-07-31 | Architecture foundation | Completed |
| S-0002 | 2026-08-23 | DNS architecture restoration and validation | Completed |
| S-0003 | 2026-08-23 | Scalability audit and 60-group baseline | Completed |
| S-0004 | 2026-08-30 | CloudFormation lifecycle hardening | Completed |
| S-0005 | 2026-08-31 | dnsdist, DNS-label, and AMI improvements | Completed |
| S-0006 | 2026-08-31 | Handbook reconciliation and hardening discovery | Completed |
| S-0007 | 2026-09-01 | Integrated instructions and CloudFormation operator UX | Completed |
| S-0008 | 2026-09-07 | Identity platform foundation and deployment reporting policy | Completed |

---

# Review Status

**Current Status:** In Review

**Next Review:** After the Foundation 1B software baseline and the first ADR-0004 reporting prototype.
