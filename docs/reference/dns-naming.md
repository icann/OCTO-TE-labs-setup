# DNS Naming Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document defines the DNS names derived from the CloudFormation parameters and identifies which component owns each record or zone.

---

# Input Parameters

## DnsParent

`DnsParent` is the existing parent Route 53 zone.

Requirements:

- it must already exist in the AWS account used by the deployment;
- it must be DNSSEC signed for the lab's DS chain to validate;
- the CloudFormation value includes the trailing dot.

Example:

```text
te-labs.training.
```

## DnsName

`DnsName` is a single DNS label used below the parent.

Current validation:

```text
length: 3-32 characters
allowed: lowercase a-z, digits 0-9, hyphen
first character: letter or digit
last character: letter or digit
```

Examples accepted:

```text
dnstest
dns-test
lab-2026
a1-b2
```

Examples rejected:

```text
-dnstest
dnstest-
dns_test
DNS-Test
```

---

# Derived Domain

The internal deployment derives:

```text
DOMAIN=<DnsName>.<DnsParent-without-final-dot>
```

Example:

```text
DnsName:   dns-test
DnsParent: te-labs.training.
DOMAIN:    dns-test.te-labs.training
```

The value is normalized to lowercase and the parent trailing dot is removed for shell and file-path use.

The current implementation does not convert dots to hyphens or attempt to reconstruct domain names from hyphenated identifiers.

---

# Public Names

| Name | Purpose | Owner |
|---|---|---|
| `<DOMAIN>` | lab zone apex, main web site, public DNS endpoint address | platform zone on `ns1`; apex delegation is in parent Route 53 |
| `ns1.<DOMAIN>` | authoritative server name and glue | parent Route 53 and platform zone |
| `ec2-<DOMAIN>` | early/direct EC2 SSH access | CloudFormation parent-zone record |
| `webssh.<DOMAIN>` | browser SSH virtual host | platform zone on `ns1` |
| `ipv4only.<DOMAIN>` | IPv4-only exercise name | platform zone on `ns1` |
| `ipv6only.<DOMAIN>` | IPv6-only exercise name | platform zone on `ns1` |

For the example domain:

```text
dns-test.te-labs.training
ns1.dns-test.te-labs.training
ec2-dns-test.te-labs.training
webssh.dns-test.te-labs.training
ipv4only.dns-test.te-labs.training
ipv6only.dns-test.te-labs.training
```

---

# Parent-Zone Records

CloudFormation creates these records in `DnsParent`:

| Record | Type | Purpose |
|---|---|---|
| `<DOMAIN>.` | NS | delegate the lab zone to `ns1.<DOMAIN>.` |
| `ns1.<DOMAIN>.` | A | IPv4 glue to the EC2 Elastic IP |
| `ns1.<DOMAIN>.` | AAAA | IPv6 glue to the EC2 public IPv6 address |
| `ec2-<DOMAIN>.` | A | direct EC2 IPv4 access |
| `ec2-<DOMAIN>.` | AAAA | direct EC2 IPv6 access |

The internal deployment later creates:

| Record | Type | Purpose |
|---|---|---|
| `<DOMAIN>.` | DS | connect parent DNSSEC validation to the signed lab zone |

The DS is created outside native CloudFormation record resources. The `labDnsCleanup` custom resource deletes it during stack deletion.

---

# Platform Zone Records

The BIND zone served by `ns1` contains at least:

| Owner | Type | Value/purpose |
|---|---|---|
| `@` | SOA | `ns1.<DOMAIN>.` and `hostmaster.ns1.<DOMAIN>.` |
| `@` | NS | `ns1.<DOMAIN>.` |
| `@` | A | EC2 public IPv4 address |
| `@` | AAAA | EC2 public IPv6 address |
| `ns1` | A/AAAA | EC2 public addresses |
| `webssh` | A/AAAA | EC2 public addresses |
| `ipv4only` | A | EC2 public IPv4 address |
| `ipv6only` | AAAA | EC2 public IPv6 address |

