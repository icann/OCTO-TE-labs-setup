# Network Topology

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document describes the current network architecture of OCTO-TE Labs across AWS, the Ubuntu host, the LXD backbone, shared services, and per-group networks.

The detailed address catalog is maintained in [`../reference/network-addressing.md`](../reference/network-addressing.md). The companion diagram is [`../diagrams/network-topology.md`](../diagrams/network-topology.md).

---

# Layered Topology

```text
Internet
   |
   v
AWS Internet Gateway
   |
   v
Public dual-stack subnet
   |
   v
EC2 host
   |
   +-- public IPv4 through an Elastic IP
   +-- public IPv6 assigned by AWS
   +-- eth0 connected to the AWS subnet
   |
   +-- net-bb backbone bridge
         |
         +-- shared service containers
         +-- one router per participant group
         +-- optional border router
               |
               +-- grpN-lan
               +-- grpN-int
               +-- grpN-dmz
               +-- grpN-extra
```

The platform intentionally separates the AWS network from the internal training topology. AWS provides public reachability to the EC2 host. The host and LXD topology provide the laboratory network.

---

# AWS Network Layer

CloudFormation creates:

| Resource | Current value or behavior |
|---|---|
| VPC | `10.0.0.0/16` |
| Public subnet | `10.0.1.0/24` |
| IPv6 | Amazon-provided VPC CIDR, with one `/64` assigned to the subnet |
| Internet access | Internet gateway with IPv4 and IPv6 default routes |
| Public IPv4 | Elastic IP associated with the EC2 instance |
| Public IPv6 | AWS-assigned global address on the EC2 network interface |
| Security boundary | One stack security group |

The EC2 interface receives its private IPv4 configuration through AWS DHCP. The instance also receives a public/global IPv6 address from the subnet.

CloudFormation publishes the EC2 public addresses through Route 53 as:

```text
ns1.<DOMAIN>
ec2-<DOMAIN>
```

The lab apex and `webssh.<DOMAIN>` are later published from the platform authoritative zone.

---

# Host Network Layer

`setup-host.sh` replaces the initial host netplan with the project network model.

## Public interface

The AWS network interface remains `eth0`.

Current behavior:

- IPv4 uses DHCP;
- the interface is matched by MAC address;
- AWS supplies the global IPv6 address;
- the host retains the AWS default path to the Internet.

## Backbone bridge

The host creates:

```text
net-bb
```

with:

```text
IPv4: 100.64.0.1/22
IPv6: fd89:59e0:0::1/48
```

The bridge is not an LXD-managed network with address allocation. It is a Linux bridge defined by netplan and used as the common backbone for shared containers and group routers.

The host provides:

- routing between the group aggregates and `net-bb`;
- outbound IPv4 NAT for internal lab addresses;
- DNAT for published DNS;
- a temporary DHCP service used while base containers are prepared;
- host-based NAT64 through TAYGA.

---

# Prepared Host Routes

The host netplan contains prepared routes beyond the current 64-group orchestrator limit.

For IPv4, the route model includes:

```text
100.100.N.0/24 via 100.64.1.N
```

for group identifiers through `200`, plus historical special routes.

For IPv6, the route model includes:

```text
fd89:59e0:N::/48 via fd89:59e0:0:1::N
```

through `200`, plus a historical `AAA` route.

This route preparation does not create group bridges or containers. It provides an underlay capacity that can be used later when a group router and its four LXD networks are created.

The current implementation therefore uses a hybrid model:

```text
host routes: prepared in advance
LXD group networks: created only for selected groups
containers: created only for selected capabilities
```

---

# Shared Backbone Services

The principal shared addresses on `net-bb` are:

| Role | Container | IPv4 | IPv6 |
|---|---|---:|---|
| Host gateway | EC2 host | `100.64.0.1` | `fd89:59e0:0::1` |
| Border router | `iborder-rtr` | `100.64.0.10` | `fd89:59e0:0::10` |
| Public DNS frontend | `dnsdist` | `100.64.0.53` | `fd89:59e0:0::53` |
| Platform authority | `ns1` | `100.64.0.54` | `fd89:59e0:0::54` |
| Exercise authority | `auth-exercise` | `100.64.0.55-.57` | `fd89:59e0:0::55-::57` |
| RPZ authority | `auth-rpz` | `100.64.0.58` | `fd89:59e0:0::58` |
| Global RPKI validator 1 | `rpki1`, when enabled | `100.64.0.70` | `fd89:59e0:0::70` |
| Global RPKI validator 2 | `rpki2`, when enabled | `100.64.0.71` | `fd89:59e0:0::71` |

The temporary DHCP pool used while preparing containers is:

```text
100.64.2.100-100.64.2.150
```

Final participant and service addresses are configured statically.

---

# Group Topology

For group `N`, the aggregate is:

```text
IPv4: 100.100.N.0/24
IPv6: fd89:59e0:N::/48
```

The group router connects the backbone to four isolated bridges:

| Router interface | LXD network | IPv4 subnet | Router IPv4 | IPv6 subnet | Router IPv6 |
|---|---|---|---|---|---|
| `eth1` | `grpN-lan` | `100.100.N.0/26` | `.1` | `fd89:59e0:N:0::/64` | `::1` |
| `eth2` | `grpN-int` | `100.100.N.64/26` | `.65` | `fd89:59e0:N:64::/64` | `::1` |
| `eth3` | `grpN-dmz` | `100.100.N.128/26` | `.129` | `fd89:59e0:N:128::/64` | `::1` |
| `eth4` | `grpN-extra` | `100.100.N.192/26` | `.193` | `fd89:59e0:N:192::/64` | `::1` |

