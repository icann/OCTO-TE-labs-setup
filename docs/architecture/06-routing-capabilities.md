# Routing Capabilities

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document describes the routing, Anycast, and RPKI capabilities represented in the current OCTO-TE Labs architecture and implementation.

It distinguishes architectural intent from verified behavior. Lab Types 3 and 4 are under recovery and must not be treated as production-ready merely because their scripts and configuration templates exist.

---

# Capability Taxonomy

The Routing training domain contains three primary capabilities:

- BGP;
- Anycast;
- RPKI.

Supporting functions include:

- group-router access;
- border-router operation;
- external VPN/peering connectivity;
- routing policy;
- IPv4 and IPv6 forwarding;
- RPKI-to-Router protocol service;
- route-origin validation and policy application.

---

# Current Routing Roles

| Role | Current implementation | Scope |
|---|---|---|
| Group router | `grpN-rtr` copied from `rtrX` | one per selected group |
| Border router | `iborder-rtr` copied from `rtrX` | shared when enabled |
| Global validators | `rpki1`, `rpki2` copied from `fortX` | shared in intended Type 3 profile |
| Group validator | `grpN-rpki` | intended one per group in Type 4 |
| Participant client | `grpN-cli` | command-line access and traffic generation |

Every group router is attached to:

- the backbone;
- LAN;
- internal server network;
- DMZ;
- extra network.

---

# Group Router Baseline

The router configuration enables IPv4 and IPv6 forwarding and assigns:

```text
Backbone IPv4: 100.64.1.N/22
Backbone IPv6: fd89:59e0:0:1::N/48
LAN:            100.100.N.1/26
Internal:       100.100.N.65/26
DMZ:            100.100.N.129/26
Extra:          100.100.N.193/26
```

The FRRouting hostname is currently generated as:

```text
rtr1.grpN.<DOMAIN>
```

The `1` is inherited from the current `%RTR%` template value and is not yet a normalized architecture-level naming convention.

The default route points to the EC2 host backbone gateway. BGP is added through the routing-profile configuration rather than the base router template.

---

# Border Router and BGP

The intended border router uses:

```text
Container: iborder-rtr
ASN:       65000
IPv4:      100.64.0.10/22
IPv6:      fd89:59e0:0::10/48
```

For group `N`, generated neighbor values are:

```text
Group ASN:      65000 + N
IPv4 neighbor: 100.64.1.N
IPv6 neighbor: fd89:59e0:0:1::N
```

The current border-router template activates IPv4 and IPv6 unicast address families and includes placeholder route maps named `TODO-IPv4` and `TODO-IPv6`. These currently permit all prefixes and are not a final routing-policy design.

The configuration also contains RPKI-aware route-map examples that assign higher local preference to valid routes than to not-found routes. Full policy behavior requires regression testing.

---

# Anycast Capability

The current repository contains topology and border-router components intended for Anycast exercises, but the complete Anycast workflow is not yet documented as verified.

A production-ready Anycast capability must define:

- which service or prefix is announced;
- which nodes originate the same prefix;
- inbound and outbound policy;
- withdrawal and failure behavior;
- IPv4 and IPv6 validation;
- interaction with RPKI;
- participant-visible success criteria.

Anycast must be treated as a profile built from BGP, service, addressing, and validation capabilities rather than as a single script switch.

---

# RPKI Capability

## Validator templates

`setup-containers.sh` prepares a stopped `fortX` template. The global-validator path copies it successfully to `rpki1` and `rpki2`.

The per-group validator path currently attempts:

```text
lxc copy RPKIfortX grpN-rpki
```

No template with that name is created. This blocks the intended group-validator profile until the naming mismatch is corrected.

## Validator addressing

Shared validators use:

```text
rpki1: 100.64.0.70 / fd89:59e0:0::70
rpki2: 100.64.0.71 / fd89:59e0:0::71
```

A group validator is intended to use:

```text
100.100.N.70
fd89:59e0:N:64::70
```

## RTR service

The FORT template is intended to expose the RPKI-to-Router protocol on TCP/323. Router/validator connectivity, cache synchronization, serial behavior, and policy application require dedicated validation in the current branch.

## Resource limits

Global Internet ROA processing can require substantially more memory than ordinary participant roles. The normal LXD profile ceiling is 2 GB; validator roles are expected to require a deliberate higher ceiling, likely 8 GB, based on prior FORT work. The final value must be measured rather than assumed.

