# Laboratory Profiles and Types

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document is the current reference for the numeric Lab Types implemented by `scripts/setup-lab.sh`.

Lab Types are implementation profiles. They map a numeric selection to internal component flags. They are not the long-term capability model described in future-design documents.

---

# Supported Group Count

The current orchestrator accepts:

```text
3-64 groups
```

CloudFormation accepts the participant value as a string, but the final range check occurs in `setup-lab.sh`. Higher scale is a planned recovery task.

---

# Components Present in All Current Profiles

## Stopped templates

| Container | Purpose |
|---|---|
| `hostX` | base general-purpose container |
| `rtrX` | base router container |
| `fortX` | base RPKI validator container |

## Running shared DNS containers

| Container | Purpose |
|---|---|
| `ns1` | platform authoritative DNS and DNSSEC signer |
| `auth-exercise` | exercise authoritative data and special targets |
| `auth-rpz` | RPZ authoritative distribution service |
| `dnsdist` | public DNS frontend |

## Per-group base topology

Every selected group receives:

- `grpN-rtr`;
- `grpN-lan`;
- `grpN-int`;
- `grpN-dmz`;
- `grpN-extra`.

NAT64 is currently created on the host for every profile. Making it optional is planned.

---

# Lab Type 1 - Resolver

## Intended training scope

- recursive DNS;
- resolver configuration;
- cache and troubleshooting;
- DNSSEC validation;
- RPZ exercises;
- DNS64 exercises when selected by the instructor.

## Per-group containers

| Container | Created |
|---|---:|
| `grpN-rtr` | Yes |
| `grpN-cli` | Yes |
| `grpN-resolv1` | Yes |
| `grpN-resolv2` | Yes |
| `grpN-soa` | No |
| `grpN-ns1` | No |
| `grpN-ns2` | No |
| `grpN-rpki` | No |

## dnsdist behavior

No group-authoritative pools are generated. `dnsdist` has only the platform authoritative backend. The platform zone still contains the generated `grpN` NS delegation entries, but Type 1 does not provide participant authoritative service for those child zones. Conditioning delegation generation on `StudentAuth` is pending.

## Count formula

Ignoring host processes and the NAT64 interface:

```text
4 containers per group + 7 shared/templates
```

Examples:

| Groups | LXD instances |
|---:|---:|
| 3 | 19 |
| 60 | 247 |

Both examples were verified in August 2026.

---

# Lab Type 2 - Full DNS

## Intended training scope

- all resolver topics;
- authoritative DNS;
- zones and delegation;
- primary and secondary operation;
- BIND and NSD;
- DNSSEC signing and rollover;
- CDS-based DS automation;
- public testing through dnsdist.

## Per-group containers

| Container | Created |
|---|---:|
| `grpN-rtr` | Yes |
| `grpN-cli` | Yes |
| `grpN-resolv1` | Yes |
| `grpN-resolv2` | Yes |
| `grpN-soa` | Yes |
| `grpN-ns1` | Yes |
| `grpN-ns2` | Yes |
| `grpN-rpki` | No |

## dnsdist behavior

Each group receives four backend objects in its pool:

```text
grpN-ns1 IPv4
grpN-ns1 IPv6
grpN-ns2 IPv4
grpN-ns2 IPv6
```

DS queries for `grpN.<DOMAIN>` are kept on the platform authority. Other queries at or below the group zone use the group pool.

For 3 groups, the expected `newServer()` count is:

```text
3 groups x 4 group backends + 1 platform backend = 13
```

This was verified after internal redeployment from Type 1 to Type 2.

## Count formula

```text
7 containers per group + 7 shared/templates
```

For 3 groups, the expected total is 28 LXD instances.

---

# Lab Type 3 - Routing with Global RPKI

## Declared intent

- participant client and resolver environment;
- group authoritative DNS;
- group router access;
- Anycast/BGP practice;
- shared global RPKI validators;
- shared border router and VPN integration.

