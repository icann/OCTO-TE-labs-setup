# Network Addressing Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document is the current IPv4 and IPv6 addressing reference for OCTO-TE Labs.

The architecture narrative is in [`../architecture/04-network-topology.md`](../architecture/04-network-topology.md).

---

# Notation

In the tables:

- `N` is the decimal participant group number;
- the current orchestrator accepts `N=1-64`;
- prepared host routes extend through `N=200`;
- `<PUBLIC-IPv4>` is the stack Elastic IP;
- `<PUBLIC-IPv6>` is the AWS-assigned EC2 global IPv6 address;
- the current ULA prefix is `fd89:59e0`.

---

# AWS Addressing

| Layer | IPv4 | IPv6 |
|---|---|---|
| VPC | `10.0.0.0/16` | Amazon-provided VPC CIDR |
| Public subnet | `10.0.1.0/24` | one AWS `/64` |
| EC2 private interface | AWS DHCP | AWS-assigned |
| Public host | Elastic IP | global IPv6 on the EC2 interface |

The actual public addresses are inserted into the platform zone and Route 53 records at deployment time.

---

# Backbone

The internal backbone is:

```text
IPv4: 100.64.0.0/22
IPv6: fd89:59e0:0::/48
```

## Host gateway

```text
IPv4: 100.64.0.1
IPv6: fd89:59e0:0::1
```

## Group-router backbone addresses

For group `N`:

```text
IPv4: 100.64.1.N/22
IPv6: fd89:59e0:0:1::N/48
```

The router default routes point to the host gateway.

## Temporary DHCP

dnsmasq provides a temporary preparation pool:

```text
100.64.2.100-100.64.2.150
```

This pool is not the final participant address plan.

---

# Shared Service Addresses

| Address | Role |
|---|---|
| `100.64.0.10` | `iborder-rtr` |
| `100.64.0.53` | `dnsdist` |
| `100.64.0.54` | `ns1` / `auth-platform` |
| `100.64.0.55` | `auth-exercise`, normal `internal.` authority |
| `100.64.0.56` | `auth-exercise`, special name-server target |
| `100.64.0.57` | `auth-exercise`, special address target |
| `100.64.0.58` | `auth-rpz` |
| `100.64.0.70` | `rpki1`, shared/global validator when enabled |
| `100.64.0.71` | `rpki2`, shared/global validator when enabled |

IPv6 uses the same final token below `fd89:59e0:0::/48`:

```text
fd89:59e0:0::10
fd89:59e0:0::53
fd89:59e0:0::54
fd89:59e0:0::55
fd89:59e0:0::56
fd89:59e0:0::57
fd89:59e0:0::58
fd89:59e0:0::70
fd89:59e0:0::71
```

---

# Per-Group IPv4 Plan

The group aggregate is:

```text
100.100.N.0/24
```

It is divided into four `/26` networks.

| Network | Prefix | Router | Current role addresses |
|---|---|---|---|
| LAN | `100.100.N.0/26` | `.1` | client `.2` |
| Internal | `100.100.N.64/26` | `.65` | SOA `.66`, resolv1 `.67`, resolv2 `.68`, RPKI `.70` |
| DMZ | `100.100.N.128/26` | `.129` | ns1 `.130`, ns2 `.131` |
| Extra | `100.100.N.192/26` | `.193` | reserved for routing/Anycast and future roles |

Examples for group 3:

```text
LAN:      100.100.3.0/26
router:   100.100.3.1
client:   100.100.3.2

Internal: 100.100.3.64/26
router:   100.100.3.65
SOA:      100.100.3.66
resolv1:  100.100.3.67
resolv2:  100.100.3.68
RPKI:     100.100.3.70

DMZ:      100.100.3.128/26
router:   100.100.3.129
ns1:      100.100.3.130
ns2:      100.100.3.131

Extra:    100.100.3.192/26
router:   100.100.3.193
```

---

# Per-Group IPv6 Plan

The group aggregate is:

```text
fd89:59e0:N::/48
```

The four current `/64` networks are:

| Network | Prefix | Router |
|---|---|---|
| LAN | `fd89:59e0:N:0::/64` | `fd89:59e0:N:0::1` |
| Internal | `fd89:59e0:N:64::/64` | `fd89:59e0:N:64::1` |
| DMZ | `fd89:59e0:N:128::/64` | `fd89:59e0:N:128::1` |
| Extra | `fd89:59e0:N:192::/64` | `fd89:59e0:N:192::1` |

