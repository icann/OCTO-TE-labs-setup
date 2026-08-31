# Deployment Flow

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document describes the verified lifecycle of an OCTO-TE Labs deployment, from repository publication and CloudFormation provisioning through the internal EC2 deployment, participant access, redeployment, and stack deletion.

The most important operational distinction is:

```text
CloudFormation CREATE_COMPLETE
    !=
OCTO-TE lab deployment complete
```

CloudFormation creates AWS resources. `cloud-init` then performs a separate, longer-running deployment inside the EC2 instance.

---

# End-to-End Flow

```text
Repository branch
    |
    v
GitHub Actions renders deployment placeholders
    |
    v
Branch content is published to S3
    |
    v
CloudFormation creates AWS resources
    |
    v
EC2 UserData starts cloud-init
    |
    +-- setup-host.sh
    +-- setup-containers.sh
    +-- setup-lab.sh --deploy
    |
    v
Shared platform services and per-group topology are created
    |
    v
nginx, WebSSH, certificates, instructions, cron, and DS are published
    |
    v
cloud-init status: done
    |
    v
Lab is ready for validation and participant use
```

---

# Phase 1 - Repository Publication

The repository contains source templates with placeholders such as:

```text
%S3BUCKET%
%DNS_PARENT_DEFAULT%
%SSH_PUBLIC_KEY%
%LAB_INSTRUCTIONS_URL%
%VPNpeerName%
%VPNlistenPort%
%VPNprivateKey%
%VPNlocalIPv4%
%VPNpublicKey%
%VPNallowedPrefixIPv4%
%VPNendPointIPv4%
```

The publication workflow renders these values and uploads the branch contents to the associated S3 bucket. The rendered S3 copy, not the source template with unresolved placeholders, is the normal CloudFormation entry point.

A deployment therefore depends on alignment among:

- the Git branch;
- the rendered S3 content;
- GitHub Actions variables and secrets;
- the CloudFormation template URL selected by the operator.

---

# Phase 2 - CloudFormation Input

The principal operator-controlled inputs are:

- parent Route 53 zone;
- lab DNS label;
- owner;
- number of groups;
- Lab Type;
- EC2 instance type;
- participant instructions URL;
- optional shared `labuser` password;
- optional AMI override for an existing-stack update.

`DnsName` is a single DNS label. The current validation permits 3-32 lowercase letters, numbers, and hyphens, with an alphanumeric first and last character.

The current shell orchestrator supports 3-64 groups even though higher route capacity is prepared in the host network template.

---

# Phase 3 - AWS Resource Provisioning

CloudFormation creates the AWS execution environment, including:

- an EC2 key pair based on the configured public key;
- a VPC and Amazon-provided IPv6 CIDR;
- a dual-stack subnet;
- Internet gateway and IPv4/IPv6 default routes;
- a security group;
- an Elastic IP and association;
- IAM role, policies, and instance profile;
- the EC2 instance and encrypted gp3 root volume;
- a Lambda custom resource that retrieves the EC2 IPv6 address;
- Route 53 NS, glue A/AAAA, and `ec2-` A/AAAA records;
- a Lambda custom resource used to remove the externally-created DS record during stack deletion.

The `ec2-<DnsName>.<DnsParent>` A and AAAA records are CloudFormation-managed and provide the most reliable early SSH target while the internal lab DNS zone is still being created.

---

# Phase 4 - EC2 Bootstrap and UserData

The EC2 UserData script:

1. moves SSH to TCP/8484;
2. updates the Ubuntu host;
3. installs the AWS CLI;
4. copies deployment files from S3 to `/root`;
5. derives the normalized lab domain;
6. discovers the public IPv4 and IPv6 addresses;
7. renders `scripts/deploy-parameters.cfg`;
8. handles the optional shared password without command tracing;
9. runs:

```bash
./setup-host.sh
./setup-containers.sh
./setup-lab.sh --deploy
```

