# Software Stack Reference

**Status:** In Review

**Last Updated:** 2026-09-01

---

# Purpose

This document lists the principal operating systems, runtimes, packages, repositories, and tools used by the current OCTO-TE Labs implementation.

The platform resolves many dependencies at deployment time. Therefore exact package versions can differ among deployments even when the Git commit is unchanged.

---

# Operating Systems

| Layer | Current source |
|---|---|
| EC2 host | Ubuntu Server 24.04 LTS, Canonical Noble AMI from an SSM parameter unless overridden |
| LXD images | `ubuntu:24.04`, copied locally as alias `ubuntu` |
| Participant and shared containers | copies of the prepared Ubuntu template |

The optional `AmiOverride` pins the host AMI during an exceptional stack update. It does not pin container image or package versions.

---

# Container Platform

| Component | Use |
|---|---|
| LXD | container lifecycle |
| LXC CLI | operational interface used by scripts |
| ZFS | LXD storage pool |
| netplan | host and container network configuration |
| Linux bridges | backbone and group network switching |
| systemd | service management |
| cloud-init | host and copied-container initialization waits |

The LXD reference is in [`lxd.md`](lxd.md).

---

# Host Networking and System Packages

Principal host packages include:

- `zfsutils-linux`;
- `net-tools`;
- `dnsutils`;
- `traceroute`;
- `bridge-utils`;
- Open vSwitch DPDK package;
- `dnsmasq`;
- `iptables-persistent`;
- TAYGA;
- curl, wget, git, tree, and general administration tools.

The host also applies the project sysctl profile and creates swap when none exists.

---

# DNS Software

| Software | Role |
|---|---|
| BIND 9 | platform authority, exercise authority, RPZ authority, participant resolver and authoritative roles |
| Unbound | second participant resolver |
| NSD | participant authoritative secondary |
| dnsdist | public DNS frontend |
| BIND utilities | `dig`, `named-checkconf`, `named-checkzone`, DNSSEC tools |
| Knot utilities | additional DNS troubleshooting tools |
| PowerDNS repositories | package sources prepared in `hostX` |
| CZ.NIC repository | Knot package source |
| ISC BIND PPA | BIND package source |

Participant DNS daemons are installed by `do-dns-lab.sh`, not by the base platform deployment alone.

---

# Routing Software

| Software | Role |
|---|---|
| FRRouting | group and border routers |
| `bgpd` | BGP |
| `ospfd` | OSPFv2 |
| `ospf6d` | OSPFv3 |
| `vtysh` | participant/router administration |
| `frr-rpki-rtrlib` | RPKI integration |
| WireGuard | border-router VPN |

The router template uses the external FRRouting repository channel `frr-stable`.

A temporary upstream repository inconsistency caused an HTTP 404 deployment failure and later resolved without a code change. Version pinning and repository resilience remain pending.

---

# RPKI Software

| Software | Role |
|---|---|
| FORT Validator | validation and RPKI-RTR server |
| FRRouting RPKI module | origin-validation policy in routers |
| rsync/RRDP dependencies | repository synchronization |
| CSV output | validated ROA export |

The template downloads the latest FORT `.deb` release during base-container preparation and configures TCP/323 server mode.

The current per-group validator script contains a template-name mismatch and requires correction before Lab Type 4 is considered operational.

RPKI workloads may require an 8 GB memory ceiling rather than the normal 2 GB default.

---

# Web and Access Software

| Software | Role |
|---|---|
| nginx | HTTPS publication and reverse proxy |
| PHP-FPM | group web pages |
| Apache `htpasswd` tools | Basic Authentication files |
| WebSSH | browser SSH backend |
| OpenSSH | operator and participant access |
| Certbot | Let's Encrypt certificate lifecycle |
| OpenSSL | certificate inspection and DH parameters |

WebSSH is installed with `pip` and modified in place to raise its connection limit to 200.

---

# Documentation Toolchain

Current instruction generation uses:

