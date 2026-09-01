# Current Implementation

**Status:** In Review

**Last Updated:** 2026-09-01

---

# Purpose

This document maps the current `nico` branch implementation to the OCTO-TE Labs architecture.

It is an implementation snapshot, not a future design. The baseline was reviewed through implementation commit `dc719a4` and includes deployment validation completed on 2026-09-01.

---

# Repository Layout

| Path | Responsibility |
|---|---|
| `lab-ec2.yaml` | CloudFormation infrastructure and EC2 UserData |
| `.github/workflows/` | render placeholders and publish branch content to S3 |
| `scripts/setup-host.sh` | prepare the Ubuntu EC2 host |
| `scripts/setup-containers.sh` | prepare reusable LXD container templates |
| `scripts/setup-lab.sh` | lifecycle and profile orchestration |
| `scripts/lab-tools/` | component-specific create/start/stop/delete functions |
| `scripts/do-dns-lab.sh` | activate participant DNS exercise services |
| `configs/` | source configuration templates copied or rendered by scripts |
| `docs/` | Architecture & Engineering Handbook |

---

# AWS Infrastructure

The CloudFormation template creates a single-host lab environment.

## Networking

- VPC: `10.0.0.0/16`.
- Public subnet: `10.0.1.0/24`.
- Amazon-provided VPC IPv6 block and `/64` subnet.
- Internet gateway.
- IPv4 and IPv6 default routes.
- Elastic IPv4 address associated with the EC2 instance.
- Security-group access for SSH on TCP/8484, DNS on TCP/UDP 53, HTTP on TCP/80, and HTTPS on TCP/443 over IPv4 and IPv6.
- The routing-profile WireGuard UDP listen port is not currently present in the CloudFormation security group and requires correction before routing-profile production use.

## Compute and storage

- One Ubuntu 24.04 Noble x86_64 EC2 instance.
- Instance type selected by `labInstanceType`; current template default `r4.2xlarge`.
- Encrypted 512 GiB gp3 root volume.
- Public SSH key injected through an AWS EC2 key-pair resource.

## IAM

The EC2 role permits:

- reading deployment objects from the branch S3 bucket;
- listing and updating Route 53 records required by the DNSSEC lifecycle.

Lambda roles provide:

- EC2 network-interface discovery for the public IPv6 address;
- Route 53 DS cleanup during stack deletion.

The IPv6 Lambda role and DS cleanup role do not use a fixed global `RoleName`, avoiding collisions among concurrent stacks.

## Route 53

CloudFormation manages:

- the delegated lab NS record;
- `ns1.<DOMAIN>` A and AAAA glue;
- `ec2-<DOMAIN>` A and AAAA access records.

The internal deployment manages:

- the signed lab zone;
- the DS record in the parent zone.

The stack-delete custom resource removes the DS because it is not a native CloudFormation `RecordSet` resource.

---

# CloudFormation Operator Interface

The template uses `AWS::CloudFormation::Interface` metadata to replace the console's default alphabetical presentation with five groups:

```text
Lab Identity
Lab Configuration
Lab Instructions
Access
Advanced Deployment
```

Friendly labels are shown in the console while logical parameter IDs remain unchanged for CLI/API use. `IntegratedInstructions` and `labInstructions` are intentionally adjacent because one controls the capability and the other supplies its source.

The current Quick Create path can pre-fill `LAB-YYYYMMDD-LOCATION`. The stack is created in the active CloudFormation console region; the current `nico` template artifact is served from S3 in `us-east-1`.

`DnsName` remains a 3-32 character lowercase DNS label with digits and internal hyphens. Its combined constraint message includes both length and syntax because CloudFormation exposes one user-facing message for these violations.

---
# AMI Selection

Normal deployments use the SSM parameter for Canonical's current Ubuntu 24.04 Noble stable AMI.

The optional `AmiOverride` parameter allows an existing stack update to retain the AMI already used by its EC2 instance. This avoids an unintended replacement caused only by movement of the `stable/current` SSM target.

`AmiOverride` is empty by default and should remain empty for normal new stacks. The template path has been validated, but a live update change set using the override remains pending.

---

# EC2 Host Services

The host provides functionality that is not placed in LXD containers:

- LXD daemon and storage pool;
- `net-bb` backbone bridge;
- host routing and NAT;
- temporary DHCP used during template/container initialization;
- TAYGA NAT64 service;
- nginx;
- WebSSH service;
- Certbot and TLS material;
- PHP-FPM for generated web pages;
- cron jobs;
- AWS CLI;
- documentation build toolchain.

The current host applies high-scale sysctl values, creates up to 10 GiB of swap, and prepares routes beyond the current 64-group shell limit.

---

# LXD Configuration

The current LXD preseed creates the default project, storage, and profile used by the lab.

The default profile includes:

