# Container Naming Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document defines the current LXD instance naming conventions and distinguishes LXD names from operating-system hostnames, DNS names, and architectural role names.

---

# Naming Domains

The platform uses several related but different identifiers:

| Identifier | Example |
|---|---|
| LXD instance name | `grp12-resolv1` |
| Operating-system hostname | `resolv1.grp12.example.test` |
| DNS zone or host name | `grp12.example.test` |
| Architectural role | `resolver-bind` or `auth-platform` |
| Group identifier | `12` |

Scripts frequently match LXD instance names with regular expressions. Renaming an instance pattern is therefore an implementation change, not a cosmetic edit.

---

# Template Instances

| Name | Purpose | Normal state |
|---|---|---|
| `hostX` | general Ubuntu template | Stopped |
| `rtrX` | FRRouting router template | Stopped |
| `fortX` | FORT/RPKI validator template | Stopped |

The suffix `X` identifies a reusable template in the current implementation.

`setup-containers.sh` deletes previous names matching the historical `\S+X` pattern before rebuilding templates. This broad match deserves review before additional template naming schemes are introduced.

---

# Shared DNS Instances

| LXD name | Architectural role | Normal state |
|---|---|---|
| `dnsdist` | public DNS frontend | Running |
| `ns1` | `auth-platform` | Running |
| `auth-exercise` | exercise authority | Running |
| `auth-rpz` | RPZ authority | Running |

The LXD name `ns1` is retained for compatibility. In architecture documentation, its logical role is `auth-platform`.

---

# Per-Group Pattern

The canonical LXD form is:

```text
grp<group-number>-<role>
```

Examples:

```text
grp1-cli
grp1-rtr
grp1-resolv1
grp1-resolv2
grp1-soa
grp1-ns1
grp1-ns2
grp1-rpki
```

The group number is decimal and begins at `1`.

---

# Per-Group Roles

| Suffix | Role |
|---|---|
| `rtr` | group router |
| `cli` | participant client |
| `resolv1` | BIND resolver exercise target |
| `resolv2` | Unbound resolver exercise target |
| `soa` | primary/SOA authoritative exercise target |
| `ns1` | BIND authoritative secondary |
| `ns2` | NSD authoritative secondary |
| `rpki` | per-group RPKI validator |

The selected Lab Type determines which role instances are created. The router is part of every current group topology.

---

# Shared Routing and RPKI Names

| Name | Intended role |
|---|---|
| `iborder-rtr` | shared border/Anycast router and VPN endpoint |
| `rpki1` | first shared/global validator |
| `rpki2` | second shared/global validator |

These roles belong to the routing profiles, which require recovery and full regression testing.

---

# LXD Network Names

Group network names follow:

```text
grp<group-number>-<network-role>
```

Current suffixes:

```text
lan
int
dmz
extra
```

Examples:

```text
grp7-lan
grp7-int
grp7-dmz
grp7-extra
```

---

# Container Hostnames

Participant service containers use DNS-style hostnames:

```text
cli.grpN.<DOMAIN>
resolv1.grpN.<DOMAIN>
resolv2.grpN.<DOMAIN>
soa.grpN.<DOMAIN>
ns1.grpN.<DOMAIN>
ns2.grpN.<DOMAIN>
rpki.grpN.<DOMAIN>
```

Shared DNS hostnames include:

```text
dnsdist.<DOMAIN>
ns1.<DOMAIN>
```

`auth-exercise` and `auth-rpz` currently use short hostnames without the lab domain.

## Router hostname exception

The LXD instance remains:

```text
grpN-rtr
```

but the generated FRRouting configuration currently sets:

```text
rtr1.grpN.<DOMAIN>
```

because the router template substitutes a fixed router index of `1`.

The router operating-system hostname is not normalized by `routers.sh` in the same way as participant service containers. This inconsistency is documented for hardening.

---

# Role Names Versus Instance Names

Do not assume a one-to-one string match between architecture and implementation.

Examples:

| Architecture role | Current LXD name |
|---|---|
| `auth-platform` | `ns1` |
| public DNS frontend | `dnsdist` |
| group primary/SOA | `grpN-soa` |
| border router | `iborder-rtr` |

Architecture documents should prefer role names when discussing responsibility and instance names when discussing implementation or commands.

---

# Useful Match Patterns

Current cleanup scripts use patterns similar to:

```text
^grp[0-9]+-rtr$
^grp[0-9]+-cli$
^grp[0-9]+-resolv1$
^grp[0-9]+-resolv2$
^grp[0-9]+-soa$
^grp[0-9]+-ns1$
^grp[0-9]+-ns2$
^grp[0-9]+-rpki$
```

Group networks use:

```text
^grp[0-9]+-lan$
^grp[0-9]+-int$
^grp[0-9]+-dmz$
^grp[0-9]+-extra$
```

These anchored patterns avoid treating interface-address output as instance names.

---

# Counting Instances Correctly

A CSV display without selecting columns can include addresses and other comma-separated fields. Do not count raw display lines as instances.

Preferred API count:

```bash
lxc query /1.0/instances | jq 'length'
```

Names:

```bash
lxc query /1.0/instances | jq -r '.[] | split("/")[-1]'
```

Status counts:

```bash
lxc query '/1.0/instances?recursion=1' |
    jq -r 'group_by(.status)[] | "\(.[0].status): \(length)"'
```

A 60-group resolver deployment contained:

```text
240 group instances
7 shared/template instances
247 total
```

with `hostX`, `rtrX`, and `fortX` stopped.

---

# Count Formulas

## Lab Type 1

```text
4 instances per group
+ dnsdist, ns1, auth-exercise, auth-rpz
+ hostX, rtrX, fortX
= 4N + 7
```

## Lab Type 2

```text
7 instances per group
+ 7 shared/templates
= 7N + 7
```

Routing-profile counts require correction and regression testing before they are treated as stable formulas.

---

# Known Naming Defects

## Per-group RPKI template mismatch

`setup-containers.sh` creates:

```text
fortX
```

but `validators.sh` currently attempts:

```text
lxc copy RPKIfortX grpN-rpki
```

This is expected to block Lab Type 4 validator creation until corrected.

## Lab Type 3 flag mismatch

Lab Type 3 assigns `StudentAuthServers`, while component creation checks `StudentAuth`. This affects container creation but is not itself an instance-naming issue; it is listed here because expected names may be absent.

## Router identity mismatch

The LXD name, FRR hostname, and DNS-style participant naming are not fully aligned for routers.

---

# Naming Rules for New Roles

New instance names should:

- use lowercase ASCII;
- use hyphens as separators;
- retain the `grpN-` prefix for group-scoped roles;
- avoid overloading an existing suffix with a different responsibility;
- have an anchored cleanup pattern;
- define the expected DNS hostname separately;
- document whether the role is a template, shared instance, or per-group instance.

---

# Review Status

**Current Status:** In Review

**Next Review:** After routing/RPKI naming fixes and capability-driven role naming.
