# Future Modularity

**Status:** Draft

**Last Updated:** 2026-08-31

---

# Purpose

This document proposes an incremental modularity model for OCTO-TE Labs.

The objective is not to replace working shell code immediately. It is to reduce hidden global coupling, make resource ownership explicit, improve lifecycle safety, and enable capability-driven planning.

---

# Current Strengths to Preserve

The current implementation already has useful module boundaries under `scripts/lab-tools/`:

- networks;
- routers;
- clients;
- resolvers;
- authoritative roles;
- validators;
- border router;
- shared DNS services;
- nginx, WebSSH, certificates, instructions, passwords, and cron.

The create/start/stop/delete function pattern is also valuable.

---

# Current Coupling Problems

Modules currently depend on sourced global variables and calling order.

Examples:

- profile flags are shell globals;
- modules assume `workdir`, `DOMAIN`, `NETWORKS`, and addressing variables exist;
- resource ownership is implicit;
- cleanup often assumes resources exist;
- function names are not validated as a contract;
- configuration generation and resource mutation are interleaved;
- external package installation occurs during resource creation;
- validation is distributed and often manual;
- current defects such as `StudentAuthServers`, `RPKIfortX`, and `start_student_servers` are not caught before execution.

---

# Target Module Contract

A future module should declare metadata and implement a consistent lifecycle.

Candidate contract:

```text
metadata
preflight
plan
create
configure
start
validate
stop
delete
cleanup_validate
```

Not every component needs every operation, but unsupported operations should be explicit.

---

# Proposed Metadata

Each module could declare:

- module identifier;
- provided roles or services;
- required capabilities;
- dependencies;
- conflicts;
- shared versus per-group scope;
- network attachments;
- addresses and ports requested;
- files and credentials owned;
- memory/CPU defaults;
- external dependencies;
- validation probes;
- cleanup resources.

This metadata can be represented in a simple data format before any orchestrator rewrite is attempted.

---

# Resource Ownership

Every resource should have one lifecycle owner.

Examples:

| Resource | Proposed owner |
|---|---|
| `grpN-lan/int/dmz/extra` | group-network module |
| `grpN-rtr` | group-router module |
| `dnsdist` container and DNAT | public-DNS-frontend module |
| parent Route 53 records | CloudFormation template |
| lab apex DS | DNSSEC lifecycle module plus CloudFormation cleanup resource |
| WebSSH virtual host | WebSSH publication module |
| WireGuard DNAT | border-connectivity module |

Ownership prevents multiple modules from creating or deleting the same resource independently.

---

# Configuration Separation

Future configuration should distinguish:

1. deployment input;
2. derived plan;
3. rendered component configuration;
4. runtime state;
5. secrets.

The current `deploy-parameters.cfg` combines persistent input with values rendered by CloudFormation. Command-line overrides do not rewrite it. A future model should make persistence and precedence explicit.

Candidate precedence:

```text
profile defaults
    < deployment configuration
    < explicit command-line overrides
```

The effective configuration should be written to a generated, non-secret plan artifact for auditability.

---

# Secrets Separation

Secrets must not share the same output path as ordinary configuration.

Future modules should:

- receive secret references or protected files;
- avoid echoing values;
- set restrictive permissions;
- rotate or remove bootstrap credentials;
- report only redacted state;
- define cleanup behavior.

---

# Dependency Graph

A module graph should replace hidden ordering assumptions.

Example:

```text
group-authority
    -> group networks
    -> group router
    -> authoritative container templates

public DNS frontend
    -> platform authority
    -> exercise authority
    -> RPZ authority

HTTPS publication
    -> public DNS
    -> certificate service
    -> nginx
```

The planner should reject cycles and missing providers before modifying the host.

---

# Idempotency Model

Lifecycle operations should be safe when repeated.

A module must know how to handle:

- resource absent;
- resource already present and correct;
- resource present but inconsistent;
- partial creation;
- dependency unavailable;
- repeated delete.

Idempotency should be validated by automated tests, not inferred from ignored errors.

---

# Validation Contract

Each module should expose machine-readable checks, for example:

```text
container exists
container state is Running
service is active
configured address is present
port is listening
query or protocol exchange succeeds
public record exists
cleanup removed owned resources
```

A profile is ready only when all required module checks pass.

---

# Migration Strategy

## Phase 1 - Stabilize current modules

- correct confirmed function and template-name defects;
- make cleanup idempotent;
- remove fixed credentials;
- add validation functions;
- document ownership.

## Phase 2 - Introduce metadata

- add module descriptors without changing the current execution path;
- generate a dependency report;
- compare report with current order.

## Phase 3 - Separate plan and apply

- derive an explicit plan;
- render configuration before mutation;
- allow dry-run inspection.

## Phase 4 - Capability-driven selection

- map current Lab Types to named profiles;
- derive module selection from capabilities;
- retain current profiles as compatibility aliases.

## Phase 5 - Replace or retain shell selectively

A future orchestrator may remain shell-based, use Python, or combine tools. The implementation language should be selected after contracts and tests exist, not before.

---

# Backward Compatibility

The migration should preserve:

- existing CloudFormation entry points where practical;
- current profile numbers as compatibility inputs;
- container and network naming until a deliberate migration exists;
- participant URLs and credential-file behavior where safe;
- internal wipe/redeploy;
- proven addressing and topology.

Security defects are not compatibility guarantees and should be removed.

---

# Acceptance Criteria

The modularity design is ready for ADR review when:

- current resources have explicit owners;
- module contracts cover lifecycle and validation;
- Types 1 and 2 can be represented without behavior loss;
- routing dependencies can be represented;
- plan generation detects current known defects before apply;
- repeated create/delete behavior can be tested automatically;
- secrets and ordinary configuration are separated;
- migration can proceed incrementally.

---

# Related Documents

- [`../architecture/03-orchestrator.md`](../architecture/03-orchestrator.md)
- [`future-orchestrator.md`](future-orchestrator.md)
- [`future-capabilities.md`](future-capabilities.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)

---

# Review Status

**Current Status:** Draft

**Next Review:** After hardening establishes reliable lifecycle contracts for the current modules.
