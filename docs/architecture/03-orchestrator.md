# Orchestration Architecture

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document describes the current orchestration model implemented by `scripts/setup-lab.sh` and the shell modules under `scripts/lab-tools/`.

The current orchestrator is profile-driven: a numeric Lab Type selects a set of boolean implementation flags. A future architecture is expected to move toward direct capability composition, but this document describes the verified implementation as it exists now.

---

# Orchestrator Entry Point

The entry point is:

```text
scripts/setup-lab.sh
```

It:

- enables `set -e -o pipefail`;
- sources every implementation module under `scripts/lab-tools/`;
- loads `scripts/deploy-parameters.cfg`;
- parses lifecycle and profile arguments;
- maps the selected Lab Type to internal flags;
- invokes lifecycle functions in a dependency-aware order.

The script is an imperative shell orchestrator rather than a declarative scheduler. Ordering and conditional execution are encoded directly in shell functions.

---

# Inputs

## Deployment parameters

`deploy-parameters.cfg` provides values such as:

- `DOMAIN`;
- `PARENT`;
- public IPv4 and IPv6 addresses;
- `LABTYPE`;
- `NETWORKS`;
- internal IPv6 prefix;
- participant instruction URL;
- optional shared password;
- VPN parameters used by routing profiles.

For an AWS deployment, UserData renders this file from `configs/deploy-parameters.cfg`.

## Command-line overrides

The orchestrator supports:

```text
-t, --type <1-4>
-n, --networks <3-64>
--deploy
--wipe
--stop_all
--start_all
```

There is currently no implemented `--help` option. Invalid options are reported by `getopt` using the historical command name `deploy.sh`. Command-line overrides change in-memory shell variables only and do not rewrite `deploy-parameters.cfg`. The historical `-d` short option is accepted by `getopt` and shown in `usage()`, but it is not handled by the parser.

---

# Lifecycle Actions

| Action | Current behavior |
|---|---|
| `--deploy` | Executes `wipe`, then `deploy` |
| `--wipe` | Stops and deletes the internal lab environment |
| `--stop_all` | Stops internal containers and platform services |
| `--start_all` | Starts the selected profile's internal components |

`--deploy` is destructive within the EC2 host. It is appropriate for rebuilding the lab on the same CloudFormation-managed host, not for preserving participant changes.

---

# Profile-to-Flag Mapping

The implementation uses these flags:

| Flag | Meaning |
|---|---|
| `StudentClients` | create one client container per group |
| `StudentResolvers` | create two resolver containers per group |
| `StudentAuth` | create one SOA/primary and two authoritative containers per group |
| `StudentRPKIvalidator` | create one RPKI validator per group |
| `StudentRouterAccess` | expose router access in participant web content |
| `GlobalRPKIvalidator` | create shared global validator containers |
| `BorderRouter` | create the shared border/Anycast router |

The current intended mapping is:

| Lab Type | Clients | Resolvers | Group authority | Group RPKI | Router access | Global RPKI | Border router |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | Yes | Yes | No | No | No | No | No |
| 2 | Yes | Yes | Yes | No | No | No | No |
| 3 | Yes | Yes | Intended | No | Yes | Yes | Yes |
| 4 | Yes | Yes | Yes | Yes | Yes | No | Yes |

## Known Lab Type 3 mismatch

The current Lab Type 3 branch assigns:

```text
StudentAuthServers=YES
```

but the rest of the orchestrator checks:

```text
StudentAuth
```

Therefore Lab Type 3 does not reliably enable group authoritative containers or their `dnsdist` pools. This is a confirmed implementation defect scheduled for correction and regression testing. Documentation must not represent Type 3 as production-verified until that work is complete.

---

# Modular Function Layout

`setup-lab.sh` delegates implementation work to sourced modules.

| Module | Primary responsibility |
|---|---|
| `networks.sh` | create/delete `lan`, `int`, `dmz`, and `extra` LXD networks |
| `routers.sh` | group routers and routing configuration |
| `cli.sh` | participant client containers |
| `studentres.sh` | participant resolver containers and network configuration |
| `studentauth.sh` | participant SOA and authoritative containers |
| `validators.sh` | group RPKI validators |
| `globalvalidators.sh` | shared RPKI validators |
| `borderrouter.sh` | border router, BGP neighbors, VPN, and Anycast support |
| `ns1.sh` | platform authoritative DNS, DNSSEC, group delegation, and DS publication |
| `auth-exercise.sh` | exercise authoritative service and special authoritative targets |
| `auth-rpz.sh` | RPZ authoritative service |
| `dnsdist.sh` | public DNS frontend and query routing |
| `tayga.sh` | host NAT64 service |
| `letsencrypt.sh` | certificate lifecycle |
| `nginx.sh` | web virtual hosts and authentication |
| `webssh.sh` | WebSSH service lifecycle |
| `web.sh` | generated group web pages and topology links |
| `instructions.sh` | participant instruction retrieval and Jekyll build |
| `passwords.sh` | shared and group credential generation |
| `cron.sh` | scheduled operational tasks |

This modularity is useful, but the modules share global variables and assume a specific calling order.

---

# Deploy Sequence

The current `deploy()` sequence is dependency-aware.

