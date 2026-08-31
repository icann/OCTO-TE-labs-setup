# Engineering Backlog

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

The Engineering Backlog is the authoritative list of planned, active, blocked, deferred, and recently completed engineering work for OCTO-TE Labs.

The Engineering Log records what happened. The Knowledge Base preserves durable lessons. This backlog defines what still needs to be done.

---

# Work Item Model

| Prefix | Type |
|---|---|
| EPIC | Coordinated body of work |
| TASK | Analysis, validation, or documentation task |
| BUG | Confirmed implementation defect |
| TD | Technical debt |
| IMP | Improvement to existing behavior |
| FEAT | New functionality |

Identifiers are never reused.

## Status Values

- Planned
- In Progress
- Blocked
- Completed
- Deferred

## Priority Values

- Critical
- High
- Medium
- Low

---

# Current Execution Order

The agreed engineering sequence is:

1. complete the Handbook reconciliation;
2. perform deployment and wipe hardening, starting with security findings;
3. recover and quantify higher scalability;
4. recover and validate routing and RPKI profiles;
5. advance capability-driven orchestration design.

A production-blocking defect can temporarily override this sequence.

---

# EPIC-001 - Current Architecture Baseline

**Status:** In Progress

**Objective:** Make the current platform understandable through evidence-based architecture, reference, decision, and development documentation.

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| TASK-0010 | Architecture | High | Completed | Analyze the deployment lifecycle from repository publication through stack deletion. |
| TASK-0011 | Documentation | High | Completed | Document the deployment lifecycle. |
| TASK-0012 | Architecture | High | Completed | Analyze `setup-lab.sh` and supporting modules. |
| TASK-0013 | Documentation | High | Completed | Document the orchestration architecture. |
| TASK-0014 | Architecture | High | Completed | Identify service and script dependencies and produce deployment diagrams. |
| TASK-0015 | Documentation | High | Completed | Document the current network topology and addressing model. |
| TASK-0016 | Documentation | High | Completed | Document DNS capabilities, platform services, AWS, LXD, ports, software, and naming. |
| TASK-0017 | Documentation | High | Completed | Replace the root operational guide and core reference placeholders. |
| TASK-0018 | Documentation | High | Completed | Update Knowledge Base, Engineering Log, Backlog, Roadmap, Ideas, To-do, and ADR-0002. |
| TASK-0019 | Documentation | High | Planned | Complete Batch 4 navigation, remaining architecture/design documents, and global consistency validation. |
| TASK-0026 | Review | Medium | Planned | Perform technical review and decide which baseline documents can be promoted from In Review to Approved. |

## Completion Criteria

EPIC-001 completes when:

- no current-behavior document remains a July placeholder;
- all verified architecture and known defects are traceable;
- relative links and metadata pass automated validation;
- current implementation and future design are clearly separated;
- a maintainer can understand the lifecycle without reading every shell script first.

---

# EPIC-004 - Deployment and Security Hardening

**Status:** Planned

**Execution Order:** Next after EPIC-001

**Objective:** Remove security risks, make lifecycle operations idempotent, improve reproducibility, and reduce operational ambiguity before broader scale and routing use.

## Security and Access

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| BUG-0040 | Bug | Critical | Planned | Add authentication and appropriate access controls to the active `webssh.<DOMAIN>` nginx virtual host. |
| BUG-0041 | Bug | Critical | Planned | Eliminate fixed bootstrap credentials `sysadm:icannws` and `rtradm:icannws`; verify removal or rotation in every template and role. |
| TD-0040 | Technical Debt | High | Planned | Prevent passwords, VPN values, and other secrets from being printed to deployment logs. |
| IMP-0040 | Improvement | Medium | Planned | Define a least-privilege and exposure review for every public port and service. |

## Lifecycle and Cleanup

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| BUG-0042 | Bug | High | Planned | Fix NAT64 teardown: remove invalid `tayga --rmmod`, test interface existence, and make repeated cleanup safe. |
| BUG-0043 | Bug | High | Planned | Make iptables add/delete operations idempotent and resolve legacy/nftables ambiguity. |
| BUG-0044 | Bug | High | Planned | Correct and regression-test `start_all()` function calls for resolver and authoritative roles. |
| BUG-0045 | Bug | Medium | Planned | Condition `grpN` delegation generation on the presence of participant authoritative capability or explicitly redesign the delegation behavior. |
| BUG-0046 | Bug | Low | Planned | Resolve the historical `-d` option and implement a correct `--help`/usage path. |
| IMP-0041 | Improvement | Medium | Planned | Make NAT64/DNS64 an explicit capability rather than an unconditional platform service. |
| IMP-0042 | Improvement | Medium | Planned | Validate `AmiOverride` with a nonexecuted change set against a disposable existing stack. |
| IMP-0043 | Improvement | High | Planned | Add a CloudFormation readiness signal so stack status can distinguish EC2 creation from internal deployment completion. |