The router backbone interface is:

```text
IPv4: 100.64.1.N/22
IPv6: fd89:59e0:0:1::N/48
```

and its default route points to the host gateway.

> [!NOTE]
> The IPv6 tokens `64`, `128`, and `192` are written as hexadecimal hextets. They were selected to parallel the IPv4 subnet offsets in the configuration and documentation.

---

# Role Placement

The normal participant role placement is:

| Role | Network | Typical IPv4 |
|---|---|---:|
| Client | LAN | `100.100.N.2` |
| SOA/primary | Internal | `100.100.N.66` |
| Resolver 1 | Internal | `100.100.N.67` |
| Resolver 2 | Internal | `100.100.N.68` |
| Group RPKI validator | Internal | `100.100.N.70` |
| Authoritative `ns1` | DMZ | `100.100.N.130` |
| Authoritative `ns2` | DMZ | `100.100.N.131` |

The `extra` bridge remains attached to every group router even when the selected profile does not place a participant container on it. It is part of the original topology and is retained for routing, Anycast, and future exercises.

---

# LXD Network Behavior

Each group network is created with:

```text
ipv4.address=none
ipv6.address=none
ipv4.nat=false
```

Therefore:

- LXD does not provide DHCP or address management on the group bridges;
- LXD does not provide per-network NAT;
- addresses and default routes are written into container netplan files;
- the group router is the gateway for all four group networks;
- the EC2 host remains the upstream gateway for group routers.

This makes the topology explicit and suitable for networking exercises.

---

# Public DNS Path

Public DNS uses DNAT on the EC2 host:

```text
Internet client
   |
   | UDP/TCP 53 to EC2 public IPv4 or IPv6
   v
host PREROUTING DNAT
   |
   v
dnsdist at 100.64.0.53 / fd89:59e0:0::53
   |
   +-- auth-platform pool -> ns1
   +-- grpN pool -> group authoritative servers, when enabled
```

The public frontend and the backend transport are independent. The current full-DNS profile keeps both IPv4 and IPv6 objects for each participant authoritative server.

---

# Web and SSH Paths

```text
SSH client
   |
   | TCP/8484
   v
EC2 host sshd
```

```text
Browser
   |
   | TCP/443
   v
nginx
   |
   +-- main lab content
   +-- WebSSH reverse proxy -> localhost:8888
```

WebSSH then opens SSH sessions to internal role addresses using the credentials generated for each group.

---

# Internet Egress

Internal containers reach external repositories and services through:

```text
container
   -> group router or net-bb
   -> EC2 host
   -> host IPv4 NAT
   -> AWS subnet and Internet gateway
```

This path is required during deployment because many packages and participant tools are downloaded at runtime.

---

# NAT64

The host currently creates a TAYGA NAT64 service for every Lab Type.

Current values:

```text
NAT64 prefix: 64:ff9b::/96
TAYGA IPv4 address: 192.0.2.1
dynamic IPv4 pool: 192.0.2.0/24
TAYGA IPv6 address: fd00:1234:5678::1
```

NAT64 is host-based because the current implementation notes that it does not work as intended inside a container.

Making NAT64 capability-driven and making teardown idempotent are hardening tasks.

---

# IPv6 Prefix Policy

The current deployment uses the fixed ULA prefix:

```text
fd89:59e0
```

The original architecture generated a deployment-specific ULA. Restoring dynamic RFC 4193 generation remains planned because it improves isolation when multiple labs coexist, but it also requires documentation and configuration templates to stop relying on one fixed prefix.

---

# Scale and Capacity

The network template prepares routes through group `200`, while `setup-lab.sh` currently accepts 3-64 groups.

The original architecture was exercised with more than 100 groups. The current refactor has been measured with 60 resolver groups, but controlled recovery of 80/100+ group operation remains pending.

Capacity is constrained by more than routes:

- EC2 memory and CPU;
- LXD process and monitor overhead;
- service-specific memory;
- dnsdist backend count;
- external package installation time;
- file descriptors and kernel tables;
- cleanup duration.

---

# Known Issues

- The current group ceiling is inconsistent across CloudFormation text, shell validation, cleanup, and prepared routes.
- IPv6 uses a fixed ULA.
- NAT64 is always created.
- TAYGA and iptables teardown are not fully idempotent.
- Routing-profile WireGuard ingress is missing from the CloudFormation security group.
- WireGuard DNAT add/delete rules are hard-coded to UDP/36456 instead of using `VPNlistenPort`.
- Some route entries are historical and require classification before the addressing plan is simplified.
- Group NS delegations are generated even when participant authoritative service is disabled.

---

# Validation

Useful host checks include:

```bash
ip -4 route
ip -6 route
ip address show net-bb
bridge link
lxc network list
```

Useful group-router checks include:

```bash
lxc exec grp1-rtr -- ip address
lxc exec grp1-rtr -- ip route
lxc exec grp1-rtr -- ip -6 route
```

Useful path tests include:

```bash
lxc exec grp1-cli -- ping -c 2 100.100.1.1
lxc exec grp1-cli -- ping -c 2 100.64.0.1
lxc exec grp1-cli -- traceroute 9.9.9.9
```

---

# Review Status

**Current Status:** In Review

**Next Review:** After network hardening, dynamic ULA design, and higher-scale regression testing.
