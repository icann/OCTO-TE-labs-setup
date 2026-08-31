# Development

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This directory contains records of engineering work, planning, chronology, immediate actions, and candidate ideas.

These documents describe activity and intent. Durable technical lessons belong in the [`Knowledge Base`](../architecture/KNOWLEDGE-BASE.md), and significant architectural decisions belong under [`../decisions/`](../decisions/README.md).

---

# Documents

| Document | Responsibility |
|---|---|
| [`engineering-log.md`](engineering-log.md) | Chronological record of completed and active engineering sessions |
| [`engineering-backlog.md`](engineering-backlog.md) | Master list of epics, bugs, debt, improvements, features, and documentation work |
| [`roadmap.md`](roadmap.md) | Strategic sequence and milestone outcomes |
| [`todo.md`](todo.md) | Short-lived immediate tasks and checks |
| [`ideas.md`](ideas.md) | Uncommitted ideas that may later become backlog items or designs |

---

# Update Rules

- Completed work is recorded in the Engineering Log.
- Confirmed future work receives a Backlog identifier.
- Strategic priority changes update both Roadmap and Backlog.
- To-do entries are removed or promoted when resolved.
- Ideas do not become commitments until reviewed.
- Durable findings are copied into the Knowledge Base rather than left only in the Log.
- Significant accepted design decisions become ADRs.

---

# Status Rules

Backlog work items use:

- Planned;
- In Progress;
- Blocked;
- Completed;
- Deferred.

The section documents themselves remain In Review until the engineering process is explicitly approved.

---

# Current Sequence

The current sequence is:

1. deployment and security hardening;
2. higher-scale recovery and measurement;
3. routing/RPKI recovery;
4. capability-driven platform evolution.

The Handbook reconciliation is complete. Technical review and approval decisions for baseline documents continue under `TASK-0026` while hardening begins.

See [`roadmap.md`](roadmap.md) and [`engineering-backlog.md`](engineering-backlog.md) for details.

---

# Review Status

**Current Status:** In Review

**Next Review:** At the start and end of each major engineering phase.
