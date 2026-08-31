# Engineering Roadmap

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

The roadmap defines the strategic sequence for understanding, hardening, scaling, restoring, and evolving OCTO-TE Labs. Detailed work items are maintained in [`engineering-backlog.md`](engineering-backlog.md).

---

# Roadmap Principles

- Understand and document current behavior before redesigning it.
- Correct security and lifecycle risks before increasing exposure or scale.
- Recover measurable capacity rather than relying on historical claims alone.
- Restore routing and RPKI with the same regression depth used for DNS.
- Preserve working behavior while moving toward capability-driven orchestration.
- Keep the Handbook synchronized with code and test evidence.

---

# Current Position

```text
M0 Architecture foundation                 Completed
M1 Current implementation baseline         Completed
M2 Deployment and security hardening       In Progress
M3 Scalability recovery                    Planned
M4 Routing and RPKI recovery               Planned
M5 Capability-driven platform evolution    Planned
```

The order reflects the agreement reached after the August 2026 DNS, lifecycle, and scalability investigations. A production-blocking issue can be addressed earlier when necessary.

---

# M0 - Architecture Foundation

**Related:** Sprint 0, ADR-0001

**Status:** Completed

## Outcomes

- Handbook structure established.
- Engineering principles documented.
- Knowledge Base, Engineering Log, Backlog, and ADR process introduced.
- Capability-oriented conceptual architecture established.

---

# M1 - Current Implementation Baseline

**Related:** EPIC-001

**Status:** Completed

**Review State:** Baseline documents remain In Review under TASK-0026 until explicit approval decisions are made.

## Objective

Create an evidence-based reference for the current AWS, Ubuntu, LXD, DNS, orchestration, network, lifecycle, and profile behavior.

## Completed Outcomes

- CloudFormation and cloud-init lifecycle documented.
- Shared DNS service separation restored and validated.
- Lab Types 1 and 2 deployed and regression-tested.
- DNSSEC publication, validation, cleanup, and name reuse tested.
- Hyphenated DNS labels tested end to end.
- 60-group resolver baseline measured.
- dnsdist profile-awareness corrected and measured.
- AMI pinning mechanism added for exceptional stack updates.
- Core, network, service, AWS, LXD, naming, addressing, port, and software documentation refreshed.
- Institutional memory, engineering tracking, the decisions index, and ADR-0002 refreshed.
- Remaining architecture, design, navigation, and acronym documents completed.
- Global metadata, relative-link, code-fence, placeholder, index-coverage, and consistency validation completed.

## Review Follow-up

- Perform TASK-0026 technical review before promoting any document to Approved.
- Keep the baseline synchronized with implementation and validation changes introduced during hardening.

---

# M2 - Deployment and Security Hardening

**Related:** EPIC-004

**Status:** In Progress

## Objective

Make normal deployment, internal redeployment, failure handling, and deletion secure, idempotent, reproducible, and understandable.

## Priority Order

1. Protect the active WebSSH endpoint.
2. Eliminate fixed bootstrap credentials and verify role-specific rotation.
3. Make NAT64 and iptables cleanup idempotent.
4. Align WireGuard parameterization, DNAT, and Security Group ingress.
5. Correct lifecycle parser and start/stop defects.
6. Reduce secret-bearing and excessively verbose logs.
7. Pin or cache external dependencies and modernize the documentation toolchain.
8. Add readiness signaling and automated validation.
9. Modernize SOA serial handling and remove legacy workflow artifacts.

## Exit Criteria

- No fixed default credentials remain in deployable templates or roles.
- WebSSH has an explicit, tested access-control model.
- Repeated wipe/delete operations succeed without invalid-command or missing-rule errors.
- A failed internal deployment is clearly represented and diagnosable.
- External dependencies are versioned or controlled sufficiently for reproducible tests.
- A live `AmiOverride` change-set test is complete.

---

# M3 - Scalability Recovery

**Related:** EPIC-005

**Status:** Planned

## Objective

Recover and quantify 100+ group support without sacrificing service correctness, security, or cleanup reliability.

## Planned Outcomes

- Central supported-capacity parameter rather than scattered `64` constants.
- Generated and validated host route configuration.
- On-demand group bridges and containers with later expansion support.
- Controlled 60, 80, 100, and higher group benchmarks.
- Capacity matrix for resolver, full DNS, and RPKI profiles.
- Role-specific resource limits.
- Dynamic per-deployment ULA policy.
- Clear instance-size recommendations backed by evidence.

## Exit Criteria

- At least one 100+ group deployment completes and passes functional validation.
- Memory, CPU, storage, network, dnsdist, LXD, and cleanup measurements are recorded.
- The supported group limit is raised only to an evidence-backed value.

---

# M4 - Routing and RPKI Recovery

**Related:** EPIC-002

**Status:** Planned

## Objective

Restore the original routing and secure-routing training capability on the current platform baseline.

## Planned Outcomes

- Lab Type 3 flag mismatch corrected.
- Group RPKI template naming corrected.
- WireGuard ingress and DNAT fully parameterized.
- Routing-only profile available without unnecessary participant DNS services.
- BGP, Anycast, shared/global RPKI, group RPKI, RTR, VPN, and cleanup tested.
- FORT memory, storage, data freshness, and restart behavior measured.
- Original and current routing architectures compared and documented.

## Exit Criteria

- Types 3 and 4 complete end-to-end regression tests.
- Routing/RPKI profiles have capacity and resource guidance.
- Public exposure and credentials pass hardening review.

---

# M5 - Capability-Driven Platform Evolution

**Related:** EPIC-003, AC-0001 through AC-0004

**Status:** Planned

## Objective

Move from numeric Lab Types and implicit shell globals toward explicit capabilities, dependencies, and named training profiles.

## Potential Outcomes

- stable capability taxonomy;
- declarative role and dependency graph;
- instructor-facing profile selection;
- generated deployment and validation plans;
- clearer separation of platform, participant, security, and operational capabilities;
- migration path that preserves existing profiles.

## Entry Criteria

This milestone should not begin implementation until:

- the current baseline is reviewed;
- security/lifecycle hardening is complete;
- scale behavior is measured;
- routing/RPKI requirements are restored and understood.

---

# Governance

Review the roadmap:

- after each milestone;
- when an ADR is approved;
- when a production-blocking issue changes the sequence;
- when new requirements materially change capacity or training scope.

Update both this roadmap and the Backlog when priorities change.

---

# Review Status

**Current Status:** In Review

**Next Review:** After the first hardening implementation batch and the baseline technical review.
