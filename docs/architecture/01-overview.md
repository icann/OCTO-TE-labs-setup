# Platform Overview

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document provides a high-level overview of OCTO-TE Labs: what the platform is, the problems it addresses, the current verified scope, and the engineering qualities it is expected to preserve.

---

# What Is OCTO-TE Labs?

OCTO-TE Labs is a deployment platform for hands-on training on Internet infrastructure technologies.

It creates isolated environments in which participants can configure, test, break, troubleshoot, and restore realistic DNS, DNSSEC, routing, Anycast, and RPKI systems without affecting production infrastructure.

The platform supports instructor-led workshops and can also support guided self-paced exercises when the required operational supervision is available.

---

# Problems Addressed

The platform is intended to reduce several recurring training challenges:

- manually building many equivalent participant environments;
- reproducing dual-stack and DNSSEC behavior consistently;
- exposing selected services to public Internet testing tools;
- isolating participant changes by group;
- managing credentials and browser/SSH access;
- cleaning up AWS and DNS state after the event;
- scaling the same topology from a few groups to large workshops;
- preserving a repeatable engineering baseline across events.

---

# Project Goals

- Provide realistic laboratory environments.
- Automate infrastructure and participant-topology deployment.
- Reduce operational complexity for instructors.
- Support repeatable and measurable deployments.
- Isolate participant groups while retaining controlled shared services.
- Support IPv4 and IPv6.
- Support DNSSEC and secure-routing exercises.
- Allow internal wipe and redeployment without replacing the EC2 host.
- Enable future capability composition without discarding proven profiles.
- Preserve engineering knowledge and decisions in the Handbook.

---

# Training Philosophy

Training is organized conceptually around capabilities rather than products.

Examples:

- Recursive DNS is a capability; BIND and Unbound are implementations used to teach it.
- Authoritative DNS is a capability; BIND and NSD are implementations used to teach it.
- BGP and RPKI are capabilities; FRRouting and FORT are current implementation choices.

The environment should resemble operational systems closely enough to teach real practices while remaining safe to reset and reproduce.

---

# Current Training Domains

## DNS

Architectural capabilities:

- Recursive DNS;
- Authoritative DNS;
- DNSSEC;
- DNS Monitoring;
- Universal Acceptance.

The current implementation and participant material most directly exercise recursive DNS, authoritative DNS, DNSSEC, troubleshooting, RPZ, and DNS64/NAT64 scenarios. Monitoring and Universal Acceptance remain capability areas whose exercise coverage must be assessed separately.

## Routing

Architectural capabilities:

- BGP;
- Anycast;
- RPKI.

The repository contains group-router, border-router, WireGuard, shared-validator, per-group-validator, and RPKI-aware FRRouting components. The routing profiles are not yet production-verified in the current baseline.

---

# Deployment Model

The current implementation uses a two-level deployment model:

```text
AWS CloudFormation
    -> creates one dual-stack EC2 host and supporting AWS resources

EC2 cloud-init and shell orchestration
    -> prepares LXD templates
    -> creates shared services
    -> creates one isolated topology per group
```

This model keeps the cloud footprint simple while allowing many containers and networks inside one host.

---

# Shared and Per-Group Resources

## Shared resources

Examples:

- EC2 host and LXD daemon;
- backbone bridge;
- public DNS frontend;
- platform authoritative DNS;
- exercise authoritative and RPZ services;
- nginx, WebSSH, certificates, instructions, and cron;
- optional border router and global RPKI validators.

## Per-group resources

Every selected group receives a router and four LXD networks. Additional containers depend on the profile:

- client;
- two resolvers;
- SOA/primary and two authoritative servers;
- optional RPKI validator.

---

# Current Profile Model

The implementation currently exposes four numeric Lab Types:

| Type | Current purpose | Validation state |
|---:|---|---|
| 1 | Resolver practice | Verified |
| 2 | Full DNS practice | Verified |
| 3 | Routing/Anycast with shared RPKI | Under recovery; known defects |
| 4 | Routing/Anycast with per-group RPKI | Under recovery; known defects |

Numeric profiles are retained for compatibility. The future architecture is expected to derive named profiles from explicit capabilities.

---

# Verified Baseline

The August 2026 baseline verified:

- CloudFormation creation and deletion;
- `cloud-init` completion criteria;
- Lab Types 1 and 2;
- internal Type 1 to Type 2 redeployment;
- public IPv4 and IPv6 DNS;
- DNSSEC validation using external recursive resolvers;
- DS cleanup and immediate reuse of a DNS name;
- DNS labels containing hyphens;
- main HTTPS site and WebSSH publication;
- 60-group resolver deployment with 247 real LXD instances;
- removal of unnecessary `dnsdist` group backends in resolver-only profiles.

The baseline also identified serious hardening work, including WebSSH access control, fixed bootstrap credentials, firewall/NAT64 cleanup, dependency reproducibility, routing-profile defects, and higher-scale validation.

---

# Platform Characteristics

## Repeatable

The same source branch and rendered deployment artifacts should produce an equivalent environment. Runtime dependency drift currently limits perfect reproducibility and is a hardening target.

## Isolated

Each group has independent networks and role containers, connected through its own router.

## Dual-stack

Public and internal IPv4/IPv6 behavior is part of the platform, not an optional afterthought.

## Lifecycle-oriented

Create, validate, activate, redeploy, stop/start, delete, and cleanup are all part of the platform lifecycle.

## Capability-oriented

Training goals are described as capabilities even though the current orchestrator still selects fixed profiles.

## Evidence-based

Claims of support require code inspection and deployment validation. Partial implementations are documented as partial.

## Scalable by design

The original architecture demonstrated more than 100 groups. The current branch prepares routes beyond its 64-group orchestrator limit, but higher scale must be recovered and measured before being claimed as supported.

---

# Intended Audience

The Handbook is intended for:

- platform maintainers;
- developers and contributors;
- technical architects;
- instructors preparing or troubleshooting labs;
- reviewers responsible for security, reliability, and capacity.

Participant instructions and exercise steps are maintained separately.

---

# Scope Boundaries

This overview does not define exact addresses, ports, commands, or implementation details. Those are documented under:

- [`02-deployment-flow.md`](02-deployment-flow.md);
- [`08-implementation.md`](08-implementation.md);
- [`../reference/`](../reference/README.md).

Future proposals are under [`../design/`](../design/README.md) and must not be interpreted as current behavior.

---

# Success Criteria

A healthy platform evolution should improve or preserve:

- training realism;
- deployment reliability;
- participant isolation;
- instructor usability;
- security of public interfaces and credentials;
- cleanup completeness;
- reproducibility;
- measured capacity;
- documentation accuracy;
- backward compatibility where it has operational value.

---

# Review Status

**Current Status:** In Review

**Next Review:** After the hardening phase changes the verified operational baseline.
