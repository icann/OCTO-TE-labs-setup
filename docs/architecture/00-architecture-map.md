# Architecture Map

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document is the conceptual entry point to the OCTO-TE Labs architecture.

It explains how the platform is organized without treating the current CloudFormation template, shell scripts, LXD layout, or numeric Lab Types as permanent architectural constraints.

---

# Architectural Model

OCTO-TE Labs is an engineering platform for hands-on Internet infrastructure training.

The architecture is organized around five related concerns:

1. training domains;
2. training capabilities;
3. training profiles;
4. shared platform services;
5. platform infrastructure and lifecycle.

Engineering governance, decisions, evidence, and accumulated knowledge apply across all five concerns.

---

# Conceptual Architecture

```text
OCTO-TE Labs
|
+-- Training Domains
|     |
|     +-- DNS
|     |     +-- Recursive DNS
|     |     +-- Authoritative DNS
|     |     +-- DNSSEC
|     |     +-- DNS Monitoring
|     |     +-- Universal Acceptance
|     |
|     +-- Routing
|           +-- BGP
|           +-- Anycast
|           +-- RPKI
|
+-- Training Profiles
|     +-- coherent capability selections
|     +-- participant roles
|     +-- resource and validation expectations
|
+-- Shared Platform Services
|     +-- public DNS frontend and platform authority
|     +-- web access and WebSSH
|     +-- authentication and credentials
|     +-- certificates
|     +-- participant instructions
|     +-- lifecycle and cleanup support
|
+-- Platform Infrastructure
      +-- cloud resources
      +-- EC2 host
      +-- LXD/LXC containers
      +-- networking and storage
      +-- deployment orchestration
      +-- observability and validation
```

The current numeric Lab Types are implementation profiles. They are not the final capability-composition model.

---

# Training Domains

A training domain groups related Internet infrastructure subjects.

The current domains are:

- DNS;
- Routing.

Additional domains may be introduced when they fit the same model of isolated, reproducible, hands-on training.

---

# Capabilities

A capability is a technical subject or operational function that can be taught, deployed, and validated independently or as part of a profile.

## DNS capabilities

- Recursive DNS;
- Authoritative DNS;
- DNSSEC;
- DNS Monitoring;
- Universal Acceptance.

## Routing capabilities

- BGP;
- Anycast;
- RPKI.

Capability names describe the training objective, not a specific software implementation. BIND, Unbound, NSD, FRRouting, and FORT are current implementation choices.

---

# Training Profiles

A Training Profile combines capabilities into a coherent exercise environment.

A profile should define:

- enabled capabilities;
- required participant and shared roles;
- network topology;
- resource expectations;
- activation steps;
- validation criteria;
- cleanup requirements.

The current implementation exposes four numeric Lab Types. Types 1 and 2 are verified DNS profiles. Types 3 and 4 are routing/RPKI profiles under recovery.

The future direction is to retain named profiles while deriving their implementation from explicit capability selections.

---

# Shared Platform Services

Platform services support training but are not themselves training-domain capabilities.

Current examples include:

- `dnsdist` public DNS frontend;
- `ns1` platform authoritative DNS;
- `auth-exercise` and `auth-rpz` exercise services;
- nginx and WebSSH;
- authentication and credential generation;
- certificate management;
- participant-instruction publication;
- Route 53 and DNSSEC lifecycle integration;
- stack cleanup and validation support.

Shared services must have explicit ownership and lifecycle boundaries. ADR-0002 formalizes the current DNS-service separation.

---

# Platform Infrastructure

Platform infrastructure provides the execution environment:

- AWS CloudFormation, EC2, VPC, IAM, S3, Lambda, and Route 53;
- Ubuntu host services;
- LXD/LXC templates and instances;
- ZFS-backed storage;
- dual-stack backbone and per-group networks;
- NAT, NAT64, and optional external routing integration;
- shell orchestration and configuration templates.

Infrastructure is an implementation concern, but lifecycle safety, security, reproducibility, and measurable capacity are architectural requirements.

---

# Lifecycle Model

```text
publish deployment artifacts
    -> create AWS resources
    -> bootstrap EC2 host
    -> prepare container templates
    -> deploy selected profile
    -> activate exercises
    -> validate services and DNSSEC
    -> operate or internally redeploy
    -> delete stack and clean external state
```

A deployment is not ready merely because CloudFormation reports `CREATE_COMPLETE`. The internal `cloud-init` and orchestration lifecycle must also complete successfully.

---

# Current-State Boundary

The current verified baseline includes:

- Lab Types 1 and 2;
- shared DNS-service separation;
- public IPv4 and IPv6 DNS;
- DNSSEC and DS lifecycle;
- HTTPS and WebSSH publication;
- internal wipe/redeploy;
- stack cleanup and name reuse;
- resolver scaling to 60 groups.

The following remain incomplete or unverified:

- production-ready Lab Types 3 and 4;
- WireGuard ingress and parameter alignment;
- per-group RPKI validator creation;
- secure WebSSH access control;
- removal of fixed bootstrap credentials;
- idempotent NAT64 and firewall cleanup;
- recovery and measurement above the current 64-group limit.

---

# Architecture, Implementation, and Design

The Handbook separates three views:

| View | Meaning |
|---|---|
| Architecture | Stable concepts, responsibilities, and relationships |
| Implementation | How the current `nico` branch realizes the architecture |
| Future Design | Proposed evolution that is not yet current behavior |

This separation prevents a temporary implementation detail from becoming an accidental permanent architecture.

---

# Handbook Map

| Document | Responsibility |
|---|---|
| [`01-overview.md`](01-overview.md) | Platform purpose, audience, and current scope |
| [`02-deployment-flow.md`](02-deployment-flow.md) | End-to-end lifecycle |
| [`03-orchestrator.md`](03-orchestrator.md) | Current shell orchestration |
| [`04-network-topology.md`](04-network-topology.md) | Network architecture and current topology |
| [`05-dns-capabilities.md`](05-dns-capabilities.md) | DNS capability architecture and verified behavior |
| [`06-routing-capabilities.md`](06-routing-capabilities.md) | Routing/RPKI capability architecture and recovery state |
| [`07-platform-services.md`](07-platform-services.md) | Shared services and security findings |
| [`08-implementation.md`](08-implementation.md) | Current implementation map |
| [`ENGINEERING-PRINCIPLES.md`](ENGINEERING-PRINCIPLES.md) | Engineering rules and documentation standards |
| [`KNOWLEDGE-BASE.md`](KNOWLEDGE-BASE.md) | Durable engineering knowledge |

Related material:

- exact values under [`../reference/`](../reference/README.md);
- decisions under [`../decisions/`](../decisions/README.md);
- future proposals under [`../design/`](../design/README.md);
- work tracking under [`../development/`](../development/README.md).

---

# Review Status

**Current Status:** In Review

**Next Review:** When a capability-driven orchestration proposal is promoted from Draft design to an ADR.
