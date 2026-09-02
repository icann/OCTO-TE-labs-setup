# ADR-0003 - Unified Lab Identity and Access

**Status:** In Review

**Date:** 2026-09-02

---

# Context

OCTO-TE Labs currently exposes the main lab site and the separate `webssh.<DOMAIN>` virtual host with fragmented access controls. The main landing page is public, group paths use individual nginx Basic Authentication files, and the active WebSSH virtual host has no nginx-layer authentication.

The platform must support two legitimate operating patterns without creating two deployment modes:

- an instructor distributes the single `labuser` credential and all participants can reach every group;
- an instructor distributes `grpN` credentials and each participant group can reach only its own resources, while `labuser` remains the instructor-wide account.

The user experience must require one credential entry per browser profile and deployment. The same authenticated session must then cover the main lab site and WebSSH during normal operation.

The lab zones `grpN.<DOMAIN>` can be controlled by participants during authoritative-DNS exercises. A session cookie scoped to the parent `<DOMAIN>` would therefore also be sent to participant-controlled descendants. The identity design must not rely on a parent-domain application cookie.

OCTO-TE Labs are temporary deployments. Their primary security window is the active lifetime of the deployment, and stack deletion or internal wipe/redeploy is the normal revocation boundary.

---

# Decision

## Identity architecture

The platform will introduce one shared LXC service named:

```text
identity-platform
```

with these initial internal addresses:

```text
IPv4: 100.64.0.60
IPv6: fd89:59e0:0::60
```

The public identity portal will be:

```text
auth.<DOMAIN>
```

The service will run:

| Process | Initial listener | Responsibility |
|---|---:|---|
| Authelia | TCP/9091 | local identity provider and OpenID Connect provider |
| OAuth2 Proxy - main | TCP/4180 | session and authentication gateway for `https://<DOMAIN>` |
| OAuth2 Proxy - WebSSH | TCP/4181 | session and authentication gateway for `https://webssh.<DOMAIN>` |
| Redis | loopback TCP/6379 | persistent session storage inside `identity-platform` |

These internal listeners are not exposed by the AWS Security Group. Host nginx remains the only public HTTP/HTTPS entry point.

## State and persistence

The initial state backends are:

| State | Backend | Responsibility |
|---|---|---|
| Local identities | generated Authelia YAML users database | stores `labuser`, `grpN`, password hashes, and group assignments |
| Authelia application state | local SQLite database | stores the single-instance identity-provider state required by Authelia |
| Authelia and OAuth2 Proxy sessions | Redis with local persistence | preserves active sessions through normal process, container, and EC2 restarts |

SQLite is selected because each LAB initially runs one `identity-platform` instance. This keeps the deployment self-contained, but it makes the identity service stateful and does not support multi-instance high availability. A future HA design would require an external SQL backend.

The Authelia storage encryption key is generated once per internal deployment and remains stable through normal restarts, like the other identity secrets.

## OIDC and cookie boundaries

Authelia will act as the OpenID Connect provider. The main site and WebSSH will each use a dedicated OAuth2 Proxy process.

The two application sessions must use independent host-only cookies:

```text
__Host-octo-te-main
__Host-octo-te-webssh
```

The cookies must be `Secure`, `HttpOnly`, use path `/`, omit the `Domain` attribute, and use `SameSite=Lax` unless browser testing demonstrates a justified exception.

Authelia's own portal session cookie is limited to `auth.<DOMAIN>`. No application session cookie may be scoped to the parent `<DOMAIN>` because participant-controlled names exist below `grpN.<DOMAIN>`.

A user may experience an OIDC redirect the first time each protected virtual host is visited, but must not be required to enter the password again while the identity session remains valid.

## Accounts and authorization

Every deployment continues to create:

```text
labuser
grp1
grp2
...
grpN
```

The initial identity backend is a generated local Authelia users database with password hashes and group assignments:

```text
labuser -> lab-admin
grpN    -> lab-participant + grpN
```

The authorization model is always available; no CloudFormation access-mode selector is added.

- `labuser` can access the landing page, common resources, every `/grpN` path, and WebSSH.
- `grpN` can access the landing page, common resources, its own `/grpN` path, and WebSSH.
- `grpN` is denied access to every other group path.

The instructor chooses the operational model by deciding which credentials to distribute. Group-specific SSH credentials remain the final authorization boundary at the target server. Strict correlation between the authenticated web identity and the requested WebSSH target is a possible later defense-in-depth improvement, not a prerequisite for the first cutover.

## Session lifetime

The target session lifetime is ten days:

```text
Authelia inactivity:        10d
Authelia expiration:        10d
Authelia remember-me mode:  disabled
OIDC access token:          1h
OIDC ID token:              1h
OIDC refresh token:         240h
OAuth2 Proxy cookie expiry: 240h
OAuth2 Proxy refresh:       before the 1h access-token expiry
```

The platform should not force reauthentication during normal use within this period. Client-side cookie deletion, private-browser termination, explicit logout, use of another browser/device, and browser privacy policy remain outside the platform guarantee.

Redis-backed sessions and persistent Redis storage are used so normal service, container, and EC2 restarts do not intentionally invalidate active sessions.

## Secret lifecycle

Each internal deployment generates new values for:

