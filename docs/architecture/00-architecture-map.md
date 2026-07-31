# Architecture Map

**Status:** In Review

**Last Updated:** 2026-07-31

---

# Purpose

This document provides the conceptual map of the OCTO-TE Labs platform.

It introduces the architectural organization of the project and serves as the entry point to the Architecture & Engineering Handbook.

Rather than describing implementation details, this document explains how the platform is conceptually structured.

---

# Architectural Model

OCTO-TE Labs is an engineering platform for Internet infrastructure training.

The architecture is organized in four conceptual layers:

1. Training Domains
2. Capabilities
3. Platform Services
4. Platform Infrastructure

Implementation details are intentionally documented separately.

---

# Conceptual Architecture

```text
OCTO-TE Labs
│
├── Training Domains
│
│   ├── DNS
│   │
│   │   ├── Recursive DNS
│   │   ├── Authoritative DNS
│   │   ├── DNSSEC
│   │   ├── Universal Acceptance
│   │   └── DNS Monitoring
│   │
│   └── Routing
│
│       ├── BGP
│       ├── Anycast
│       └── RPKI
│
├── Platform Services
│
│   ├── WebSSH
│   ├── Lab Instructions
│   ├── Authentication
│   ├── Certificate Management
│   └── Platform Monitoring
│
└── Platform Infrastructure
    │
    ├── Cloud Infrastructure
    ├── Virtual Machines
    ├── Container Platform
    ├── Networking
    └── Storage
```

---

# Training Domains

Training Domains represent the educational areas supported by the platform.

A domain groups together related capabilities that can be combined to build one or more laboratory experiences.

Current domains are:

- DNS
- Routing

The architecture allows additional domains to be introduced without changing the overall platform model.

---

# Capabilities

Capabilities are the fundamental building blocks of the platform.

A capability represents a technical subject that can be taught independently or combined with other capabilities.

Examples include:

DNS:

- Recursive DNS
- Authoritative DNS
- DNSSEC
- Universal Acceptance
- DNS Monitoring

Routing:

- BGP
- Anycast
- RPKI

Capabilities are intentionally independent from their implementation.

---

# Platform Services

Platform Services provide functionality shared across all training domains.

They support the operation of laboratories but are not themselves training capabilities.

Examples include:

- Web-based SSH access
- Participant instructions
- Authentication
- Certificate management
- Platform monitoring

---

# Platform Infrastructure

Platform Infrastructure provides the execution environment required by the platform.

It includes cloud resources, virtual machines, container technologies, networking, and storage.

Infrastructure is considered an implementation concern rather than a training capability.

---

# Relationship with the Handbook

The documents in this handbook progressively refine the architecture introduced here.

| Document | Description |
|----------|-------------|
| 01-overview.md | General overview of the platform |
| 02-deployment-flow.md | Lifecycle of a laboratory deployment |
| 03-orchestrator.md | Architecture of the orchestration layer |
| 04-network-topology.md | Network architecture |
| 05-dns-capabilities.md | DNS capabilities |
| 06-routing-capabilities.md | Routing capabilities |
| 07-platform-services.md | Shared platform services |
| 08-implementation.md | Current implementation architecture |
| KNOWLEDGE-BASE.md | Engineering knowledge accumulated over time |

---

# Scope

This document intentionally avoids implementation details.

Its purpose is to provide a stable conceptual view of the platform that remains valid as the implementation evolves.

---

# Review Status

**Current Status**

In Review

**Next Review**

After completion of EPIC-001.