UserData runs under `cloud-init`. Any failure in these scripts makes the internal deployment incomplete, even when CloudFormation itself already reached `CREATE_COMPLETE`.

---

# Phase 5 - Host Preparation

`setup-host.sh` prepares the EC2 host by:

- updating the operating system;
- installing host tools and dependencies;
- applying the project sysctl profile;
- creating swap when required;
- replacing the host network configuration;
- creating the `net-bb` backbone bridge;
- installing and configuring LXD;
- enabling outbound NAT for internal lab networks;
- configuring temporary DHCP support used during container preparation;
- installing nginx, WebSSH, Certbot, PHP, and documentation tooling;
- setting the host name to the lab domain.

The host netplan currently contains prepared IPv4 and IPv6 routes for a larger design capacity than the 64-group orchestrator limit. Per-group LXD networks are created later only for the selected group count.

---

# Phase 6 - Base Container Preparation

`setup-containers.sh` creates reusable stopped templates, including:

- `hostX` for general-purpose Ubuntu containers;
- `rtrX` for FRRouting-based routers;
- `fortX` for RPKI validator work.

Group containers are copied from these templates. The LXD default profile currently applies a 2 GB memory ceiling to normal containers. A ceiling is not a reservation: containers consume memory according to workload, up to the configured limit.

---

# Phase 7 - Laboratory Orchestration

`setup-lab.sh --deploy` first wipes a previous internal environment, then recreates it.

The verified high-level order is:

1. generate passwords;
2. create four LXD networks per selected group;
3. create one router per group;
4. create shared DNS backends:
   - `ns1`;
   - `auth-exercise`;
   - `auth-rpz`;
5. create the host NAT64 service;
6. create `dnsdist` after its shared authoritative backends;
7. create optional border-router and RPKI components;
8. create selected participant containers;
9. start routers and push network configuration;
10. start and configure participant containers;
11. obtain or reuse the HTTPS certificate;
12. generate nginx and WebSSH configuration;
13. publish the participant web content and instructions;
14. configure cron jobs;
15. publish the lab DS to the parent Route 53 zone;
16. report `DEPLOY DONE`.

The exact profile mapping is documented in [`../reference/lab-types.md`](../reference/lab-types.md).

---

# Phase 8 - DNS and Web Publication

The shared DNS sequence is deliberately ordered:

```text
ns1 / auth-exercise / auth-rpz
              |
              v
dnsdist frontend
              |
              v
Let's Encrypt validation
              |
              v
nginx and WebSSH
              |
              v
DS publication
```

The platform authoritative zone provides the apex, `ns1`, and `webssh` records. `dnsdist` exposes DNS on the public host addresses through DNAT to the container at `100.64.0.53` and the corresponding ULA address.

The generated certificate covers both:

```text
<DOMAIN>
webssh.<DOMAIN>
```

The DS is generated only after the platform zone is signed. It is created by the EC2-side deployment through the Route 53 API, so it requires separate stack-delete cleanup.

---

# Phase 9 - Completion and Validation

The operator should connect through:

```text
ec2-<DnsName>.<DnsParent>
```

and run:

```bash
sudo -i
cloud-init status --wait
cloud-init status --long
```

Successful completion requires:

```text
status: done
errors: []
```

The final log marker is:

```text
===================== DEPLOY DONE =======================
```

Recommended external validation includes:

- parent NS and glue;
- apex A and AAAA;
- DS presence;
- DNSSEC validation with the AD flag;
- HTTPS response from the main site;
- HTTPS response from WebSSH.

---

# Participant Exercise Activation

The base platform deployment creates participant containers and topology. It does not necessarily activate the DNS exercise services inside those containers.

For DNS workshops, the instructor later runs:

```bash
cd /root/scripts
./do-dns-lab.sh <group-or-all>
```

This installs and configures the participant-facing BIND, Unbound, and NSD services required by the exercise. The distinction is intentional: provisioning the environment and performing the participant exercise are separate lifecycle stages.