## Reproducibility and Maintainability

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| TD-0041 | Technical Debt | High | Planned | Pin, cache, mirror, or prebake external package and artifact dependencies; define retry behavior. |
| TD-0042 | Technical Debt | Medium | Planned | Stop reinstalling the Jekyll toolchain on every internal redeploy and remove Bundler-root and Sass deprecation warnings. |
| TD-0043 | Technical Debt | Medium | Planned | Replace initial SOA serial `1` with UTC `YYYYMMDDnn` and safe same-day increment logic. |
| TD-0044 | Technical Debt | Low | Planned | Remove or justify the legacy `%KSK_ARN%` substitution from the publication workflow. |
| TD-0045 | Technical Debt | Medium | Planned | Reduce output noise, fix message typos, and add explicit normal/verbose/debug modes. |
| TD-0046 | Technical Debt | Medium | Planned | Introduce automated shell, CloudFormation, configuration, link, and lifecycle validation in CI. |

---

# EPIC-005 - Scalability Recovery

**Status:** Planned

**Objective:** Recover measurable support for 100+ groups while preserving service correctness and predictable host behavior.

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| TASK-0050 | Validation | High | Completed | Establish the 60-group Lab Type 1 baseline and correct LXD instance-count methodology. |
| IMP-0050 | Improvement | High | Completed | Stop generating nonexistent group-authoritative `dnsdist` backends when `StudentAuth=NO`. |
| TASK-0051 | Validation | High | Planned | Repeat 60-group testing after the dnsdist fix and run controlled 80/100+ group tests. |
| TASK-0052 | Architecture | High | Planned | Produce a capacity matrix by Lab Type, instance type, CPU, RAM, storage, instance count, and role mix. |
| IMP-0051 | Improvement | High | Planned | Raise and centralize the current 64-group limit after validation. |
| IMP-0052 | Improvement | Medium | Planned | Replace large hand-written route lists with validated generated configuration while preserving prepared capacity. |
| IMP-0053 | Improvement | High | Planned | Support adding groups later by creating only the required bridges, containers, credentials, DNS, and web artifacts. |
| IMP-0054 | Improvement | Medium | Planned | Restore a dynamic RFC 4193 ULA per deployment. |
| IMP-0055 | Improvement | High | Planned | Define role-specific LXD memory/CPU limits, including an 8 GB target ceiling for global RPKI validators when justified. |
| IMP-0056 | Improvement | Medium | Planned | Measure and, if safe, parallelize independent container preparation stages. |

## Historical Target

The original implementation demonstrated more than 100 complete groups and more than 700 containers on a 128 GiB host. The current branch must reproduce equivalent evidence before claiming the same capacity.

---

# EPIC-002 - Routing and RPKI Recovery

**Status:** Planned

**Objective:** Restore and regression-test routing, Anycast, VPN, and RPKI functionality against the current Ubuntu/LXD baseline.

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| TASK-0020 | Architecture | High | Planned | Compare current routing/RPKI code with the preserved original implementation and define required parity. |
| BUG-0020 | Bug | High | Planned | Replace `StudentAuthServers` with the implemented `StudentAuth` flag in Lab Type 3. |
| BUG-0021 | Bug | High | Planned | Resolve `RPKIfortX` versus `fortX` in group-validator creation. |
| BUG-0022 | Bug | High | Planned | Align `VPNlistenPort`, WireGuard DNAT add/delete rules, and CloudFormation UDP ingress. |
| TASK-0021 | Validation | High | Planned | Run full Lab Type 3 deployment, BGP, Anycast, shared-validator, VPN, DNS, and cleanup tests. |
| TASK-0022 | Validation | High | Planned | Run full Lab Type 4 deployment, group-validator, BGP, Anycast, VPN, DNS, and cleanup tests. |
| IMP-0020 | Improvement | High | Planned | Restore a routing-only profile/capability that avoids unnecessary DNS participant services. |
| IMP-0021 | Improvement | High | Planned | Validate FORT memory, storage, runtime, ROA data, RTR ports, and restart behavior at scale. |
| IMP-0022 | Improvement | Medium | Planned | Make routing and RPKI dependencies versioned and reproducible. |

---

# EPIC-003 - Capability-Driven Platform Evolution

**Status:** Planned

**Objective:** Replace fixed numeric profile coupling with a capability-driven model after current behavior, hardening, scale, and routing requirements are understood.

| Item | Type | Priority | Status | Description |
|---|---|---:|---|---|
| TASK-0030 | Architecture | Medium | Planned | Finalize the capability taxonomy for DNS, routing, platform, security, and operations. |
| TASK-0031 | Architecture | Medium | Planned | Define dependencies among capabilities and platform roles. |
| TASK-0032 | Design | Medium | Planned | Define instructor-facing Training Profiles as named capability sets. |
| TASK-0033 | Design | Medium | Planned | Design a declarative deployment plan that replaces implicit shell-global ordering. |
| FEAT-0030 | Feature | Medium | Deferred | Implement capability selection only after the design and migration path are approved. |

**Related Candidates:** AC-0001, AC-0002, AC-0003, AC-0004

---

# Recently Completed Implementation Work

| Commit | Result |
|---|---|
| `58d8884` | Removed fixed IAM role naming conflict across stacks |
| `f37fc40` | Added stack-delete DS cleanup |
| `6cce2d6` | Made group-authoritative dnsdist pools conditional |
| `482c8e4` | Allowed validated hyphenated lab DNS labels |
| `b9ce623` | Added optional AMI pinning for stack updates |
| `bdf70b3` | Refreshed core deployment and architecture documentation |
| `44fd0e5` | Refreshed network and platform service documentation |

---

# Review Status

**Current Status:** In Review

**Next Review:** At the end of each documentation batch and after every hardening or capacity milestone.
