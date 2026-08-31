# Immediate Engineering Tasks

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This file contains short-lived immediate actions. Durable work belongs in the Engineering Backlog. Completed items should be removed or transferred to the Engineering Log rather than accumulating here indefinitely.

---

# Documentation Governance

- [ ] Perform TASK-0026 technical review and decide which baseline documents can be promoted from In Review to Approved.
- [ ] Keep the Handbook synchronized with hardening changes and new validation evidence.

---

# Current Hardening Actions

- [ ] Reproduce the active WebSSH virtual-host configuration and implement explicit authentication/access control.
- [ ] Inventory inherited accounts in `hostX`, `rtrX`, shared DNS, routers, validators, and border-router roles.
- [ ] Remove fixed bootstrap credentials and add regression tests for every role.
- [ ] Fix TAYGA/NAT64 teardown and repeated iptables cleanup.
- [ ] Align WireGuard `VPNlistenPort`, DNAT add/delete rules, and CloudFormation Security Group ingress.
- [ ] Create a disposable existing stack and validate `AmiOverride` through a nonexecuted change set.

---

# Validation Reminders

- [ ] Use `cloud-init status --long`; do not treat `CREATE_COMPLETE` as readiness.
- [ ] Count LXD instances through `/1.0/instances`, not repeated address rows.
- [ ] Test success, failure, deletion, and immediate name reuse for lifecycle changes.
- [ ] Keep platform deployment validation separate from `do-dns-lab.sh` exercise activation.
- [ ] Do not claim Types 3 or 4 production-ready before their known blockers are fixed.
- [ ] Do not raise the 64-group limit before post-hardening capacity tests are complete.

---

# Pending Evidence to Collect

- [ ] Live `AmiOverride` change-set behavior.
- [ ] Post-fix 60-group dnsdist memory and thread measurements.
- [ ] 80/100+ group resolver and full DNS capacity measurements.
- [ ] FORT role memory, storage, RTR, and restart measurements.
- [ ] Routing-only profile behavior with DNS participant services disabled.

---

# Maintenance Rule

When an item becomes durable, move it to:

- [`engineering-backlog.md`](engineering-backlog.md) for planned work;
- [`engineering-log.md`](engineering-log.md) for completed work;
- [`../architecture/KNOWLEDGE-BASE.md`](../architecture/KNOWLEDGE-BASE.md) for a durable lesson;
- [`../decisions/`](../decisions/README.md) for a significant decision.