- root disk from the project storage pool;
- `eth0` attached to `net-bb`;
- `limits.memory: 2GB`.

The 2 GB value is a per-container safety ceiling. It does not reserve 2 GB for every container.

Known exceptions include:

- `dnsdist`, explicitly raised to 8 GB;
- RPKI validator roles, planned to use an 8 GB ceiling where global ROA processing requires it.

---

# Base Templates

| Template | Purpose | Normal state |
|---|---|---|
| `hostX` | base for clients, resolvers, authoritative servers, and shared service containers | Stopped |
| `rtrX` | base router with FRRouting components | Stopped |
| `fortX` | base for FORT/RPKI validator work | Stopped |

Templates are copied to create deployment instances. They remain present after a normal deployment and account for three stopped instances in measured container totals.

---

# Shared DNS Infrastructure

| Container | Role | IPv4 | IPv6 |
|---|---|---|---|
| `dnsdist` | public DNS frontend and dispatcher | `100.64.0.53` | `fd89:59e0::53` |
| `ns1` | platform authoritative DNS and DNSSEC signer | `100.64.0.54` | `fd89:59e0::54` |
| `auth-exercise` | exercise authority and special authoritative targets | `100.64.0.55-100.64.0.57` | `fd89:59e0::55`, `fd89:59e0::56`, `fd89:59e0::57` |
| `auth-rpz` | authoritative RPZ distribution service | `100.64.0.58` | `fd89:59e0::58` |

## dnsdist

`dnsdist` listens on its internal IPv4 and IPv6 addresses. Host DNAT publishes UDP/TCP 53 from the EC2 public addresses.

It rejects DNS UPDATE, NOTIFY, AXFR, IXFR, and CHAOS queries at the public frontend.

For Lab Type 1:

- one backend is registered: `auth-platform`;
- no group authoritative pools are created.

For profiles with `StudentAuth=YES`:

- each group receives a pool;
- `grpN-ns1` and `grpN-ns2` are registered over both IPv4 and IPv6;
- DS queries for `grpN.<DOMAIN>` remain directed to the platform authority;
- other group-zone queries are directed to the group pool.

## Platform authoritative DNS

`ns1` is authoritative-only and uses BIND DNSSEC policy automation. Its zone contains:

- apex A and AAAA;
- apex NS;
- `ns1` A and AAAA;
- `webssh` A and AAAA;
- `ipv4only` A;
- `ipv6only` AAAA;
- one `grpN` NS delegation for every selected group, currently generated regardless of `StudentAuth`;
- group DS records added dynamically by the CDS automation when CDS records are detected.

The initial SOA serial is currently fixed at `1`. Migration to a `YYYYMMDDnn` scheme is scheduled for hardening.

## Exercise authority

`auth-exercise` serves:

- `internal.`;
- `badnsname.internal.`;
- `evilnsip.internal.`.

The container carries `.55`, `.56`, and `.57` addresses so separate exercise authorities can be represented without additional containers.

## RPZ authority

`auth-rpz` serves the `rpz.` zone. `resolv1` obtains it as a secondary during the DNS exercise and applies policies such as NXDOMAIN, NODATA, DROP, TCP-only, passthrough, and local-data rewrites.

---

# Group Topology

Every selected group receives one router and four LXD networks.

| Network | IPv4 | IPv6 pattern |
|---|---|---|
| LAN | `100.100.N.0/26` | `fd89:59e0:N:0::/64` |
| Internal | `100.100.N.64/26` | `fd89:59e0:N:64::/64` |
| DMZ | `100.100.N.128/26` | `fd89:59e0:N:128::/64` |
| Extra | `100.100.N.192/26` | `fd89:59e0:N:192::/64` |

The current fixed ULA prefix is `fd89:59e0`. A dynamic per-deployment RFC 4193 prefix is a future scalability and isolation improvement.

## Common per-group roles

| Container | Role | Typical network |
|---|---|---|
| `grpN-rtr` | connects backbone, LAN, internal, DMZ, and extra networks | all group networks plus backbone |
| `grpN-cli` | participant workstation | LAN |
| `grpN-resolv1` | BIND resolver exercise target | internal |
| `grpN-resolv2` | Unbound resolver exercise target | internal |

## Authoritative roles

| Container | Role | Typical network |
|---|---|---|
| `grpN-soa` | primary/SOA exercise server | internal |
| `grpN-ns1` | authoritative secondary using BIND | DMZ |
| `grpN-ns2` | authoritative secondary using NSD | DMZ |

## RPKI roles

| Container | Role |
|---|---|
| `grpN-rpki` | validator assigned to a group, when enabled |
| `rpki1`, `rpki2` | shared validators for the global-validator profile |
| `iborder-rtr` | shared border/Anycast router and VPN endpoint |

Routing and RPKI roles are less comprehensively verified than DNS roles.

---

# Participant DNS Exercise Lifecycle

