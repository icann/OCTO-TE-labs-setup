# Architecture & Engineering Handbook Changelog

**Status:** In Review

**Last Updated:** 2026-09-01

---

# Purpose

This changelog records significant updates to the OCTO-TE Labs Architecture & Engineering Handbook. It records documentation evolution rather than serving as the implementation release log.

Routine wording, spelling, or formatting changes do not normally require an entry.

---

# Version History

## 2026-09-01 - Integrated Instructions and Deployment UX

### Added operational instruction control

- Added the cross-profile `IntegratedInstructions=YES/NO` deployment option.
- `YES` preserves the integrated per-group instruction workflow and requires a non-empty `labInstructions` source URL.
- `NO` omits the group-page link, skips the Jekyll instruction build, and removes the reserved per-group `instructions` path.
- Validated both modes with three-group Lab Type 1 deployments and clean `cloud-init` completion.

### Improved CloudFormation operator experience

- Grouped all template parameters by operator task with `AWS::CloudFormation::Interface`.
- Added friendly console labels while preserving the existing CLI/API parameter IDs.
- Verified a Quick Create path with editable `LAB-YYYYMMDD-LOCATION` stack-name prefill and an explicit active-region warning.
- Clarified the `DnsName` policy and its complete 3-32 character validation message.

### Recorded lifecycle evidence and follow-up

- Revalidated deletion and immediate recreation of `testing.te-labs.training`, including A, AAAA, delegation, DS publication, HTTPS, and DNSSEC validation.
- Recorded that recursive and workstation resolver state can lag briefly after the authoritative and Route 53 state is already correct.
- Identified that `--deploy` currently performs `wipe` before the enabled-instruction source validation inside `deploy()`.
- Reserved `/var/www/<DOMAIN>/html/grpN/instructions` for the integrated pipeline because `NO` removes that path unconditionally.
- Recorded the publication-workflow region mismatch: the sync action declares `us-east-2`, while the current `nico` bucket is in `us-east-1`.

### Implementation and documentation commits

- `0a8832c` - Add optional integrated lab instructions.
- `6793da4` - Group CloudFormation deployment parameters.
- `51e3d71` - Clarify DNS name validation guidance.
- `dc719a4` - Include DNS name length in validation message.
- `9e37720` - Document integrated instructions and deployment UX.

---

## 2026-08-31 - Verified Implementation Reconciliation, Batch 4

### Completed architecture and navigation coverage

- Refreshed the Architecture Map and Platform Overview.
- Replaced the Routing Capabilities placeholder with a current-state and recovery reference.
- Updated Engineering Principles to include security, lifecycle, reproducibility, ownership, and measured scalability.
- Reviewed ADR-0001 against the reconciled engineering model.
- Replaced section README placeholders with navigable indexes.
- Added a complete acronym and abbreviation reference.

### Developed future-design proposals

- Defined a candidate capability model and capability lifecycle.
- Defined target module contracts and incremental modularization principles.
- Defined a capability-driven future orchestrator with profile compatibility.
- Defined the target direction and validation gates for routing and RPKI recovery.

### Final consistency work

- Reconciled documentation status tables and reading paths.
- Marked future-design documents as Draft and current-state documents as In Review.
- Established deployment and security hardening as the next engineering phase.

---

## 2026-08-31 - Verified Implementation Reconciliation, Batch 3

### Updated institutional memory

- Expanded the Knowledge Base with durable architecture, lifecycle, scaling, security, and operational findings.
- Updated the Engineering Log with the August 2026 validation and documentation phases.
- Rebuilt the Engineering Backlog around confirmed bugs, debt, improvements, and future work.
- Updated the Roadmap, immediate To-do, and Ideas documents.

### Added decision record

- Added ADR-0002, Shared DNS Service Separation, with status In Review.
- Updated the ADR index and cross references.

---

## 2026-08-31 - Verified Implementation Reconciliation, Batch 2

### Documented networks and platform services

- Current network topology, backbone, group networks, IPv4, IPv6, NAT64, and prepared routes.
- DNS capabilities and shared DNS-service behavior.
- nginx, WebSSH, authentication, certificate, instructions, and supporting host services.
- AWS resources and services.
- LXD profiles, templates, limits, storage, and instance inventory.
- Container naming, addressing, ports, protocols, and software stack.
- Mermaid deployment-flow and network-topology diagrams.

### Registered hardening findings

- WebSSH virtual host without nginx-layer authentication.
- Fixed bootstrap credentials inherited from base templates.
- WireGuard parameter, DNAT, cleanup, and Security Group mismatch.
- Per-group validator template-name mismatch.
- External dependency and runtime installation risks.

---

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

The reconciliation reflects the `nico` branch through implementation commit `b9ce623` and the August 2026 validation sessions.

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

**Next Review:** After the first hardening implementation batch is documented.
