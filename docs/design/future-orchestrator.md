# Future Orchestrator

**Status:** Draft

**Last Updated:** 2026-08-31

---

# Purpose

This document proposes a future orchestration model based on capabilities, named profiles, explicit dependencies, planning, validation, and lifecycle ownership.

It is a target design, not the current implementation.

---

# Current Baseline

The current orchestrator:

- is implemented in `scripts/setup-lab.sh`;
- maps numeric Lab Types to shell flags;
- sources component modules;
- mutates the host imperatively;
- uses global variables from `deploy-parameters.cfg` and command-line overrides;
- provides `--deploy`, `--wipe`, `--start_all`, and `--stop_all`;
- has useful create/start/stop/delete module functions;
- lacks a formal plan, module contract, dry run, and unified validation report.

The future model should build on the useful behavior rather than discard it without evidence.

---

# Design Goals

- Select labs through capabilities and named profiles.
- Derive required shared and per-group roles.
- Build and validate a dependency graph before mutation.
- Produce an inspectable deployment plan.
- Separate configuration, secrets, rendered artifacts, and runtime state.
- Make create/delete and repeated cleanup idempotent.
- Provide preflight and post-deployment validation.
- Estimate resources before deployment.
- Preserve compatibility with current Lab Types.
- Support internal redeployment and future incremental expansion.

---

# Proposed Flow

```text
input configuration
    -> normalize and validate
    -> expand named profile
    -> resolve capabilities
    -> resolve modules and dependencies
    -> calculate group and shared resources
    -> preflight capacity and external dependencies
    -> produce plan
    -> operator review or automatic approval policy
    -> apply in dependency order
    -> validate
    -> publish readiness report
```

Deletion follows the reverse dependency graph and validates cleanup.

---

# Input Model

Candidate top-level input:

```yaml
profile: full-dns
groups: 30
features:
  nat64: true
  webssh: true
  monitoring: false
options:
  public_dns: true
  external_routing: false
```

A profile can expand to capabilities and defaults. Explicit overrides remain visible in the effective plan.

The example is illustrative; no configuration format is approved yet.

---

# Profile Compatibility

Current Lab Types should remain accepted during migration:

```text
1 -> resolver profile
2 -> full-dns profile
3 -> routing-global-rpki profile
4 -> routing-group-rpki profile
```

The compatibility mapping should be data, not duplicated case logic.

A named profile can evolve only through explicit review because instructors rely on predictable topology.

---

# Planning Model

The plan should contain:

- normalized inputs;
- selected capabilities;
- selected modules;
- dependency order;
- shared resources;
- per-group resource formulas;
- addresses and ports;
- estimated container count;
- memory ceilings and expected use;
- external repositories or artifacts;
- public interfaces;
- credentials and secret references;
- validation checks;
- cleanup ownership.

The plan should be serializable for review and post-deployment comparison.

---

# Preflight Checks

Before apply:

- validate group range against addressing and capacity;
- verify required LXD templates;
- verify external package/artifact availability or cache;
- validate ports and Security Group requirements;
- detect conflicting capabilities;
- validate address collisions;
- verify parent DNS and IAM permissions;
- verify disk, memory, CPU, and swap thresholds;
- verify secrets without printing them;
- validate module functions and descriptors.

Current defects such as missing `fortX`, wrong function names, or absent WireGuard ingress should be caught here.

---

# Apply Model

Apply should:

- use the dependency graph;
- record operation start/end and result;
- avoid repeating completed correct work;
- stop on a defined failure policy;
- preserve enough state to perform cleanup;
- keep secrets out of logs;
- distinguish retryable external failures from configuration defects.

Parallelism may improve deployment time, but should be introduced only after dependency and resource contention are understood.

---

# Validation Model

Validation should aggregate module checks into a profile report:

```text
Infrastructure: PASS
Shared DNS:     PASS
Group roles:    30/30 PASS
Public DNS:     PASS
DNSSEC:         PASS
HTTPS:          PASS
WebSSH:         FAIL - access control missing
Cleanup test:   NOT RUN
Overall:        FAIL
```

A profile's readiness policy determines which checks are mandatory.

CloudFormation `CREATE_COMPLETE` remains only an infrastructure-stage result.

---

# Lifecycle Operations

Candidate operations:

| Operation | Meaning |
|---|---|
| `plan` | calculate and display changes |
| `apply` | create or reconcile selected state |
| `validate` | run readiness checks |
| `stop` | stop profile resources safely |
| `start` | start and validate profile resources |
| `destroy` | delete profile-owned resources |
| `cleanup-validate` | prove owned resources were removed |
| `expand` | add groups within prepared and measured capacity |
| `export-state` | record plan, versions, and evidence |

The exact command syntax is not yet decided.

---

# State Model

The current platform relies primarily on discovery through LXD, files, and cloud APIs.

A future state record could improve recovery but must not become a fragile single point of truth.

Candidate approach:

- desired plan file;
- generated artifact inventory;
- operation journal;
- discovered runtime comparison;
- external-state ownership list.

Runtime discovery remains necessary to handle partial deployment and manual changes.

---

# Error and Recovery Model

Errors should be classified:

- invalid input;
- failed preflight;
- external dependency unavailable;
- module create/configure failure;
- validation failure;
- cleanup failure;
- capacity threshold exceeded.

The orchestrator should report:

- failed operation;
- affected module/group;
- completed dependencies;
- retry safety;
- cleanup recommendation;
- relevant logs without secrets.

Automatic rollback should not be assumed safe for every training environment; explicit destroy/reapply may be clearer.

---

# Capacity Model

Before deployment, calculate:

```text
shared instances
+ groups x per-group instances
+ optional capability instances
```

Combine this with measured per-role memory and service-specific costs such as `dnsdist` downstream objects and RPKI validator memory.

Capacity policy can then warn or block based on host class and selected profile.

---

# Security Model

The orchestrator should fail preflight when:

- fixed bootstrap credentials remain in deployable templates;
- a public management interface lacks required access control;
- secrets would be emitted to logs;
- required public ingress is absent or overbroad;
- cleanup ownership is undefined.

Security is part of readiness, not a separate optional report.

---

# Implementation Options

Possible implementations include:

- a hardened shell orchestrator with generated metadata;
- Python coordinating existing shell modules;
- a purpose-built declarative engine;
- staged migration using both shell and structured descriptors.

No implementation language is selected by this Draft. Contracts, evidence, migration safety, and tests should drive the choice.

---

# Migration Phases

1. harden and test current lifecycle functions;
2. add module validation functions;
3. create module descriptors and a read-only plan generator;
4. map current Lab Types to named profiles;
5. compare planned resources with current deployments;
6. allow plan-driven Type 1 and Type 2 deployment;
7. recover routing profiles through the same model;
8. add capacity policy and controlled expansion;
9. retire duplicate case logic only after compatibility tests pass.

---

# Acceptance Criteria

The design is ready for ADR review when a prototype can:

- represent current Types 1 and 2 exactly;
- detect current known profile defects before apply;
- generate a deterministic resource plan;
- calculate expected instance counts;
- apply and destroy a disposable profile idempotently;
- produce a readiness report;
- retain numeric-profile compatibility;
- keep secrets out of output;
- support routing dependencies without embedding routing-specific logic in the core.

---

# Related Documents

- [`../architecture/03-orchestrator.md`](../architecture/03-orchestrator.md)
- [`future-capabilities.md`](future-capabilities.md)
- [`future-modularity.md`](future-modularity.md)
- [`future-routing.md`](future-routing.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)

---

# Review Status

**Current Status:** Draft

**Next Review:** After current lifecycle hardening and a read-only plan prototype are available.