The zone is signed automatically by BIND using `dnssec-policy default`.

The current initial serial is `1`. Conversion to a UTC `YYYYMMDDnn` scheme is planned for the hardening phase.

---

# Group Names

For group `N`, the group zone is:

```text
grpN.<DOMAIN>
```

Examples:

```text
grp1.dns-test.te-labs.training
grp25.dns-test.te-labs.training
```

Participant service hostnames are derived as follows:

```text
cli.grpN.<DOMAIN>
resolv1.grpN.<DOMAIN>
resolv2.grpN.<DOMAIN>
soa.grpN.<DOMAIN>
ns1.grpN.<DOMAIN>
ns2.grpN.<DOMAIN>
rpki.grpN.<DOMAIN>
```

The router keeps the LXD instance name `grpN-rtr`; its generated FRRouting hostname is currently `rtr1.grpN.<DOMAIN>`. `routers.sh` does not normalize the container operating-system hostname to the same DNS-style form.

LXD instance names use the shorter implementation form:

```text
grpN-cli
grpN-rtr
grpN-resolv1
grpN-resolv2
grpN-soa
grpN-ns1
grpN-ns2
grpN-rpki
```

---

# Group Delegation and dnsdist Routing

The platform zone currently generates an NS delegation for every selected `grpN.<DOMAIN>` name. The NS target is the public platform service `ns1.<DOMAIN>`, and this delegation is generated independently of `StudentAuth`.

When `StudentAuth=YES`, `dnsdist` additionally creates a private authoritative pool for the group with:

- `grpN-ns1` over IPv4;
- `grpN-ns1` over IPv6;
- `grpN-ns2` over IPv4;
- `grpN-ns2` over IPv6.

Routing behavior is split:

```text
DS for grpN.<DOMAIN>
    -> platform authoritative pool

all other names at or below grpN.<DOMAIN>
    -> grpN authoritative pool
```

For resolver-only profiles, group authoritative containers do not exist and no group pools are generated. The generated group delegation therefore does not represent an available participant authoritative service in Lab Type 1. Conditioning delegation generation on `StudentAuth` is a documented hardening item.

---

# Exercise-Only Names

The shared exercise authority serves names outside the public lab domain, including:

```text
internal.
badnsname.internal.
evilnsip.internal.
```

The RPZ authority serves:

```text
rpz.
```

These zones support resolver and policy exercises and are separate from the platform authoritative zone.

---

# HTTPS Names

The platform certificate covers:

```text
<DOMAIN>
webssh.<DOMAIN>
```

nginx uses the same names as virtual hosts. Hyphens in `DnsName` have been validated across:

- CloudFormation;
- Route 53;
- host naming;
- BIND zone loading;
- DNSSEC signing and external validation;
- Certbot certificate issuance;
- nginx;
- WebSSH;
- stack deletion and DNS cleanup.

---

# DNSSEC Validation

A complete external validation should show the AD flag from validating resolvers:

```bash
dig @1.1.1.1 +dnssec +adflag <DOMAIN> SOA
dig @8.8.8.8 +dnssec +adflag <DOMAIN> SOA
```

A signed answer containing an RRSIG is not alone proof that the full chain validated. The `ad` flag from a trusted validating resolver is the expected external check.

---

# Deletion and Cache Behavior

After stack deletion:

- CloudFormation removes NS, glue, and `ec2-` records;
- the custom resource removes the DS;
- Route 53 should contain no records matching the deleted lab name.

Recursive resolvers may briefly return previous data or a transient validation error while cached DS and denial-of-existence records converge. Record state in Route 53 is the primary cleanup check, followed by public resolver checks after the TTL interval.

---

# Review Status

**Current Status:** In Review

**Next Review:** After DNS hardening changes, including SOA serial modernization.