```text
passwords
  -> group networks
  -> group routers
  -> shared authoritative DNS
  -> NAT64
  -> dnsdist
  -> optional routing/RPKI shared services
  -> participant containers
  -> start and configure topology
  -> certificate
  -> nginx/WebSSH/content/instructions
  -> cron
  -> DS publication
```

## Shared DNS ordering

The shared authoritative services are created before `dnsdist`:

```text
create_ns1
create_auth_exercise
create_auth_rpz
create_nat64
create_dnsdist
```

This allows `dnsdist` to be finalized against known backend addresses before public service and certificate validation.

## Group authoritative condition

`dnsdist` generates group authoritative pools only when:

```text
StudentAuth=YES
```

For Lab Type 1, only the platform authoritative backend is registered. For Lab Type 2, each group retains four backend objects:

- group `ns1` over IPv6;
- group `ns2` over IPv6;
- group `ns1` over IPv4;
- group `ns2` over IPv4.

This conditional removed hundreds of nonexistent downstream objects from large resolver-only deployments. The platform-zone generator in `ns1.sh` still emits `grpN` NS delegations for every selected group regardless of `StudentAuth`; in Lab Type 1 those delegations have no group-authoritative pool behind them. Aligning delegation generation with the same capability flag is a documented hardening item.

---

# Start and Stop Sequences

`start_all()` and `stop_all()` use the selected profile flags. Shared DNS follows a frontend/backend dependency rule:

- start authoritative backends before `dnsdist`;
- stop `dnsdist` before authoritative backends.

The current `start_all()` contains a likely implementation error: both the resolver and authoritative branches call a generic `start_student_servers` name rather than the verified specific functions used during `deploy()`. This path requires dedicated regression testing before being considered fully reliable.

---

# Wipe Semantics

`wipe()` temporarily sets:

```text
NETWORKS=64
```

before calling `stop_all` and `delete_all`. This attempts to remove any group resources within the current supported range, even when the active deployment selected fewer groups.

The function disables immediate exit during cleanup so that missing resources do not stop the remaining deletion sequence.

This model is practical but produces several hardening needs:

- cleanup functions should explicitly test resource existence;
- NAT64 teardown currently invokes an invalid TAYGA option and can report missing interfaces;
- some iptables deletion commands report errors when the rule is absent;
- lifecycle operations need consistent idempotency guarantees;
- the fixed cleanup ceiling must evolve with the planned higher group limit.

---

# Per-Group Network Model

Every selected group receives four LXD networks:

```text
grpN-lan
grpN-int
grpN-dmz
grpN-extra
```

The router is always created and attached to all four networks. The remaining containers are created according to the selected profile.

Prepared host routes and per-group LXD networks are intentionally separate:

- host routes are prepared for a design capacity;
- LXD networks and containers are created only for selected groups.

This hybrid model supports fast later expansion while avoiding the memory cost of pre-creating containers.

---

# Credentials and Output

`passwords.sh` creates:

- one `labuser` password, optionally supplied by the stack parameter;
- one random password per group.

The password file is:

```text
/home/ubuntu/grouppasswords.txt
```

Current modules also print several generated passwords to standard output. Reducing secret exposure in logs is a hardening requirement.

VPN private-key output is currently redacted in the main parameter summary, but all modules require review for equivalent handling.

---

# External Dependencies

The orchestrator installs or downloads components during deployment from several external services, including:

- Ubuntu repositories;
- ISC BIND PPA;
- PowerDNS repositories;
- FRRouting repository;
- RubyGems;
- GitHub instruction archives;
- Let's Encrypt.

This makes a new deployment sensitive to upstream metadata, package removal, rate limits, and compatibility changes. A 2026-08-31 deployment initially failed because the FRRouting repository index referenced packages that returned HTTP 404; a later identical deployment succeeded when the upstream repository became consistent again.

Version pinning, caching, prebaked images, and clearer retry policy are future hardening topics.

---

# Current Architectural Constraints

- Shell globals couple modules to `setup-lab.sh`.
- Numeric Lab Types encode capability combinations indirectly.
- The group limit is hard-coded in more than one layer.
- Cleanup is partly best-effort rather than fully idempotent.
- External dependencies are resolved at deployment time.
- Logging is verbose and can expose sensitive values.
- Routing profile behavior is less verified than DNS profile behavior.
- Platform `grpN` delegations are not yet conditioned on `StudentAuth`.
- Per-group RPKI creation references `RPKIfortX`, while base preparation creates `fortX`.
- Routing profiles configure a WireGuard UDP listener, but the current CloudFormation security group does not expose that UDP port.
- The historical `-d` short option is not implemented by the parser.

---

# Planned Evolution

The target direction is capability-driven orchestration:

```text
selected capabilities
    -> derived required roles
    -> dependency graph
    -> deployment plan
    -> validation plan
```

A future orchestrator should preserve the useful module boundaries while reducing global state, making dependencies explicit, and allowing a profile to be expressed as a named capability set rather than a numeric case statement.

That future design is documented under [`../design/`](../design/README.md). It is not yet the current implementation.

---

# Review Status

**Current Status:** In Review

**Next Review:** After correction and regression testing of lifecycle actions and routing-profile flag mapping.