---

# Internal Redeployment

The EC2 host can be reused for another internal profile without a CloudFormation update:

```bash
cd /root/scripts
./setup-lab.sh --deploy --type 2 --networks 3
```

`--deploy` means:

```text
wipe current internal environment
    -> deploy selected internal environment
```

It preserves the EC2 and CloudFormation resources but deletes and recreates LXD networks, containers, shared DNS services, web content, credentials, and related internal state.

The internal redeploy can generate a new DNSSEC key and updates the parent DS accordingly.

Command-line profile and group-count overrides are process-local. They do not update `deploy-parameters.cfg`; edit that file for a persistent change or repeat the same overrides on subsequent lifecycle commands.

---

# Stack Update Lifecycle

The normal lifecycle is create, operate, and delete. In-place CloudFormation updates of active labs are exceptional.

`LatestUbuntu` resolves Canonical's current Ubuntu 24.04 Noble stable AMI. When that target changes, an unrelated stack update can otherwise mark the EC2 instance for replacement.

For a deliberate update that must preserve the host:

1. retrieve the EC2 instance's current AMI;
2. pass that AMI through `AmiOverride`;
3. create a change set;
4. confirm that the EC2 instance is not being replaced;
5. execute only after reviewing all other resource changes.

AMI pinning does not prevent replacements caused by other properties.

The template and parameter path have been validated. A live update change set using `AmiOverride` remains pending because no suitable existing test stack was available when the mechanism was added.

---

# Stack Deletion Lifecycle

Normal deletion is initiated through CloudFormation, from either the console or CLI.

CloudFormation deletes its managed Route 53 records:

- delegated NS;
- `ns1` A and AAAA glue;
- `ec2-` A and AAAA records.

The lab DS is different: it was created by the internal EC2 deployment. The `labDnsCleanup` custom resource handles its deletion.

The cleanup behavior is idempotent:

- if the DS exists, it is deleted;
- if it does not exist, deletion still succeeds;
- if the parent hosted zone cannot be found, the cleanup returns success because there is no target to clean in that account context;
- a real AWS API error is reported to CloudFormation rather than silently ignored.

This lifecycle has been validated for:

- successful deployments;
- a deployment whose `cloud-init` failed before DS publication;
- deletion from the AWS console;
- deletion from the AWS CLI;
- recreation with the same `DnsName` immediately after deletion;
- a `DnsName` containing a hyphen.

---

# Failure Boundaries

| Boundary | Typical symptom | Primary evidence |
|---|---|---|
| CloudFormation validation | stack is not created | CloudFormation error message |
| AWS resource creation | stack rollback or failed resource | CloudFormation events |
| UserData/cloud-init | CloudFormation complete but lab incomplete | `cloud-init status --long` and `/var/log/cloud-init-output.log` |
| External package repository | installation exits with HTTP or APT errors | cloud-init log |
| Container service | container exists but service is inactive | `lxc exec`, `systemctl`, and service logs |
| DNS publication | DS, delegation, or validation failure | Route 53 records and external `dig` tests |
| Web publication | HTTPS or WebSSH failure | nginx test, service state, and `curl` |

A recent example was a transient FRRouting repository index that advertised packages no longer available at the referenced URLs. The platform code had not changed, but a new deployment failed during `rtrX` preparation. External dependency reproducibility remains a hardening task.

---

# Verified Invariants

- `CREATE_COMPLETE` alone is not the readiness signal.
- `ec2-<DOMAIN>` is the early CloudFormation-managed access name.
- shared authoritative DNS must exist before `dnsdist` is finalized;
- the DS is created outside CloudFormation and deleted by a custom resource;
- `--deploy` is destructive inside the EC2 host;
- participant DNS exercise services are activated separately;
- delete and recreate with the same DNS label is supported.

---

# Review Status

**Current Status:** In Review

**Next Review:** After deployment hardening and the next full lifecycle regression test.
