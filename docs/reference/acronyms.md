# Acronyms and Abbreviations

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document defines acronyms and abbreviations used throughout the OCTO-TE Labs Handbook and implementation.

---

# Project and Engineering

| Term | Meaning |
|---|---|
| AC | Architecture Candidate |
| ADR | Architecture Decision Record |
| BUG | Confirmed engineering defect identifier |
| EPIC | Large engineering work area |
| FEAT | Feature work-item identifier |
| ICANN | Internet Corporation for Assigned Names and Numbers |
| IMP | Improvement work-item identifier |
| KB | Knowledge Base entry |
| OCTO | Office of the Chief Technology Officer |
| NSRC | Network Startup Resource Center |
| TASK | Engineering task identifier |
| TD | Technical-debt identifier |
| TE | Technical Engagement |

---

# DNS and DNSSEC

| Term | Meaning |
|---|---|
| A | DNS record containing an IPv4 address |
| AAAA | DNS record containing an IPv6 address |
| AXFR | Full DNS zone transfer |
| CDS | Child DS record used to signal a desired parent DS update |
| CDNSKEY | Child DNSKEY record used to signal parent-side DNSSEC automation |
| CNAME | Canonical Name DNS record |
| DNS | Domain Name System |
| DNS64 | DNS synthesis mechanism that creates AAAA answers from A records for NAT64 clients |
| DNSSEC | Domain Name System Security Extensions |
| DS | Delegation Signer record in a parent zone |
| EAI | Email Address Internationalization |
| EDNS | Extension Mechanisms for DNS |
| IDN | Internationalized Domain Name |
| IXFR | Incremental DNS zone transfer |
| KSK | Key Signing Key |
| NS | Name Server DNS record |
| NSEC | DNSSEC authenticated denial-of-existence record |
| RPZ | Response Policy Zone |
| RRSIG | DNSSEC signature record |
| SOA | Start of Authority DNS record |
| TTL | Time To Live |
| UA | Universal Acceptance |
| ZSK | Zone Signing Key |

---

# Routing and RPKI

| Term | Meaning |
|---|---|
| ASN | Autonomous System Number |
| BGP | Border Gateway Protocol |
| FORT | RPKI validator implementation used by the current platform |
| FRR | FRRouting routing software suite |
| RIR | Regional Internet Registry |
| ROA | Route Origin Authorization |
| RPKI | Resource Public Key Infrastructure |
| RTR | RPKI-to-Router protocol |
| TAL | Trust Anchor Locator |
| VPN | Virtual Private Network |

---

# Cloud and AWS

| Term | Meaning |
|---|---|
| AMI | Amazon Machine Image |
| API | Application Programming Interface |
| AWS | Amazon Web Services |
| AZ | Availability Zone |
| CFN | Common abbreviation for AWS CloudFormation |
| CIDR | Classless Inter-Domain Routing notation |
| EBS | Elastic Block Store |
| EC2 | Elastic Compute Cloud |
| EIP | Elastic IP address |
| IAM | Identity and Access Management |
| IGW | Internet Gateway |
| KMS | Key Management Service |
| S3 | Simple Storage Service |
| SG | Security Group |
| SSM | AWS Systems Manager; also used for public AMI parameters |
| VPC | Virtual Private Cloud |

---

# Containers, Host, and Storage

| Term | Meaning |
|---|---|
| CLI | Command-Line Interface |
| cgroup | Linux control group used for resource accounting and limits |
| LXC | Linux Containers runtime/tooling family |
| LXD | System-container manager used by the current platform |
| ULA | IPv6 Unique Local Address |
| ZFS | Filesystem and volume manager used for the current LXD storage pool |

---

# Networking and Security

| Term | Meaning |
|---|---|
| DHCP | Dynamic Host Configuration Protocol |
| DNAT | Destination Network Address Translation |
| HTTP | Hypertext Transfer Protocol |
| HTTPS | HTTP over TLS |
| HSTS | HTTP Strict Transport Security |
| IPv4 | Internet Protocol version 4 |
| IPv6 | Internet Protocol version 6 |
| NAT | Network Address Translation |
| NAT64 | Translation between IPv6 clients and IPv4 destinations |
| nftables | Linux packet-filtering and NAT framework |
| SSH | Secure Shell |
| TCP | Transmission Control Protocol |
| TLS | Transport Layer Security |
| UDP | User Datagram Protocol |
| WebSSH | Browser-based SSH frontend used by the platform |

---

# Software and Configuration

| Term | Meaning |
|---|---|
| BIND | Berkeley Internet Name Domain DNS software |
| Jekyll | Static-site generator used for participant instructions |
| NSD | Name Server Daemon authoritative DNS software |
| TAYGA | Stateless NAT64 implementation used by the current host |
| Unbound | Recursive DNS resolver software |
| WireGuard | VPN protocol and implementation used for border-router connectivity |

---

# Usage Notes

- `ns1` can refer to the shared platform authoritative container or to a group authoritative role; context and full naming distinguish them.
- `RTR` in this Handbook normally means the RPKI-to-Router protocol. Group router instance names use the suffix `-rtr`.
- `Lab Type` refers to the current numeric implementation profile. `Training Profile` is the broader architecture/design concept.

---

# Review Status

**Current Status:** In Review

**Next Review:** When new domains, protocols, software, or engineering identifier classes are introduced.
