# Ports and Protocols Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document lists the currently implemented public and internal ports used by OCTO-TE Labs.

It distinguishes:

- AWS Security Group exposure;
- host listeners;
- container listeners;
- internal routing protocols;
- planned or defective paths.

---

# Public AWS Ingress

The current CloudFormation Security Group permits the following from both IPv4 and IPv6:

| Protocol | Port | Purpose |
|---|---:|---|
| TCP | 8484 | SSH to the EC2 host |
| TCP | 53 | public DNS over TCP |
| UDP | 53 | public DNS over UDP |
| TCP | 80 | HTTP redirect and Certbot standalone validation |
| TCP | 443 | HTTPS main site and WebSSH |

No other public ingress is currently declared by the template.

---

# Host Listeners and Publication

| Listener or path | Bind scope | Public path |
|---|---|---|
| sshd TCP/8484 | EC2 interfaces | directly allowed by Security Group |
| nginx TCP/80 | IPv4 and IPv6 | directly allowed |
| nginx TCP/443 | IPv4 and IPv6 | directly allowed |
| WebSSH TCP/8888 | `localhost` only | nginx reverse proxy |
| PHP-FPM | Unix socket | nginx only |
| dnsmasq DHCP | backbone preparation network | internal only |
| DNS DNAT TCP/53 | host PREROUTING | `dnsdist` |
| DNS DNAT UDP/53 | host PREROUTING | `dnsdist` |

WebSSH is not exposed directly on port 8888.

---

# DNS Ports

## Public frontend

`dnsdist` listens internally on:

```text
100.64.0.53:53
[fd89:59e0:0::53]:53
```

for UDP and TCP.

The host translates public port 53 to those addresses.

## Authoritative services

| Service | Address scope | Port |
|---|---|---:|
| `ns1` | backbone IPv4/IPv6 and loopback | TCP/UDP 53 |
| `auth-exercise` | backbone IPv4/IPv6 and loopback | TCP/UDP 53 |
| `auth-rpz` | backbone IPv4/IPv6 and loopback | TCP/UDP 53 |
| group `soa`, `ns1`, `ns2` | group internal/DMZ | TCP/UDP 53 |

TCP/53 is required for:

- large DNS responses;
- DNSSEC;
- zone transfers;
- exercise behavior.

## Recursive services

Participant resolvers listen on TCP/UDP 53 after `do-dns-lab.sh` installs and configures BIND and Unbound.

## dnsdist control socket

The configuration contains a commented example:

```text
127.0.0.1:5199
```

The control socket is not enabled in the current baseline.

---

# Web Ports

| Protocol | Port | Responsibility |
|---|---:|---|
| TCP | 80 | redirect to HTTPS and standalone ACME validation |
| TCP | 443 | main lab site and WebSSH |
| TCP | 8888 | loopback-only WebSSH backend |

The WebSSH proxy uses WebSocket upgrade semantics over HTTPS.

---

# SSH

| Path | Protocol/port |
|---|---|
| Operator to EC2 host | TCP/8484 |
| WebSSH to participant containers | SSH, normally TCP/22 on internal addresses |
| Direct host-to-container administration | SSH or `lxc exec`, internal only |

The AWS Security Group does not expose TCP/22 publicly.

---

# Routing Protocols

## BGP

FRRouting uses BGP between:

- each group router;
- `iborder-rtr`.

Standard BGP uses:

```text
TCP/179
```

This traffic remains on the internal backbone and does not require public Security Group ingress.

## OSPF

The router template enables OSPF and OSPFv3 daemons. These are IP protocols, not TCP or UDP application ports.

Their current exercise use requires routing-profile regression testing.

---

# RPKI-RTR

The FORT template is configured in server mode on:

```text
TCP/323
```

This is the standard RPKI-RTR service path used by FRRouting with the RPKI module.

It is intended for internal lab use and is not exposed in the current AWS Security Group.

The RPKI profiles are not production-verified in the current branch.

---

# WireGuard

The WireGuard configuration uses the parameter:

```text
VPNlistenPort
```

However, the current host iptables add and delete commands are hard-coded to:

```text
UDP/36456 -> 100.64.0.10:36456
```

where `100.64.0.10` is `iborder-rtr`. The tested environment also used `36456`, so the values happened to align. Any different `VPNlistenPort` would leave the WireGuard listener and host forwarding rule inconsistent.

> [!WARNING]
> The current CloudFormation Security Group does not permit WireGuard UDP at all. Routing-profile VPN ingress is therefore incomplete until the parameter, DNAT rule, cleanup path, and Security Group are aligned and tested.

The remote endpoint port is part of `VPNendPointIPv4` and can differ from the local listener.

---

# DHCP

dnsmasq provides temporary DHCP during container preparation.

The exact DHCP server port pair is the standard UDP/67 and UDP/68 behavior, but it is confined to the internal backbone and is not publicly exposed.

dnsmasq DNS service is disabled with:

```text
port=0
```

---

# NAT64

TAYGA uses a TUN interface rather than a public application listener.

Relevant routed prefixes:

```text
64:ff9b::/96
192.0.2.0/24
```

No additional AWS ingress port is required for NAT64.

---

# External Egress Dependencies

Deployment requires outbound access for:

- DNS resolution;
- HTTP/HTTPS package repositories;
- S3 downloads;
- GitHub release and instruction downloads;
- Let's Encrypt;
- RubyGems;
- RPKI repository synchronization used by FORT.

The current Security Group relies on its default egress behavior. Restricting egress would require an explicit dependency inventory.

---

# Port Validation

Host:

```bash
ss -lntup
systemctl status ssh
systemctl status nginx
systemctl status wsshd
```

Containers:

```bash
lxc exec dnsdist -- ss -lntup
lxc exec ns1 -- ss -lntup
lxc exec auth-rpz -- ss -lntup
lxc exec grp1-rtr -- ss -lntup
```

CloudFormation:

```bash
aws ec2 describe-security-groups \
    --group-ids <SECURITY_GROUP_ID>
```

---

# Known Gaps

- WireGuard UDP is missing from public ingress;
- WireGuard DNAT is hard-coded to UDP/36456 instead of using `VPNlistenPort`;
- dnsdist control is disabled and has no documented operational credential.
- RPKI-RTR exposure and policy require profile testing.
- iptables legacy warnings indicate an unresolved firewall implementation strategy.
- Public exposure should be reassessed before adding monitoring or management ports.

---

# Review Status

**Current Status:** In Review

**Next Review:** After routing-profile ingress and firewall hardening.
