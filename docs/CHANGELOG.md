# Architecture & Engineering Handbook Changelog

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This changelog records significant updates to the OCTO-TE Labs Architecture & Engineering Handbook. It records documentation evolution rather than serving as the implementation release log.

Routine wording, spelling, or formatting changes do not normally require an entry.

---

# Version History

## 2026-08-31 - Verified Implementation Reconciliation, Batch 1

### Replaced placeholders with verified documentation

- Deployment lifecycle from S3 and CloudFormation through `cloud-init`, host preparation, container templates, orchestration, publication, and participant access.
- Shell orchestration model implemented by `scripts/setup-lab.sh` and `scripts/lab-tools/`.
- Current implementation map covering AWS, the EC2 host, LXD, shared DNS services, per-group resources, web access, and DNSSEC lifecycle.
- Current Lab Type 1-4 reference, including verified DNS profiles and known routing-profile limitations.
- DNS naming and parent-zone ownership reference.

### Updated operational guidance

- Clarified that CloudFormation `CREATE_COMPLETE` does not imply completion of the internal deployment.
- Corrected SSH access to use the CloudFormation-managed `ec2-<DnsName>.<DnsParent>` name on TCP/8484.
- Added the validated `cloud-init` completion criteria.
- Removed manual Route 53 record deletion from the normal stack take-down procedure.
- Documented the custom DS cleanup resource and idempotent deletion behavior.
- Documented support for lowercase DNS labels containing hyphens.
- Documented `AmiOverride` for exceptional updates of existing stacks.
- Documented the destructive internal `--deploy` workflow.

### Recorded current DNS architecture

- `dnsdist` public frontend at `100.64.0.53`.
- `ns1` platform authority at `100.64.0.54`.
- `auth-exercise` exercise authority at `100.64.0.55-100.64.0.57`.
- `auth-rpz` RPZ authority at `100.64.0.58`.
- Conditional group-authoritative pools in `dnsdist`: disabled for Lab Type 1 and retained as IPv4/IPv6 backends for Lab Type 2.

### Recorded known limitations

- Current 3-64 group limit in the shell orchestrator.
- Lab Type 3 `StudentAuthServers`/`StudentAuth` mismatch.
- Unconditional `grpN` delegations in the platform zone when group authority is disabled.
- Per-group RPKI template-name mismatch between `RPKIfortX` and `fortX`.
- Missing CloudFormation security-group ingress for the routing-profile WireGuard UDP port.
- The historical `-d` short option is accepted by `getopt` but not handled by the command parser.
- Routing and RPKI profiles require renewed validation.
- NAT64 wipe behavior and external dependency hardening remain pending.
- Higher scalability recovery and documentation are pending.

### Implementation baseline referenced

The Batch 1 documentation reflects the `nico` branch through implementation commit `b9ce623` and the August 2026 validation sessions.

---

## 2026-07-31 - Sprint 0, Architecture Foundation

### Added

- Initial Architecture & Engineering Handbook.
- Engineering Principles.
- Architecture Map.
- Platform Overview.
- Knowledge Base.
- ADR-0001.
- Engineering Log.
- Engineering Backlog.
- Documentation structure.
- Engineering workflow.
- Architecture review process.

### Established

- Capability-driven architecture.
- Architecture-driven engineering.
- Knowledge Base methodology.
- Engineering identifiers.
- Architecture Candidates.

---

# Review Status

**Current Status:** In Review

**Next Review:** After completion of the remaining 2026-08-31 documentation reconciliation batches.