The platform deployment creates DNS participant containers but leaves their exercise services uninstalled or inactive.

`do-dns-lab.sh` later installs and configures:

- BIND on `resolv1`;
- Unbound on `resolv2`;
- BIND on `soa` and `ns1`;
- NSD on `ns2`.

This means a full DNS platform deployment and a completed participant DNS exercise are different states.

---

# Web and Authentication Implementation

The host publishes:

```text
https://<DOMAIN>
https://webssh.<DOMAIN>
```

nginx provides:

- the main lab site;
- per-group Basic Authentication;
- the WebSSH reverse proxy; the active WebSSH virtual host still lacks nginx-layer authentication and remains a priority hardening item;
- shared TLS configuration.

`passwords.sh` generates:

- one `labuser` password, optionally supplied by CloudFormation;
- one random password per group.

The credentials file is:

```text
/home/ubuntu/grouppasswords.txt
```

The generated topology pages link to WebSSH sessions for roles enabled in the selected profile.

Integrated instructions are independent of the profile. `web.sh` injects the **Lab instructions** link only when `IntegratedInstructions=YES`; `setup-lab.sh` then either calls the Jekyll-based builder or removes `/var/www/<DOMAIN>/html/grpN/instructions` for every selected group. The removal is unconditional, so custom content at that path is not preserved. Both modes were validated with clean three-group Type 1 deployments.

---

# DNSSEC Lifecycle

1. `ns1` loads the platform zone with `dnssec-policy default`.
2. BIND creates and activates the zone key.
3. the deployment extracts a DS from the DNSKEY;
4. the EC2 role performs an UPSERT in the parent Route 53 zone;
5. external resolvers validate the chain;
6. during stack deletion, `labDnsCleanup` finds and deletes the exact DS record set if present.

The cleanup resource is intentionally independent of the EC2 instance so that it still operates when the internal deployment failed or the EC2 is already being removed.

---

# Scalability Evidence

A resolver-only deployment with 60 groups was measured on an 8-vCPU host with approximately 59 GiB of RAM.

Verified final state before the `dnsdist` optimization:

- 247 real LXD instances;
- 244 running;
- 3 stopped templates;
- approximately 30 GiB used and 29 GiB available;
- negligible swap.

The 60 groups contributed:

- 60 routers;
- 60 clients;
- 60 `resolv1` containers;
- 60 `resolv2` containers.

The original `dnsdist` configuration incorrectly created 240 nonexistent group-authoritative backends in this Lab Type 1 deployment. It reached approximately 6.1 GiB RSS and 263 threads.

After the conditional fix, a 3-group Lab Type 1 deployment measured:

- 1 `newServer()`;
- 23 dnsdist threads;
- approximately 38 MiB dnsdist RSS;
- approximately 136 MiB container cgroup memory.

The same host redeployed as Lab Type 2 with 3 groups measured:

- 13 `newServer()` objects;
- 35 dnsdist threads;
- approximately 350 MiB dnsdist RSS;
- approximately 450 MiB container cgroup memory.

These measurements demonstrate the importance of backend count, but they are not sufficient alone to declare a maximum supported scale. Controlled 80/100+ group testing remains pending.

---

# Current Limitations and Hardening Backlog

- `setup-lab.sh` enforces 3-64 groups while the route plan extends further.
- Lab Type 3 uses `StudentAuthServers` instead of `StudentAuth`.
- platform `grpN` delegations are generated even when `StudentAuth=NO` and should be aligned with `dnsdist` pool generation.
- per-group RPKI creation references `RPKIfortX`, while `setup-containers.sh` creates `fortX`.
- routing-profile WireGuard ingress is missing from the current CloudFormation security group.
- the historical `-d` short option is not handled by `setup-lab.sh`.
- NAT64 is always deployed and is not yet selectable from CloudFormation.
- TAYGA teardown is not fully idempotent.
- Some iptables cleanup commands fail noisily when rules are absent.
- iptables legacy warnings remain.
- deployment resolves many external dependencies at runtime.
- the Jekyll toolchain emits root-user and Sass deprecation warnings when integrated instructions are enabled.
- the `YES` plus empty-source validation runs only after `wipe` in the current `--deploy` action; it should move ahead of destructive cleanup.
- disabling integrated instructions removes the entire per-group `instructions` path without ownership markers; custom-content preservation requires an explicit design decision.
- the publication workflow declares `us-east-2` for S3 synchronization while the current `nico` bucket is actually in `us-east-1`; the value should be aligned or derived.
- logs are excessively verbose and can expose generated credentials.
- SOA serials commonly start at `1` rather than `YYYYMMDDnn`.
- RPKI memory ceilings and runtime behavior require dedicated testing.
- dynamic ULA restoration remains pending.

---

# Review Status

**Current Status:** In Review

**Next Review:** After the hardening phase and higher-scale regression testing.
