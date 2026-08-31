# Future Capabilities

**Status:** Draft

**Last Updated:** 2026-08-31

---

# Purpose

This document proposes a structured capability model for future OCTO-TE Labs composition.

It does not replace the current numeric Lab Types. It defines information that a future profile and orchestrator could use to derive roles, dependencies, validation, and resource requirements.

---

# Current Capability Taxonomy

## DNS

- Recursive DNS;
- Authoritative DNS;
- DNSSEC;
- DNS Monitoring;
- Universal Acceptance.

## Routing

- BGP;
- Anycast;
- RPKI.

The taxonomy describes training goals. Current exercise coverage differs by capability and must be recorded separately.

---

# Proposed Capability Metadata

Each capability should eventually define:

| Field | Meaning |
|---|---|
| Identifier | stable machine-readable name |
| Display name | instructor-facing name |
| Training domain | DNS, Routing, or a future domain |
| Description | educational and operational objective |
| Required roles | participant and shared components |
| Dependencies | other capabilities or platform services |
| Conflicts | incompatible selections |
| Network needs | subnets, public exposure, external connectivity |
| Resource model | expected containers, memory, CPU, storage, and scale |
| Activation | deployment-time or instructor-time steps |
| Validation | automated and manual success criteria |
| Cleanup | state and resources that must be removed |
| Security | credentials, public interfaces, and sensitive data |
| Maturity | candidate, implemented, verified, deprecated |

---

# Capability Lifecycle

```text
Candidate
    -> Designed
    -> Implemented
    -> Verified
    -> Operationally Supported
    -> Deprecated or Superseded
```

A capability can exist architecturally before a complete exercise exists. The maturity field prevents that distinction from being lost.

---

# Candidate DNS Capability Decomposition

## Recursive DNS

Potential sub-capabilities:

- resolver fundamentals;
- cache behavior;
- forwarding and recursion;
- root priming and local root;
- RPZ;
- DNS64;
- validation troubleshooting.

## Authoritative DNS

Potential sub-capabilities:

- zone construction;
- primary/secondary transfer;
- delegation;
- multi-implementation secondary service;
- reverse DNS;
- lame and intentionally broken authority scenarios.

## DNSSEC

Potential sub-capabilities:

- validation;
- manual signing;
- automatic signing;
- ZSK and KSK rollover;
- CDS-driven DS automation;
- insecure delegation transitions;
- failure diagnosis.

## DNS Monitoring

Candidate functions:

- query and response metrics;
- authoritative health;
- resolver health;
- DNSSEC expiry and validation state;
- deployment readiness dashboards.

## Universal Acceptance

Candidate functions:

- IDN-aware DNS names;
- EAI and mailbox handling;
- application acceptance testing;
- punycode and Unicode troubleshooting.

## Additional candidates

Candidates requiring separate review include DNS privacy, transport encryption, and more advanced traffic-observation scenarios. They should not be added merely because software support exists.

---

# Candidate Routing Capability Decomposition

## BGP

- session establishment;
- IPv4 and IPv6 unicast;
- route advertisement and withdrawal;
- policy and filtering;
- path selection;
- troubleshooting;
- external peering through a controlled border.

## Anycast

- service-prefix ownership;
- identical service announcements;
- failure and withdrawal behavior;
- traffic steering and observation;
- IPv4 and IPv6;
- interaction with RPKI.

## RPKI

- validator synchronization;
- TAL and repository operation;
- RTR service;
- router cache sessions;
- validation states;
- policy application;
- ROA change and failure scenarios.

---

# Platform Capabilities

Some selectable behavior is not a training-domain capability but may still need explicit configuration:

- WebSSH access;
- public DNS exposure;
- participant instructions;
- NAT64;
- external WireGuard connectivity;
- monitoring;
- shared or per-group credentials;
- shared or per-group validators.

These should be modeled as platform features or deployment options, not mixed into the training taxonomy.

---

# Training Profiles

A profile is a reviewed capability set with operational defaults.

Candidate named profiles:

| Profile | Example capability selection |
|---|---|
| Recursive DNS Fundamentals | Recursive DNS, DNSSEC validation, tools |
| Full DNS Operations | Recursive DNS, Authoritative DNS, DNSSEC |
| Resolver Security | Recursive DNS, RPZ, DNSSEC validation |
| Secure Routing Fundamentals | BGP, shared RPKI |
| Group RPKI Operations | BGP, per-group RPKI |
| Anycast Service Operations | BGP, Anycast, optional RPKI |

The current Types 1-4 can map to compatibility profiles while the new model is introduced.

---

# Composition Rules

A future planner should derive resources rather than let each capability independently create duplicates.

Example:

```text
Recursive DNS requires:
    client + router + resolver roles

Authoritative DNS requires:
    SOA + authoritative secondaries + public query routing

Both selected:
    share the same client, router, networks, credentials, and platform services
```

Shared services must be created once, with capabilities registering required behavior through explicit interfaces.

---

# Open Questions

- What is the minimum stable capability granularity?
- Which behaviors are capabilities versus exercise variants?
- How are conflicting options represented?
- How are resource estimates aggregated?
- How are instructor activation steps represented?
- Should monitoring be mandatory for every supported profile?
- Which capabilities require public Internet reachability?
- How are experimental capabilities labeled and isolated?

---

# Acceptance Criteria for the Model

The model is ready for ADR review when it can:

- represent current Types 1 and 2 without losing behavior;
- represent intended Types 3 and 4;
- prevent nonexistent resources such as resolver-only group authoritative backends;
- derive shared and per-group dependencies;
- express validation and cleanup;
- estimate resources by group count;
- preserve backward-compatible named profiles;
- distinguish implemented from verified support.

---

# Related Documents

- [`../architecture/00-architecture-map.md`](../architecture/00-architecture-map.md)
- [`future-orchestrator.md`](future-orchestrator.md)
- [`future-modularity.md`](future-modularity.md)
- [`../architecture/KNOWLEDGE-BASE.md`](../architecture/KNOWLEDGE-BASE.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)

---

# Review Status

**Current Status:** Draft

**Next Review:** After current hardening clarifies the required platform-feature model and routing recovery clarifies capability dependencies.