## Intended components

| Component | Intended |
|---|---:|
| client per group | Yes |
| two resolvers per group | Yes |
| SOA and two authoritative servers per group | Yes |
| group RPKI validator | No |
| shared global validators | Yes |
| border router | Yes |
| router access in web topology | Yes |

## Current implementation defect

The Type 3 case sets:

```text
StudentAuthServers=YES
```

while the rest of the implementation tests:

```text
StudentAuth
```

As a result, group authoritative containers and matching `dnsdist` pools are not reliably enabled. The border-router VPN path also depends on a WireGuard UDP port that is not exposed by the current CloudFormation security group. Type 3 is therefore **not production-verified** and must be corrected and regression-tested before operational use.

Do not use the intended container-count formula as a current guarantee.

---

# Lab Type 4 - Routing with Group RPKI

## Declared intent

- client, resolver, and authoritative DNS environment;
- router access;
- Anycast/BGP practice;
- one RPKI validator per group;
- shared border router and VPN integration.

## Per-group components

| Container | Intended |
|---|---:|
| `grpN-rtr` | Yes |
| `grpN-cli` | Yes |
| `grpN-resolv1` | Yes |
| `grpN-resolv2` | Yes |
| `grpN-soa` | Yes |
| `grpN-ns1` | Yes |
| `grpN-ns2` | Yes |
| `grpN-rpki` | Yes |

A shared `iborder-rtr` is also enabled. The current CloudFormation security group does not expose the configured WireGuard UDP listen port, so routing-profile VPN ingress requires correction and validation.

## Status

The profile mapping is present in the current code, but the full profile has not received the same August 2026 end-to-end regression coverage as Types 1 and 2. In addition, `validators.sh` currently copies `RPKIfortX`, while `setup-containers.sh` creates the base template as `fortX`; this naming mismatch is expected to block per-group validator creation until corrected. Validate resource limits, FORT behavior, BGP, VPN, RPKI data, and cleanup before production use.

---

# Provisioned Versus Exercise-Ready

For Types 1 and 2, platform deployment creates the participant containers and network topology. The DNS daemons used by the participant exercise are installed later.

Before running the exercise activation script, the participant DNS containers can exist with no service listening on port 53.

The instructor activates one group or all groups with:

```bash
cd /root/scripts
./do-dns-lab.sh 1
./do-dns-lab.sh all
```

The script configures the intended software roles:

| Role | Software |
|---|---|
| `resolv1` | BIND |
| `resolv2` | Unbound |
| `soa` | BIND |
| `ns1` | BIND secondary |
| `ns2` | NSD secondary |

This distinction is essential when validating whether a deployment is ready as a platform or ready as a completed exercise.

---

# Internal Profile Change

An existing EC2 host can be wiped and changed to another profile:

```bash
cd /root/scripts
./setup-lab.sh --deploy --type <1-4> --networks <3-64>
```

The command deletes the current internal environment before rebuilding. It does not update CloudFormation or replace the EC2 instance. The command-line values are not written back to `deploy-parameters.cfg`; edit that file for a persistent change or repeat the overrides on later lifecycle commands.

---

# Current Validation Status

| Profile | CloudFormation | Internal deployment | Shared DNS | Participant DNS activation | Routing/RPKI |
|---|---:|---:|---:|---:|---:|
| Type 1 | Verified | Verified | Verified | Verified for sampled groups | Not applicable |
| Type 2 | Verified | Verified | Verified | Verified for sampled groups | Not applicable |
| Type 3 | Partial | Known flag defect | Requires retest | Requires retest | Requires recovery/testing |
| Type 4 | Partial | Known RPKI template-name defect; requires full retest | Requires retest | Requires retest | Requires recovery/testing |

---

# Review Status

**Current Status:** In Review

**Next Review:** After correction and end-to-end testing of Lab Types 3 and 4.
