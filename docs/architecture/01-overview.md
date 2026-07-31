# Platform Overview

**Status:** In Review

**Last Updated:** 2026-07-31

---

# Purpose

This document provides a high-level overview of the OCTO-TE Labs platform.

It explains the purpose of the project, the problems it addresses, and the scope of the platform without describing implementation details.

---

# What is OCTO-TE Labs?

OCTO-TE Labs is a platform for delivering hands-on technical training on Internet infrastructure technologies.

The platform enables instructors to deploy complete laboratory environments where participants can learn, configure, test, and troubleshoot real-world Internet technologies in isolated environments.

The platform is designed to support both instructor-led and self-paced training.

---

# Project Goals

The primary goals of the platform are:

- Provide realistic laboratory environments.
- Automate laboratory deployment.
- Reduce operational complexity for instructors.
- Allow laboratories to be reproduced consistently.
- Support multiple Internet infrastructure technologies.
- Enable future expansion through new capabilities.

---

# Training Philosophy

Training is organized around technical capabilities rather than around individual software products.

Participants learn concepts and operational practices using realistic environments that resemble production deployments while remaining safe for experimentation.

---

# Current Training Domains

The current architecture supports the following training domains:

## DNS

Capabilities currently identified include:

- Recursive DNS
- Authoritative DNS
- DNSSEC
- Universal Acceptance
- DNS Monitoring

---

## Routing

Capabilities currently identified include:

- BGP
- Anycast
- RPKI

Additional routing capabilities may be incorporated over time.

---

# Platform Characteristics

The platform is designed around the following characteristics:

- Repeatable deployments
- Automated provisioning
- Isolated laboratory environments
- Capability-based organization
- Modular evolution
- Shared platform services
- Infrastructure independence at the architectural level

---

# Intended Audience

This handbook is intended for:

- Platform maintainers
- Developers
- Instructors
- Contributors
- Technical architects

Training material intended for participants is documented separately.

---

# Relationship with the Handbook

This overview introduces the platform.

The remaining architecture documents progressively describe:

- conceptual architecture
- deployment lifecycle
- orchestration
- networking
- platform services
- implementation

---

# Scope

This document intentionally avoids implementation details.

Its purpose is to explain what the platform is and the engineering objectives it serves.

---

# Review Status

**Current Status**

In Review

**Next Review**

After completion of EPIC-001.