Role addresses use the same written final token as the IPv4 role number.

Examples:

```text
client:  fd89:59e0:N:0::2
SOA:     fd89:59e0:N:64::66
resolv1: fd89:59e0:N:64::67
resolv2: fd89:59e0:N:64::68
RPKI:    fd89:59e0:N:64::70
ns1:     fd89:59e0:N:128::130
ns2:     fd89:59e0:N:128::131
```

> [!IMPORTANT]
> IPv6 hextets are hexadecimal. The strings `64`, `128`, `192`, `67`, and `130` are literal hexadecimal tokens in these addresses. The notation intentionally resembles the IPv4 role plan but is not a decimal-to-hex conversion table.

---

# Static Routing

The EC2 host has prepared routes:

```text
100.100.N.0/24 via 100.64.1.N
fd89:59e0:N::/48 via fd89:59e0:0:1::N
```

through group `200`.

The netplan also contains historical special entries:

- `100.100.0.0/24` via `100.64.1.254`;
- an IPv6 `AAA` aggregate and next hop.

These entries should be classified before the route template is regenerated or simplified.

Group routers install default routes to the host:

```text
0.0.0.0/0 via 100.64.0.1
::/0 via fd89:59e0:0::1
```

---

# Address Assignment Method

The LXD group bridges have no configured LXD addresses or DHCP.

Container addresses are generated from templates and pushed into netplan:

```text
configs/netplan/10-lxc.yaml
configs/netplan/bb-lxc.yaml
```

A participant role receives:

- a static IPv4 address;
- a static ULA address;
- an IPv4 default route through the group router;
- an IPv6 default route through the group router;
- a temporary external resolver, normally `9.9.9.9`, until the exercise-specific resolver configuration is installed.

---

# Public DNS Publication

These public names resolve to the EC2 public addresses:

| Name | A | AAAA |
|---|---|---|
| `<DOMAIN>` | Elastic IP | EC2 global IPv6 |
| `ns1.<DOMAIN>` | Elastic IP | EC2 global IPv6 |
| `ec2-<DOMAIN>` | Elastic IP | EC2 global IPv6 |
| `webssh.<DOMAIN>` | Elastic IP | EC2 global IPv6 |

Public DNS packets are translated to the internal `dnsdist` addresses.

---

# NAT64

Current TAYGA values:

| Item | Value |
|---|---|
| Interface | `nat64` |
| NAT64 prefix | `64:ff9b::/96` |
| TAYGA IPv4 address | `192.0.2.1` |
| Dynamic pool | `192.0.2.0/24` |
| TAYGA IPv6 address | `fd00:1234:5678::1` |

This address plan is independent of the project ULA prefix.

---

# VPN Addressing

Routing profiles use variables rather than one universal address plan:

```text
VPNlocalIPv4
VPNallowedPrefixIPv4
VPNendPointIPv4
VPNlistenPort
```

The current example deployment parameters use a private WireGuard link terminating at `100.64.0.10`. The WireGuard configuration consumes `VPNlistenPort`, but the present host DNAT rule is hard-coded to UDP/36456. Parameterized addressing and forwarding are therefore not yet fully aligned.

VPN values are environment-specific and must not be treated as fixed platform addresses.

---

# Prefix Policy

The fixed `fd89:59e0` prefix is convenient for documentation but reduces isolation among concurrent labs.

The planned future model is:

```text
generate one RFC 4193 ULA prefix per deployment
    -> render it into host, router, DNS, and participant configuration
    -> publish the selected prefix in generated documentation
```

No migration should occur until every fixed-prefix reference is inventoried.

---

# Validation Commands

```bash
ip address show net-bb
ip -4 route | grep 100.100
ip -6 route | grep fd89:59e0

lxc exec grp1-rtr -- ip address
lxc exec grp1-cli -- ip address
lxc exec grp1-cli -- ip route
lxc exec grp1-cli -- ip -6 route
```

---

# Review Status

**Current Status:** In Review

**Next Review:** After route cleanup, dynamic ULA design, and 100+ group testing.