- the Authelia session secret;
- the Authelia storage encryption key;
- the OIDC HMAC secret, signing key, and client secret;
- each OAuth2 Proxy cookie/session secret;
- the Redis credential.

These values remain stable through normal restarts and are regenerated by internal wipe/redeploy. Old browser sessions must not authenticate to a newly deployed identity epoch, even when the same DNS name is reused.

Operator-supplied shared passwords should not be reused across training events. This is an operational warning and documentation requirement; the platform will not enforce password history or cross-deployment uniqueness.

## Availability and emergency access

Normal authentication is fail closed. Loss of Authelia, OAuth2 Proxy, or Redis must not automatically make the lab public.

The operational states are:

```text
NORMAL
  Authelia + OAuth2 Proxy + per-user authorization

RECOVERY
  explicit health checks and service/container recovery

EMERGENCY
  operator-enabled nginx Basic Authentication using labuser
```

The platform will provide explicit operator commands equivalent to:

```text
lab-auth status
lab-auth recover
lab-auth emergency-enable
lab-auth emergency-disable
```

Emergency mode never permits anonymous access. It may require the same Basic Authentication credential once per virtual host; this reduced user experience is acceptable only as a temporary continuity mechanism.

## Future identity integration

The local users file is the first backend. A future deployment may connect Authelia to an ICANN-managed LDAP or Active Directory service without redesigning the nginx and OAuth2 Proxy boundaries.

Federation to an external OIDC- or SAML-only corporate provider is not decided by this ADR and requires a separate compatibility and privacy review.

---

# Scope and Boundaries

This ADR decides:

- the identity component boundary;
- the service name, hostname, and initial internal address;
- use of Authelia, a generated local users database, SQLite application storage, two OAuth2 Proxy processes, and Redis;
- host-only application cookie boundaries;
- the shared and per-group authorization model;
- the ten-day session target;
- fail-closed behavior and explicit emergency fallback;
- the ephemeral secret and revocation lifecycle.

This ADR does not yet decide:

- the final pinned package versions and artifact checksums;
- every nginx implementation detail;
- strict WebSSH target-to-group correlation;
- removal of SSH credentials from generated WebSSH URLs;
- external corporate identity federation beyond a future LDAP-compatible backend;
- high availability across multiple identity containers.

`webssh.<DOMAIN>` remains a separate virtual host.

---

# Consequences

## Positive

- The public landing page, group content, and WebSSH gain a consistent authentication boundary.
- Participants enter credentials once during normal use.
- `labuser` and per-group credentials coexist without separate deployment modes.
- Group-path authorization is enforced server-side rather than by hiding links.
- Host-only cookies avoid exposing application sessions to participant-controlled DNS descendants.
- The identity provider can later use an LDAP-compatible ICANN directory.
- Redis-backed sessions survive ordinary process, container, and host restarts.
- Explicit emergency access provides continuity without automatic anonymous fail-open.

## Trade-offs and Risks

- The design adds one shared LXC and four internal processes.
- Authentication becomes a dependency of all web access and must be observable and recoverable.
- OIDC and reverse-proxy configuration add deployment and browser-testing complexity.
- As of 2026-09-02, [Authelia documents its OpenID Connect Provider role as open beta](https://www.authelia.com/configuration/identity-providers/openid-connect/provider/). Versions must be pinned, and browser and lifecycle regression must pass before merge.
- Redis is a local dependency and requires persistence, backup-free recovery semantics, and secure credentials.
- SQLite makes the initial identity service stateful and constrains it to one Authelia instance; moving to high availability requires an external SQL backend.
- WebSSH URLs continue to carry target credentials until separately hardened.
- Emergency mode temporarily loses per-group web authorization and relies on the shared `labuser` credential.

---

# Validation

The architecture must not be merged into `nico` until it is validated with:

- `labuser` access to all groups;
- `grpN` access to its own path and denial from other group paths;
- one password entry across the main site and WebSSH;
- host-only cookie inspection showing no parent-domain application cookie;
- Chrome, Firefox, Safari, and Edge;
- 3-, 30-, and 60-group deployments;
- normal service restart, identity-container restart, and EC2 stop/start with SQLite and Redis state preserved;
- ten-day expiry behavior or an accelerated equivalent test;
- Authelia, OAuth2 Proxy, and Redis failure with fail-closed results;
- successful explicit recovery;
- emergency enable/disable with nginx configuration validation;
- internal wipe/redeploy invalidating the previous identity epoch;
- deletion and recreation with the same DNS name;
- no unexpected public ports or Security Group ingress.

---

# Related Documents

- [`../architecture/00-architecture-map.md`](../architecture/00-architecture-map.md)
- [`../architecture/07-platform-services.md`](../architecture/07-platform-services.md)
- [`../architecture/08-implementation.md`](../architecture/08-implementation.md)
- [`../reference/network-addressing.md`](../reference/network-addressing.md)
- [`../reference/ports.md`](../reference/ports.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)
- [`../development/todo.md`](../development/todo.md)

---

# Review Criteria

Promote this ADR to Approved only after:

- the foundation runs independently in `nico-auth` without changing public nginx behavior;
- package versions and checksums are pinned;
- cookie and authorization boundaries are verified in browser developer tools;
- the normal, recovery, and emergency states pass regression tests;
- the design is reviewed by the OCTO-TE team;
- the complete implementation is ready to merge without changing the stable `nico` deployment path unexpectedly.