---

# External Connectivity and WireGuard

The border-router path configures a WireGuard interface from deployment parameters, including `VPNlistenPort`.

Current blockers:

- CloudFormation does not expose the WireGuard UDP listener;
- host DNAT add/delete rules are hard-coded to UDP/36456;
- the DNAT destination is hard-coded to `100.64.0.10:36456`;
- cleanup is not safely idempotent;
- configuration output can expose sensitive VPN information.

Parameter, Security Group, host DNAT, container listener, cleanup, and documentation must be aligned before external routing use.

---

# Current Lab-Type Mapping

## Lab Type 3 - intended shared RPKI profile

Intended components:

- group routers and clients;
- resolver and authoritative environment;
- router access;
- `rpki1` and `rpki2`;
- `iborder-rtr`;
- WireGuard external connectivity.

Known profile defect:

```text
StudentAuthServers=YES
```

is assigned, while the rest of the orchestrator checks `StudentAuth`. Group authoritative containers and their `dnsdist` pools are therefore not reliably enabled.

## Lab Type 4 - intended per-group RPKI profile

Intended components:

- Type 2 DNS environment;
- router access;
- one `grpN-rpki` per group;
- `iborder-rtr` and external connectivity.

The `RPKIfortX`/`fortX` mismatch is expected to block group-validator creation.

---

# Additional Lifecycle Defects

Routing recovery must also account for:

- `start_all()` calling a generic `start_student_servers` name instead of the verified resolver and authoritative functions;
- fixed bootstrap credentials inherited by router and validator roles;
- generated passwords printed to logs;
- external FRRouting repository availability and version drift;
- no explicit public ingress for WireGuard;
- cleanup commands that fail noisily when resources are absent;
- current `-d` command-line option inconsistency;
- unconditional NAT64 deployment even for profiles that may not require it.

---

# Current Validation State

| Area | State |
|---|---|
| Group router creation and five-interface attachment | Observed in DNS-profile deployments |
| Base FRRouting installation and configuration push | Observed |
| Border-router generation | Present in code; requires current end-to-end test |
| IPv4 BGP peering | Present in generated config; not current production-verified |
| IPv6 BGP peering | Present in generated config; not current production-verified |
| Anycast workflow | Partial design/code; not current production-verified |
| Global FORT validators | Present in code; requires current runtime validation |
| Per-group FORT validators | Blocked by template-name mismatch |
| RPKI policy in FRR | Present as examples; requires validation |
| WireGuard external connectivity | Blocked by ingress and DNAT inconsistencies |
| Type 3 complete profile | Not production-verified |
| Type 4 complete profile | Not production-verified |

---

# Recovery Sequence

The recommended recovery order is:

1. correct profile flag and template-name defects;
2. remove fixed credentials from router and validator templates;
3. align WireGuard parameter, Security Group, DNAT, and cleanup;
4. pin or otherwise stabilize FRRouting and FORT dependencies;
5. validate group routers independently;
6. validate the border router and IPv4/IPv6 BGP;
7. validate global RPKI validators and RTR sessions;
8. validate per-group validators;
9. define and validate Anycast scenarios;
10. test stop/start, wipe, stack deletion, and repeat deployment;
11. measure memory, CPU, startup time, and maximum group count;
12. promote profiles to production-ready only after regression evidence exists.

---

# Acceptance Criteria

A routing profile should not be described as verified until:

- all intended containers exist and reach the expected state;
- BGP sessions establish over IPv4 and IPv6;
- intended prefixes are announced and filtered correctly;
- RPKI validators synchronize and serve RTR;
- routers classify validation states correctly;
- external WireGuard connectivity works with the configured parameter;
- credentials and public access are hardened;
- repeated start, stop, wipe, redeploy, and stack delete are clean;
- resource use is measured for the intended group count;
- participant instructions match the actual topology.

---

# Related Documents

- [`04-network-topology.md`](04-network-topology.md)
- [`08-implementation.md`](08-implementation.md)
- [`../reference/lab-types.md`](../reference/lab-types.md)
- [`../reference/network-addressing.md`](../reference/network-addressing.md)
- [`../reference/ports.md`](../reference/ports.md)
- [`../design/future-routing.md`](../design/future-routing.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)

---

# Review Status

**Current Status:** In Review

**Next Review:** After the first complete routing-profile regression test on the current branch.