- unzip;
- Ruby;
- Bundler;
- Jekyll;
- Just the Docs;
- GitHub Flavored Markdown tooling;
- Sass;
- pandoc;
- `MarkdownTools2`.

This toolchain is invoked only when `IntegratedInstructions=YES`. When `IntegratedInstructions=NO`, the deployment omits the instruction link, does not call the Jekyll build pipeline, and removes `/var/www/<DOMAIN>/html/grpN/instructions` for every selected group. That removal is unconditional; custom content at the same path is not preserved.

When enabled, the deployment currently installs or resolves parts of this toolchain during each redeploy.

Observed enabled-mode warnings include:

- Bundler running as root;
- deprecated Sass `@import`;
- deprecated global Sass functions;
- deprecated color helpers.

Modernization is required before future toolchain versions make those warnings fatal.

---

# AWS Tooling

| Tool or service client | Use |
|---|---|
| AWS CLI on EC2 | S3 copy and Route 53 DS operations |
| AWS CLI on operator workstation | validation and lifecycle operations |
| Boto3 in Lambda | EC2 IPv6 lookup and Route 53 cleanup |
| CloudFormation helper `cfnresponse` | custom-resource responses |

---

# Participant Utility Stack

The prepared `hostX` template includes tools such as:

- `dig` and DNS utilities;
- Knot DNS utilities;
- tcpdump;
- dnstop;
- traceroute;
- whois;
- telnet;
- ICANN RDAP client;
- editors and manual pages;
- OpenSSH server.

This template is copied to participant and shared service containers.

---

# Package and Artifact Sources

The current deployment depends on:

- Ubuntu archives;
- ISC Launchpad PPA;
- CZ.NIC package repository;
- PowerDNS package repository;
- FRRouting package repository;
- GitHub releases;
- GitHub instruction archives and RubyGems when integrated instructions are enabled;
- PyPI;
- Let's Encrypt;
- RPKI repositories.

Several downloads use `latest` or unpinned repository channels.

This creates two separate reproducibility risks:

1. version drift;
2. temporary upstream inconsistency.

---

# Version Policy

Current policy is largely dynamic:

```text
new deployment
    -> current Noble AMI
    -> current Ubuntu updates
    -> current repository metadata
    -> selected latest external artifacts
```

This keeps new labs updated but means a Git commit alone is not sufficient to reproduce a deployment.

The planned hardening direction is to classify dependencies:

| Class | Proposed policy |
|---|---|
| Base OS | controlled AMI selection |
| Critical routing/DNS packages | tested repository/version channel |
| External binaries | checksum and version pin |
| Documentation gems | lockfile and cache |
| Participant tools | update deliberately |
| Security fixes | scheduled refresh with regression test |

---

# Runtime Validation

Host:

```bash
lsb_release -a
uname -a
lxd --version
nginx -v
certbot --version
python3 --version
ruby --version
```

Containers:

```bash
lxc exec dnsdist -- dnsdist --version
lxc exec ns1 -- named -V
lxc exec grp1-resolv2 -- unbound -V
lxc exec grp1-ns2 -- nsd -v
lxc exec grp1-rtr -- vtysh -c 'show version'
lxc exec fortX -- fort --version
```

Exact commands can fail before the corresponding exercise package is installed or while a template is stopped.

---

# Known Technical Debt

- Runtime dependency installation is extensive.
- Several sources use unpinned latest versions.
- FRR repository stability is not controlled.
- FORT artifact integrity is not independently verified by the script.
- pip uses `--break-system-packages`.
- base templates contain fixed `sysadm` and `rtradm` bootstrap credentials that are not uniformly removed or rotated;
- the active WebSSH virtual host does not reference the generated nginx htpasswd file;
- Bundler runs as root when integrated instructions are enabled.
- Sass/Jekyll deprecations are unresolved in the enabled instruction path.
- firewall tools show legacy-table warnings.
- software versions are not captured in one deployment manifest.

---

# Review Status

**Current Status:** In Review

**Next Review:** After dependency pinning and deployment-manifest design.
