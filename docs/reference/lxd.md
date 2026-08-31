# LXD Platform Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document describes the current LXD configuration, templates, storage, profiles, bridges, and lifecycle used by OCTO-TE Labs.

---

# Initialization

The host initializes LXD with:

```bash
lxd init --preseed < configs/lxd/lxdpreseed.yaml
```

The preseed defines:

- the default LXD project;
- one ZFS storage pool;
- one default profile;
- no LXD-managed networks.

The backbone bridge is created by host netplan rather than by the LXD preseed.

---

# Storage

| Item | Current value |
|---|---|
| Pool name | `dns` |
| Driver | ZFS |
| Backing file | `/var/snap/lxd/common/lxd/disks/dns.img` |
| Configured size | `250GB` |
| ZFS pool name | `dns` |

The EC2 root volume is larger than the LXD pool, leaving host space for packages, logs, swap, instructions, and deployment artifacts.

---

# Default Profile

The default profile provides:

```yaml
config:
  limits.memory: 2GB
devices:
  eth0:
    nictype: bridged
    parent: net-bb
  root:
    pool: dns
```

CPU limit keys are present but empty.

## Memory semantics

`limits.memory: 2GB` is a ceiling, not a reservation.

It prevents one normal container from consuming all host memory, while unused memory remains available to other containers and the host.

Known or planned exceptions:

| Role | Limit |
|---|---:|
| normal container | 2 GB |
| `dnsdist` | 8 GB |
| RPKI validator | planned 8 GB where required |

The effective configuration must be checked with `--expanded` because an instance can override the profile.

```bash
lxc config show dnsdist --expanded
```

---

# Base Image

`setup-containers.sh` copies:

```text
ubuntu:24.04
```

to the local image store with alias:

```text
ubuntu
```

It then creates and customizes `hostX`.

Preparation includes:

- waiting for cloud-init;
- removing the inherited network file;
- disabling `systemd-resolved`;
- writing an external resolver;
- adding DNS package repositories;
- installing troubleshooting tools;
- enabling interactive SSH authentication;
- creating the `sysadm` account;
- applying an rsyslog/AppArmor adjustment.

`hostX` currently creates the fixed bootstrap credential `sysadm:icannws`. `rtrX` inherits that account and also creates `rtradm:icannws`. Participant client, resolver, authoritative, and intended group-validator paths rotate `sysadm`, while group routers rotate only `rtradm`. Shared DNS roles, global validators, the border router, and template instances do not currently show a uniform removal or rotation step for every inherited account. These fixed credentials must be eliminated during hardening.

---

# Templates

## hostX

General-purpose template for:

- participant clients;
- participant resolvers;
- participant authoritative servers;
- shared DNS service containers.

## rtrX

Copy of `hostX` with:

- FRRouting packages;
- RPKI module;
- FRR daemon configuration;
- `rtradm` account and `vtysh` shell.

## fortX

Copy of `hostX` with:

- FORT Validator;
- FORT configuration;
- enabled FORT service.

All three templates are normally stopped after preparation.

---

# Instance Creation

The orchestrator uses `lxc copy` from a stopped template.

Examples:

```bash
lxc copy hostX grp1-cli
lxc copy hostX dnsdist
lxc copy rtrX grp1-rtr
lxc copy fortX rpki1
```

The current per-group RPKI function incorrectly refers to `RPKIfortX`; this must be corrected to `fortX` or the template naming redesigned.

---

# Network Devices

## Default device

Instances inherit `eth0` attached to `net-bb` from the default profile.

Many roles then add or override explicit devices.

## Group routers

Group routers receive:

```text
eth0 -> net-bb, inherited
eth1 -> grpN-lan
eth2 -> grpN-int
eth3 -> grpN-dmz
eth4 -> grpN-extra
```

## Participant containers

Participant roles receive one explicit `eth0` on their selected group bridge. Their final netplan is pushed after the container is started.

## Group bridges

The orchestrator creates unmanaged-style LXD bridges:

```bash
lxc network create grpN-lan ipv6.address=none ipv4.address=none ipv4.nat=false
```

and similarly for `int`, `dmz`, and `extra`.

LXD does not provide addresses, DHCP, or NAT on these bridges.

---

# Lifecycle

## Initial host bootstrap

```text
setup-host.sh
    -> LXD initialization

setup-containers.sh
    -> template creation

setup-lab.sh --deploy
    -> deployment instances
```

## Internal wipe

`setup-lab.sh --wipe` or `--deploy` deletes deployed role instances and group bridges but preserves the EC2 host and recreatable template layer.

The cleanup temporarily uses `NETWORKS=64` to target all currently supported group numbers.

## CloudFormation deletion

Deleting the stack removes the EC2 host and therefore the entire LXD state.

---

# State and Counting

Preferred API inventory:

```bash
lxc query /1.0/instances | jq -r '.[] | split("/")[-1]'
```

Status inventory:

```bash
lxc query '/1.0/instances?recursion=1' |
    jq -r '.[] | [.name, .status] | @tsv'
```

Count:

```bash
lxc query /1.0/instances | jq 'length'
```

The API method avoids counting interface-address rows from a formatted `lxc list` table.

---

# Memory Inspection

Current cgroup state is available through the LXD API:

```bash
lxc query /1.0/instances/dnsdist/state | jq '.memory'
```

Process RSS inside a container is useful but not identical to total container memory:

```bash
lxc exec dnsdist -- ps -o pid,rss,vsz,comm -C dnsdist
```

Use both when investigating scale.

---

# Measured Scale

A 60-group resolver deployment contained:

```text
247 real instances
244 running
3 stopped templates
```

The group count was:

```text
60 routers
60 clients
60 resolv1
60 resolv2
```

The test used approximately 30 GiB of a 59 GiB host after deployment, with negligible swap.

This measurement occurred before the dnsdist backend fix, so a repeat benchmark is required.

---

# Storage and Disk Interpretation

`lxc info` disk values can reflect the container root view or ZFS accounting and are not a direct measure of copied image cost.

For capacity planning, review:

```bash
lxc storage info dns
zfs list
du -sh /var/snap/lxd/common/lxd
df -h /
```

---

# Useful Commands

```bash
lxc profile show default
lxc storage list
lxc storage info dns
lxc image list
lxc network list
lxc list
lxc info <instance>
lxc config show <instance> --expanded
```

---

# Known Issues

- cleanup and template matching rely on naming patterns;
- CPU limits are not defined;
- the ZFS pool size is fixed in the preseed;
- group limit and cleanup ceiling are fixed at 64 in the current orchestrator;
- RPKI template naming is inconsistent;
- fixed `sysadm` and `rtradm` bootstrap credentials require removal and verified per-role rotation;
- the container image and packages are dynamically updated;
- high-scale startup concurrency is not explicitly controlled;
- resource accounting needs repeatable benchmark tooling.

---

# Review Status

**Current Status:** In Review

**Next Review:** After resource-profile design and 100+ group testing.
