# Network Topology Diagram

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document provides visual summaries of the current AWS, host, shared-service, and per-group network topology.

The detailed architecture is in [`../architecture/04-network-topology.md`](../architecture/04-network-topology.md). Exact addresses are in [`../reference/network-addressing.md`](../reference/network-addressing.md).

---

# Overall Topology

```mermaid
flowchart TB
    INTERNET((Internet))
    IGW[AWS Internet Gateway]
    SUBNET[Public dual-stack subnet]
    HOST[EC2 host<br/>EIP + global IPv6<br/>SSH 8484 / HTTPS / DNS DNAT]
    BB[net-bb<br/>100.64.0.1/22<br/>fd89:59e0:0::1/48]

    DD[dnsdist<br/>.53]
    NS1[ns1 / auth-platform<br/>.54]
    EX[auth-exercise<br/>.55-.57]
    RPZ[auth-rpz<br/>.58]
    BORDER[iborder-rtr<br/>.10]

    R1[grp1-rtr<br/>100.64.1.1]
    RN[grpN-rtr<br/>100.64.1.N]

    INTERNET --> IGW --> SUBNET --> HOST --> BB

    BB --> DD
    BB --> NS1
    BB --> EX
    BB --> RPZ
    BB --> BORDER
    BB --> R1
    BB --> RN
```

---

# One Group

```mermaid
flowchart LR
    BB[net-bb]
    RTR[grpN-rtr]

    LAN[grpN-lan<br/>100.100.N.0/26]
    INT[grpN-int<br/>100.100.N.64/26]
    DMZ[grpN-dmz<br/>100.100.N.128/26]
    EXTRA[grpN-extra<br/>100.100.N.192/26]

    CLI[grpN-cli<br/>.2]
    SOA[grpN-soa<br/>.66]
    R1[grpN-resolv1<br/>.67]
    R2[grpN-resolv2<br/>.68]
    RPKI[grpN-rpki<br/>.70]
    NSG1[grpN-ns1<br/>.130]
    NSG2[grpN-ns2<br/>.131]

    BB --> RTR
    RTR --> LAN --> CLI
    RTR --> INT
    INT --> SOA
    INT --> R1
    INT --> R2
    INT --> RPKI
    RTR --> DMZ
    DMZ --> NSG1
    DMZ --> NSG2
    RTR --> EXTRA
```

Roles are created according to the selected Lab Type. The four bridges and router attachment exist for every current group.

---

# Public DNS Path

```mermaid
flowchart LR
    CLIENT[Public DNS client]
    PUBLIC[EC2 public IPv4/IPv6:53]
    DNAT[Host DNAT]
    DD[dnsdist .53]
    PLAT[ns1 .54]
    GPOOL[grpN authoritative pool]
    GNS1[grpN-ns1 IPv4/IPv6]
    GNS2[grpN-ns2 IPv4/IPv6]

    CLIENT --> PUBLIC --> DNAT --> DD
    DD -->|platform and unmatched| PLAT
    DD -->|group zone when enabled| GPOOL
    GPOOL --> GNS1
    GPOOL --> GNS2
```

Group DS queries remain on the platform authority.

---

# Web and Access Path

```mermaid
flowchart LR
    OP[Operator SSH client]
    USER[Participant browser]
    SSH[EC2 sshd :8484]
    NGINX[nginx :443]
    WSSH[WebSSH localhost:8888]
    TARGET[Internal participant role]

    OP --> SSH
    USER --> NGINX --> WSSH --> TARGET
```

---

# Egress Path

```mermaid
flowchart LR
    ROLE[Internal container]
    RTR[Group router]
    HOST[EC2 host]
    NAT[IPv4 NAT]
    AWS[AWS subnet / Internet gateway]
    OUT[External repositories and DNS]

    ROLE --> RTR --> HOST --> NAT --> AWS --> OUT
```

Shared backbone containers can reach the host directly without a group router.

---

# Address Legend

| Token | Meaning |
|---|---|
| `.1` | group LAN router |
| `.65` | group internal router |
| `.129` | group DMZ router |
| `.193` | group extra router |
| `.53` | shared dnsdist |
| `.54` | shared platform authority |
| `.55-.57` | exercise authoritative targets |
| `.58` | RPZ authority |

IPv6 follows the literal ULA patterns documented in the addressing reference.

---

# Current Constraints

- The fixed ULA is shared by all deployments.
- Host routes are prepared through group 200, but orchestration stops at 64.
- NAT64 is always created.
- WireGuard public ingress is incomplete.
- Group delegations exist even when participant authority is disabled.
- Routing and per-group RPKI paths need regression testing.

---

# Review Status

**Current Status:** In Review

**Next Review:** After dynamic ULA and routing-profile recovery.
