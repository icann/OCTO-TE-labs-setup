# ADR-0002 - Shared DNS Service Separation

**Status:** In Review

**Date:** 2026-08-31

---

# Context

OCTO-TE Labs needs several authoritative and policy-related DNS behaviors at the same time:

- a public frontend reachable through the EC2 public IPv4 and IPv6 addresses;
- an authoritative service for the lab platform zone and DNSSEC signing;
- authoritative targets for resolver exercises, including intentionally unusual behaviors;
- an authoritative Response Policy Zone source;
- optional participant authoritative servers for each group.

Treating these responsibilities as one undifferentiated DNS server creates lifecycle coupling, makes exercises harder to isolate, and obscures which service owns a response.

The current implementation also needs to support resolver-only profiles without creating participant authoritative backends that do not exist.

---

# Decision

The shared DNS platform is separated into four explicit roles:

| Role | Current implementation | IPv4 | Responsibility |
|---|---|---:|---|
| Public DNS frontend | `dnsdist` | `100.64.0.53` | publish UDP/TCP DNS and route queries to the correct backend pool |
| Platform authority | `ns1` / `auth-platform` | `100.64.0.54` | serve and sign `<DOMAIN>`, own platform records, group delegations, and group DS data |
| Exercise authority | `auth-exercise` | `100.64.0.55-.57` | serve exercise-only authoritative zones and special targets |
| RPZ authority | `auth-rpz` | `100.64.0.58` | serve the RPZ zone transferred to participant resolvers |

The corresponding IPv6 addresses use the current `fd89:59e0:0::/48` platform prefix.

## Public frontend

`dnsdist` is the only shared public DNS frontend. Host DNAT forwards public UDP/TCP 53 to its internal IPv4 and IPv6 listeners.

The frontend rejects public UPDATE, NOTIFY, AXFR, IXFR, and CHAOS traffic according to the current security policy.

## Platform authoritative service

`ns1` is authoritative-only. It:

- serves the lab apex and platform records;
- signs the lab zone with BIND DNSSEC policy;
- provides the `ns1` target used by the parent delegation;
- stores group delegations and group DS records;
- supports apex DS generation for publication to the parent Route 53 zone.

## Exercise authority

Exercise-specific zones and intentionally special authoritative targets remain outside the platform zone and are served by `auth-exercise`.

The `.55`, `.56`, and `.57` addresses represent distinct exercise targets without requiring one container per target.

## RPZ authority

RPZ distribution remains a separate authoritative service. Participant resolver `resolv1` can transfer the zone as a secondary and apply the policy locally.

## Participant authoritative pools

Group authoritative backends are created in `dnsdist` only when the selected profile enables `StudentAuth=YES`.

For each enabled group, the current implementation retains four backend objects:

- `grpN-ns1` over IPv4;
- `grpN-ns1` over IPv6;
- `grpN-ns2` over IPv4;
- `grpN-ns2` over IPv6.

DS queries for `grpN.<DOMAIN>` stay on the platform authority because the DS belongs to the parent zone. Other queries at or below the group zone are routed to the group pool.

---

# Scope and Boundaries

This ADR decides service responsibility and separation. It does not approve every current implementation detail.

The following remain implementation or hardening work:

- platform `grpN` delegations are currently generated even when `StudentAuth=NO`;
- Lab Type 3 uses the wrong authoritative flag name;
- SOA serial modernization;
- NAT64/DNS64 capability selection;
- future replacement of numeric Lab Types with capability composition;
- possible future evaluation of one versus two internal backend transport families.

The current decision is to keep IPv4 and IPv6 backend objects for full DNS profiles.

---

# Consequences

## Positive

- Clear ownership of platform, exercise, policy, and participant DNS data.
- Independent lifecycle and troubleshooting for each service.
- Resolver exercises do not need to alter the platform authority.
- RPZ distribution is isolated from platform-zone signing.
- Resolver-only profiles avoid nonexistent participant backend objects.
- Public query routing can evolve without moving authoritative data into the frontend.
- Addressing and documentation have stable role names.

## Trade-offs and Risks

- More shared containers and configuration modules must be deployed and monitored.
- `dnsdist` routing rules must remain aligned with enabled capabilities and generated delegations.
- The public service depends on multiple backend roles being created in the correct order.
- IPv4 and IPv6 backend objects increase resource use for full DNS profiles.
- Naming must distinguish the public `ns1.<DOMAIN>` service from participant `grpN-ns1` containers.

---

# Validation

The separated design was validated during August 2026 through:

- direct IPv4 and IPv6 SOA queries to participant authoritative servers;
- public queries through `dnsdist`;
- platform-zone DNSSEC signing and external AD validation;
- RPZ AXFR/secondary transfer and policy rewrites;
- Lab Type 1 with only the platform backend;
- Lab Type 2 with four backend objects per group;
- internal wipe and redeploy from Type 1 to Type 2;
- CloudFormation delete and DNS cleanup.

Measured `dnsdist` behavior confirmed that creating nonexistent group backends has a material resource cost, reinforcing the capability-conditioned boundary.

---

# Related Documents

- [`../architecture/05-dns-capabilities.md`](../architecture/05-dns-capabilities.md)
- [`../architecture/07-platform-services.md`](../architecture/07-platform-services.md)
- [`../architecture/08-implementation.md`](../architecture/08-implementation.md)
- [`../reference/dns-naming.md`](../reference/dns-naming.md)
- [`../reference/lab-types.md`](../reference/lab-types.md)
- [`../development/engineering-log.md`](../development/engineering-log.md)
- [`../architecture/KNOWLEDGE-BASE.md`](../architecture/KNOWLEDGE-BASE.md)

---

# Related Knowledge

- KB-0006 - Shared DNS Roles Must Remain Separated
- KB-0007 - DNS Record Ownership Defines Cleanup Responsibility
- KB-0008 - Resource Generation Must Follow Enabled Capabilities
- KB-0017 - Apex DS and Group DS Records Use Different Control Paths
- KB-0019 - dnsdist Backend Count Has a Material Resource Cost

---

# Review Criteria

Promote this ADR to Approved only after:

- technical review of role boundaries and terminology;
- confirmation that architecture and reference documents use the same names;
- a decision on whether resolver-only profiles should generate group delegations;
- regression validation after the first hardening cycle.
