# Future Routing Architecture

**Status:** Draft

**Last Updated:** 2026-08-31

---

# Purpose

This document proposes the target direction for restored and future BGP, Anycast, and RPKI laboratories.

It is informed by the current branch and the original implementation, but it is not a claim that the routing profiles currently work end to end.

---

# Design Objectives

- Restore working routing profiles on the current Ubuntu/LXD baseline.
- Make routing deployable without unnecessary DNS participant roles.
- Preserve dual-stack group topology and the `extra` network.
- Support BGP, Anycast, and RPKI as composable capabilities.
- Align WireGuard parameters, cloud ingress, host forwarding, and cleanup.
- Support shared and per-group validator profiles.
- Remove fixed credentials and secret output.
- Validate lifecycle and scale before production use.

---

# Target Topology

```text
External peer or controlled ISP
          |
       WireGuard
          |
     iborder-rtr (AS65000)
          |
      net-bb backbone
          |
  +-------+--------+------+
  |                |      |
grp1-rtr        grp2-rtr ... grpN-rtr
AS65001         AS65002      AS65000+N
  |                |
LAN / INT / DMZ / EXTRA per group
```

Optional validators attach either to the backbone or to each group's internal network.

---

# Capability Components

## BGP

Required behavior:

- IPv4 and IPv6 sessions;
- stable per-group ASN assignment;
- explicit inbound and outbound policy;
- route advertisement and withdrawal exercises;
- session and prefix validation;
- safe default policy.

The current permit-all `TODO` route maps are placeholders and should not become the default production policy.

## Anycast

Required behavior:

- explicit Anycast prefix or service definition;
- at least two origins;
- controlled announcement and withdrawal;
- observable path changes;
- IPv4 and IPv6 scenarios;
- optional RPKI-valid and invalid cases;
- clear participant reset procedure.

## RPKI

Required behavior:

- stable FORT package/version or prebaked template;
- TAL and repository initialization;
- RTR service and session validation;
- shared-validator profile;
- per-group-validator profile;
- appropriate memory ceilings;
- router policy for valid, invalid, and not-found states;
- metrics or status evidence.

---

# Routing-Only Profile

A routing-only profile should not create participant resolver and authoritative containers unless the exercise explicitly requires them.

Minimum candidate per-group roles:

```text
grpN-rtr
grpN-cli
optional grpN-rpki
```

Shared roles:

```text
iborder-rtr
optional rpki1/rpki2
platform web/access services
```

Shared platform DNS can remain available for hostnames and certificates, while participant DNS capabilities are disabled.

This separates platform prerequisites from training capability selection.

---

# Addressing and ASN Policy

The current scheme can be retained initially:

```text
Border ASN: 65000
Group ASN:  65000 + group number
```

Current backbone addresses:

```text
iborder-rtr: 100.64.0.10 / fd89:59e0:0::10
grpN-rtr:    100.64.1.N  / fd89:59e0:0:1::N
```

Before extending above the current range, validate:

- IPv4 host-space limits;
- IPv6 representation of decimal group numbers;
- ASN range and exercise assumptions;
- external-peer policy;
- route generation and cleanup.

---

# WireGuard and External Peering

The target model must use one authoritative value for the local listener.

Required alignment:

```text
VPNlistenPort
    -> CloudFormation Security Group ingress
    -> host DNAT destination port
    -> iborder-rtr WireGuard ListenPort
    -> delete/cleanup rule
    -> documentation and validation
```

The public source range should be configurable and restricted. VPN keys must not be logged.

External connectivity should be optional and should fail preflight clearly when parameters are incomplete.

---

# Validator Profiles

## Shared-validator profile

- `rpki1` and `rpki2` on the backbone;
- group routers connect to selected caches;
- supports common Internet validation data;
- easier to scale than one validator per group.

## Per-group-validator profile

- one `grpN-rpki` on each internal network;
- independent validation and failure exercises;
- significantly higher memory, network, disk, and startup cost;
- requires corrected template naming and measured capacity.

The profile must select validator architecture explicitly rather than infer it from unrelated DNS flags.

---

# Security Requirements

- no fixed `sysadm` or `rtradm` credentials;
- router access only through intended paths;
- WebSSH protected by explicit access control;
- WireGuard ingress limited to required source and port;
- VPN private keys protected and redacted;
- BGP default policy defined safely;
- no accidental public RTR exposure unless explicitly required;
- package and image provenance recorded.

---

# Lifecycle Requirements

Every routing component must support:

- create;
- configure;
- start;
- validate;
- stop;
- delete;
- repeated cleanup.

A failed deployment must not leave:

- public UDP ingress;
- DNAT rules;
- WireGuard interfaces;
- BGP sessions;
- validator containers;
- credentials or keys;
- orphan LXD networks.

---

# Validation Matrix

| Area | Required evidence |
|---|---|
| Group router | interfaces, routes, FRR service, credentials |
| Border router | interfaces, FRR service, correct ASN and policies |
| IPv4 BGP | Established sessions and expected prefixes |
| IPv6 BGP | Established sessions and expected prefixes |
| WireGuard | handshake, routes, correct parameterized port |
| Shared RPKI | validators synchronized, RTR reachable |
| Group RPKI | one validated cache per group |
| Route validation | valid/invalid/not-found states and policy |
| Anycast | multiple origins, path observation, withdrawal |
| Stop/start | state returns cleanly |
| Wipe/redeploy | no stale rules, links, containers, or keys |
| Stack delete | cloud and DNS cleanup complete |
| Scale | measured resource use at target group counts |

---

# Scale Strategy

Routing capacity should use the same hybrid model as the broader platform:

- prepared host routes and tuning for a design maximum;
- LXD networks and containers created only for deployed groups;
- shared validators when high scale is required;
- per-group validators only when the exercise requires them;
- explicit degradation policy for optional features at high scale.

Testing should proceed through controlled steps such as 3, 10, 30, 60, 80, and 100+ groups, with cleanup after each run.

---

# Migration Sequence

1. compare current and original routing code;
2. fix `StudentAuth` profile mapping;
3. fix `fortX` template naming;
4. correct `start_all()` function calls;
5. eliminate bootstrap credentials;
6. align WireGuard ingress and DNAT;
7. stabilize FRRouting and FORT dependencies;
8. validate a minimal two-group BGP topology;
9. validate shared RPKI;
10. validate per-group RPKI;
11. validate Anycast;
12. validate routing-only profile composition;
13. run lifecycle and scale regression tests;
14. update architecture and promote support status only after evidence exists.

---

# Open Questions

- Which external-peer environment is supported for general deployment?
- Should route policy be instructor-selectable or profile-defined?
- Which Anycast service is the baseline exercise target?
- What validator data and refresh strategy are appropriate for workshops?
- What is the supported maximum for shared versus per-group validators?
- Should RTR use TCP/323 or an alternate internal port in constrained environments?
- How should routing profiles operate when no external VPN is configured?

---

# Related Documents

- [`../architecture/06-routing-capabilities.md`](../architecture/06-routing-capabilities.md)
- [`../architecture/04-network-topology.md`](../architecture/04-network-topology.md)
- [`future-capabilities.md`](future-capabilities.md)
- [`future-orchestrator.md`](future-orchestrator.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)

---

# Review Status

**Current Status:** Draft

**Next Review:** After a minimal current-branch BGP and shared-RPKI deployment succeeds and produces measured evidence.
