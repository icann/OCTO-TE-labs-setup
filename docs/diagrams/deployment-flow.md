# Deployment Flow Diagram

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document provides visual summaries of the OCTO-TE Labs deployment and deletion lifecycles.

The detailed narrative is in [`../architecture/02-deployment-flow.md`](../architecture/02-deployment-flow.md).

---

# Creation Flow

```mermaid
flowchart TD
    GIT[Repository branch] --> RENDER[GitHub Actions renders placeholders]
    RENDER --> S3[S3 branch content]
    S3 --> CF[CloudFormation CreateStack]

    CF --> NET[VPC, subnet, routes, security group]
    CF --> IAM[IAM roles and policies]
    CF --> EC2[Ubuntu EC2 host]
    CF --> R53[NS, glue, and ec2 records]
    CF --> LAMBDA[IPv6 and DNS-cleanup custom resources]

    EC2 --> UD[UserData / cloud-init]
    UD --> HOST[setup-host.sh]
    HOST --> TEMPLATES[setup-containers.sh]
    TEMPLATES --> ORCH[setup-lab.sh --deploy]

    ORCH --> SHARED[Shared DNS and platform services]
    ORCH --> GROUPS[Per-group networks and containers]
    ORCH --> WEB[Certificate, nginx, WebSSH, instructions]
    ORCH --> DS[Publish DS to parent Route 53]

    DS --> READY[cloud-init done / DEPLOY DONE]
```

---

# Readiness Boundary

```mermaid
sequenceDiagram
    participant Operator
    participant CloudFormation
    participant EC2
    participant CloudInit
    participant Orchestrator

    Operator->>CloudFormation: Create stack
    CloudFormation->>EC2: Create instance and UserData
    CloudFormation-->>Operator: CREATE_COMPLETE
    Note over Operator,CloudFormation: AWS resources exist; lab may not be ready

    EC2->>CloudInit: Run final modules
    CloudInit->>Orchestrator: setup-host, templates, deploy
    Orchestrator-->>CloudInit: DEPLOY DONE
    CloudInit-->>Operator: status: done, errors: []
```

---

# Internal Redeployment

```mermaid
flowchart LR
    ACTIVE[Existing EC2 and LXD lab]
    WIPE[setup-lab.sh --deploy performs wipe]
    REBUILD[Create selected Lab Type and group count]
    REPUBLISH[Rebuild DNS, web, credentials, instructions, DS]
    READY[Internal lab ready]

    ACTIVE --> WIPE --> REBUILD --> REPUBLISH --> READY
```

The EC2, VPC, EIP, IAM, and CloudFormation stack remain in place.

Command-line profile and group overrides are process-local and do not modify `deploy-parameters.cfg`.

---

# Participant DNS Activation

```mermaid
flowchart LR
    PLATFORM[Platform deployment complete]
    CONTAINERS[Participant containers exist]
    ACTIVATE[do-dns-lab.sh]
    SERVICES[BIND, Unbound, and NSD configured]
    EXERCISE[DNS exercise ready]

    PLATFORM --> CONTAINERS --> ACTIVATE --> SERVICES --> EXERCISE
```

Platform-ready and exercise-ready are separate states.

---

# Deletion Flow

```mermaid
flowchart TD
    DEL[DeleteStack from CLI or console]
    CUSTOM[labDnsCleanup Delete event]
    FIND[Locate parent zone and exact DS]
    DSDEC{DS exists?}
    DELDS[Delete DS]
    SUCCESS[Return SUCCESS]
    NATIVE[Delete CloudFormation Route 53 records]
    EC2DEL[Delete EC2, EIP, VPC, IAM, Lambda]
    DONE[Stack no longer exists]

    DEL --> CUSTOM --> FIND --> DSDEC
    DSDEC -- yes --> DELDS --> SUCCESS
    DSDEC -- no --> SUCCESS
    SUCCESS --> NATIVE --> EC2DEL --> DONE
```

A real AWS API error returns failure rather than silently leaving DNS state behind.

---

# Failure Boundaries

```mermaid
flowchart TD
    TEMPLATE[Template and parameter validation]
    AWS[AWS resource creation]
    CI[cloud-init and UserData]
    PKG[External package repositories]
    LXD[LXD and service creation]
    DNS[DNS and DNSSEC publication]
    WEB[HTTPS and WebSSH]

    TEMPLATE --> AWS --> CI --> PKG --> LXD --> DNS --> WEB
```

Each boundary has a different source of truth:

| Boundary | Evidence |
|---|---|
| Template | CloudFormation validation |
| AWS resources | CloudFormation events |
| UserData | cloud-init status and log |
| Packages | APT/download output |
| LXD | LXD API and service state |
| DNS | Route 53 and external `dig` |
| Web | nginx state and `curl` |

---

# Review Status

**Current Status:** In Review

**Next Review:** After hardening introduces explicit health gates and retries.
