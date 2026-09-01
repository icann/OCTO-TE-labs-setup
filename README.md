[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

# OCTO-TE Labs

OCTO-TE Labs is the laboratory deployment platform used by the ICANN Office of the CTO (OCTO) Technical Engagement team for hands-on DNS, DNSSEC, routing, Anycast, and RPKI training.

The platform uses AWS CloudFormation to provision a dual-stack EC2 host and supporting AWS resources. The EC2 host then runs the platform services and one isolated LXD environment per participant group.

The engineering handbook is available under [`docs/`](docs/README.md). Participant-facing exercises are maintained separately in the [OCTO-TE-labs](https://github.com/icann/OCTO-TE-labs) repository.

> [!IMPORTANT]
> A CloudFormation stack reaching `CREATE_COMPLETE` means that AWS resource creation completed. It does not mean that the installation inside the EC2 instance completed. Always verify `cloud-init` before using the lab.

## Current verification scope

The current DNS baseline has been validated with:

- Lab Type 1 (resolver practice);
- Lab Type 2 (full DNS practice);
- IPv4 and IPv6 public DNS;
- DNSSEC delegation and validation;
- HTTPS and WebSSH;
- internal wipe and redeploy;
- CloudFormation deletion and DNS cleanup;
- DNS labels containing hyphens;
- optional integrated instructions in both enabled and disabled modes;
- grouped CloudFormation parameters and a verified Quick Create path;
- deployments from 3 groups through a 60-group resolver scalability test.

Routing profiles remain under restoration and require validation before production use. See [`docs/reference/lab-types.md`](docs/reference/lab-types.md).

## Architecture at a glance

```text
AWS CloudFormation
    |
    +-- VPC, subnet, routes, security group, EIP, EC2
    +-- IAM roles and policies
    +-- Route 53 parent-zone records
    +-- Lambda custom resources
    |
    v
Ubuntu EC2 host
    |
    +-- LXD/LXC container platform
    +-- nginx, WebSSH, Certbot, cron
    +-- NAT, routing, and NAT64 support (currently deployed for every profile)
    |
    +-- Shared DNS services
    |     dnsdist        100.64.0.53
    |     ns1            100.64.0.54
    |     auth-exercise  100.64.0.55-100.64.0.57
    |     auth-rpz       100.64.0.58
    |
    +-- Per-group environments
          grpN-rtr
          grpN-cli
          grpN-resolv1 / grpN-resolv2
          grpN-soa / grpN-ns1 / grpN-ns2, when enabled
          grpN-rpki, when enabled
```

The shared authoritative roles are intentionally separated:

- `dnsdist` is the public DNS frontend;
- `ns1` is the platform authoritative server;
- `auth-exercise` serves exercise-specific authoritative data;
- `auth-rpz` distributes the Response Policy Zone.

## Lab profiles

| Lab Type | Purpose | Per-group components |
|---|---|---|
| 1 | Resolver practice | router, client, two resolver containers |
| 2 | Full DNS practice | Type 1 plus SOA/primary and two authoritative containers |
| 3 | Routing and Anycast with global RPKI | routing profile with shared validators and border router; currently under restoration |
| 4 | Routing and Anycast with group RPKI | routing profile with a validator per group and border router; currently under restoration |

The current orchestrator accepts between 3 and 64 groups. Work is planned to recover the higher scalability of the original implementation.

> [!NOTE]
> In DNS profiles, the participant DNS containers are provisioned by the platform deployment, but the exercise DNS software and configuration are installed later with `scripts/do-dns-lab.sh`. This preserves the intended training workflow.

# AWS deployment

## Prerequisites

Before creating a stack, confirm that:

- the deployment files have been published to the intended S3 bucket;
- the parent Route 53 hosted zone already exists;
- the parent zone is DNSSEC signed;
- the configured SSH public key is correct;
- the selected EC2 instance type is available in the target region;
- the account can create IAM, Lambda, Route 53, EC2, and networking resources.

## Create the stack

### Quick Create for the current `nico` branch

[Open OCTO-TE Labs Quick Create in AWS CloudFormation](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https%3A%2F%2Focto-te-labs-setup-nico.s3.us-east-1.amazonaws.com%2Flab-ec2.yaml&stackName=LAB-YYYYMMDD-LOCATION)

The link pre-fills the editable stack name as `LAB-YYYYMMDD-LOCATION`. Replace the date and location before submission; for example:

```text
LAB-20260901-USA
```

> [!IMPORTANT]
> Confirm the active AWS region shown in the upper-right corner of the CloudFormation console before submitting. The stack is created in that active region. The current `nico` template artifact is stored in an S3 bucket in `us-east-1`; the template bucket region and the stack deployment region are independent.

The Quick Create link targets the rendered `nico` branch template. For another branch or fork, use that deployment's S3 template URL. All pre-filled values remain editable. CloudFormation does not accept Quick Create URL values for `NoEcho` parameters such as `labSinglePassword`.

### Manual creation

1. Open AWS CloudFormation in the intended region.
2. Choose **Create stack** -> **With new resources (standard)**.
3. Use the S3 URL for `lab-ec2.yaml` from the bucket associated with the required branch.
4. Enter a stack name using the recommended format `LAB-YYYYMMDD-LOCATION`, for example `LAB-20260901-USA`.
5. Review the parameters below.
6. Acknowledge IAM resource creation.
7. Create the stack.

The manual path does not pre-fill the stack name; the naming recommendation above must be entered by the operator.

## Parameters

The table follows the same groups and order shown by the CloudFormation console. The logical parameter IDs remain unchanged for CLI and API use.

| Console group | Parameter | Normal use |
|---|---|---|
| Lab Identity | `DnsName` | Lab DNS label. Use 3-32 lowercase letters, numbers, or hyphens. It must start and end with a letter or number. |
| Lab Identity | `DnsParent` | Existing Route 53 parent zone, including the trailing dot, for example `te-labs.training.` |
| Lab Identity | `Owner` | Name of the person responsible for the deployment. |
| Lab Configuration | `LabType` | `1` resolver, `2` full DNS, `3` routing/global RPKI, `4` routing/group RPKI. |
| Lab Configuration | `Participants` | Number of participant groups. The current orchestrator supports 3-64. |
| Lab Configuration | `labInstanceType` | EC2 type for the host. The current template default is `r4.2xlarge`; availability varies by region. |
| Lab Instructions | `IntegratedInstructions` | `YES` by default. Publishes the integrated per-group instructions and link. Set to `NO` to omit the link and skip the instruction build pipeline. |
| Lab Instructions | `labInstructions` | ZIP URL used as the source only when `IntegratedInstructions=YES`. It must be non-empty in that mode and is ignored when integrated instructions are disabled. |
| Access | `labSinglePassword` | Optional password for the shared `labuser` account. If empty, a random password is generated. Group passwords remain independently generated. |
| Advanced Deployment | `AmiOverride` | Leave empty for normal deployments. Use only to pin an existing stack to its current AMI during a deliberate CloudFormation update. |
| Advanced Deployment | `LatestUbuntu` | Leave unchanged for normal deployments. It resolves the current Ubuntu 24.04 Noble stable AMI. |
| Advanced Deployment | `S3Bucket` | Bucket containing the rendered deployment files. Normally leave the branch default. |

## Integrated instructions behavior

`IntegratedInstructions` controls the complete platform-managed instruction capability, not only the visibility of one link.

| Value | Result |
|---|---|
| `YES` | Requires a non-empty `labInstructions` URL, downloads and parameterizes the archive for each group, builds the Jekyll site, publishes `/grpN/instructions`, and shows **Lab instructions** on each group page. |
| `NO` | Ignores the source URL, omits the link, does not call the Jekyll build pipeline, and removes `/var/www/<DOMAIN>/html/grpN/instructions` for every selected group. |

For compatibility with older manually maintained `deploy-parameters.cfg` files, an absent `IntegratedInstructions` value defaults to `YES`. Both modes were validated with three-group Lab Type 1 deployments and clean `cloud-init` completion.

> [!CAUTION]
> In the current `--deploy` action, `wipe` runs before `deploy()` checks whether an enabled instruction source is empty. Before an internal redeploy with `IntegratedInstructions=YES`, confirm that `INSTRUCTIONS` contains a valid non-empty URL. Moving this validation ahead of destructive cleanup is tracked as lifecycle hardening.

> [!NOTE]
> The `/var/www/<DOMAIN>/html/grpN/instructions` path is reserved for the integrated instruction pipeline. Selecting `NO` removes that path unconditionally; alternative or custom training material must be stored or linked elsewhere if it must survive a redeploy.

## Wait for the internal deployment

CloudFormation normally completes before the software deployment inside the instance. The CloudFormation-managed hostname is available as:

```text
ec2-<DnsName>.<DnsParent>
```

For example:

```text
ec2-dns-test.te-labs.training
```

Use SSH on TCP/8484:

```bash
ssh ubuntu@ec2-<DnsName>.<DnsParent-without-final-dot>
```

Then verify:

```bash
sudo -i
cloud-init status --wait
cloud-init status --long
```

A successful deployment must show:

```text
status: done
errors: []
```

The detailed log is:

```bash
tail -f /var/log/cloud-init-output.log
```

The final orchestration marker is:

```text
===================== DEPLOY DONE =======================
```

If `cloud-init` reports `error`, treat the lab as incomplete even when CloudFormation reports `CREATE_COMPLETE`.

# Lab access

## SSH

A convenient client configuration is:

```sshconfig
Host ec2-*.te-labs.training
    User ubuntu
    IdentityFile ~/.ssh/id_te-lab.pem
    IdentitiesOnly yes
    Port 8484
```

Connect with:

```bash
ssh ubuntu@ec2-<DnsName>.<DnsParent-without-final-dot>
```

If a stack is deleted and recreated with the same DNS name, the SSH host key changes. Remove only the previous entry before reconnecting:

```bash
ssh-keygen -R '[ec2-<DnsName>.<DnsParent-without-final-dot>]:8484'
```

## Web interfaces

After the internal deployment completes:

```text
https://<DnsName>.<DnsParent>
https://webssh.<DnsName>.<DnsParent>
```

The generated credentials are stored on the host in:

```text
/home/ubuntu/grouppasswords.txt
```

The file contains:

- the shared `labuser` credential;
- one independent credential for each `grpN` account.

# Operational lifecycle

## Stop and start the EC2 instance

For a lab prepared in advance, the EC2 instance can be stopped to reduce costs and started again before the event. Allow time for the host, LXD containers, DNS, nginx, and WebSSH to become available after restart.

## Redeploy inside the existing EC2 host

The environment can be wiped and rebuilt without replacing the EC2 instance:

```bash
sudo -i
cd /root/scripts
./setup-lab.sh --deploy --type 2 --networks 3
```

`--deploy` is destructive inside the host: it performs a wipe before rebuilding the selected profile.

Command-line `--type` and `--networks` values apply only to that invocation; they do not rewrite `scripts/deploy-parameters.cfg`. For a persistent profile or group-count change, edit that file before redeploying, or repeat the same overrides on later lifecycle commands. `do-dns-lab.sh` also reads that file, so stale values can affect exercise activation.

Available lifecycle actions are:

```text
--deploy      wipe and recreate the environment
--wipe        stop and delete the deployed environment
--stop_all    stop deployed instances and services
--start_all   start deployed instances and services
```

## CloudFormation updates and AMI pinning

Labs are normally ephemeral and should be created and deleted rather than updated in place. When an existing stack must be updated, create a change set and inspect replacements before execution.

`LatestUbuntu` points to Canonical's current Ubuntu 24.04 AMI. If that AMI changed after the stack was created, an update can otherwise replace the EC2 instance. To preserve the existing host, obtain its current AMI and pass it through `AmiOverride`.

```bash
AWS_REGION="<STACK_REGION>"
STACK_NAME="<STACK_NAME>"

INSTANCE_ID=$(aws cloudformation describe-stack-resources \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --logical-resource-id labInstance \
    --query 'StackResources[0].PhysicalResourceId' \
    --output text)

AMI_ID=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].ImageId' \
    --output text)

echo "$AMI_ID"
```

Pass this value when creating the update change set:

```text
ParameterKey=AmiOverride,ParameterValue=<CURRENT_AMI_ID>
```

AMI pinning prevents replacement caused by an AMI change only. Other template changes may still require replacement, so the change set remains mandatory.

The template path and parameter syntax have been validated. Before relying on `AmiOverride` for a live lab, verify the proposed update with a nonexecuted change set against a disposable existing stack.

## Delete the lab

Delete the CloudFormation stack from the console or CLI:

```bash
AWS_REGION="<STACK_REGION>"
STACK_NAME="<STACK_NAME>"

aws cloudformation delete-stack \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME"

aws cloudformation wait stack-delete-complete \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME"
```

Manual deletion of the lab's Route 53 records is not part of the normal procedure. CloudFormation owns the NS, glue, and `ec2-` records. A custom cleanup resource removes the DS record created by the internal DNSSEC deployment. The cleanup is designed to succeed when the DS does not exist. It has been validated with a successful deployment where a DS was present, with an internal deployment that failed before DS publication, and with deletion initiated from both the CLI and the AWS console.

Public and local recursive resolvers can retain positive or negative answers briefly according to DNS caching rules. Immediate deletion and recreation with the same `DnsName` is supported, but a local resolver can temporarily show asymmetric A/AAAA results while its cache converges. In the verified `testing` reuse cycle, the authoritative path and major public resolvers returned the new A and AAAA records while the workstation resolver briefly lacked the A record. Route 53 and authoritative responses remain the primary cleanup and publication checks.

# Basic validation

On the host:

```bash
cloud-init status --long
lxc query /1.0/instances | jq 'length'
lxc query '/1.0/instances?recursion=1' | jq -r 'group_by(.status)[] | "\(.[0].status): \(length)"'
```

From an external system:

```bash
dig <DOMAIN> NS
dig <DOMAIN> DS
dig @1.1.1.1 +dnssec +adflag <DOMAIN> SOA
dig @8.8.8.8 +dnssec +adflag <DOMAIN> SOA
curl -I https://<DOMAIN>
curl -I https://webssh.<DOMAIN>
```

# Addressing summary

The lab uses RFC 6598 shared address space internally.

| Purpose | IPv4 |
|---|---|
| Backbone bridge | `100.64.0.0/22` |
| Public DNS frontend | `100.64.0.53` |
| Platform authoritative DNS | `100.64.0.54` |
| Exercise authoritative targets | `100.64.0.55-100.64.0.57` |
| RPZ authoritative service | `100.64.0.58` |
| Group aggregate | `100.100.<group>.0/24` |
| Group LAN | `100.100.<group>.0/26` |
| Group internal servers | `100.100.<group>.64/26` |
| Group DMZ | `100.100.<group>.128/26` |
| Group extra network | `100.100.<group>.192/26` |

The current internal IPv6 plan uses the fixed ULA prefix `fd89:59e0`. Restoration of a dynamic RFC 4193 prefix remains a future scalability task.

# Repository publication and forks

The repository workflow renders placeholders in `lab-ec2.yaml` and configuration files, then publishes the branch contents to S3. A fork must provide the required GitHub Actions secrets and variables, including:

- AWS credentials for publication;
- destination bucket;
- SSH public key;
- parent DNS zone;
- participant instructions URL;
- VPN values used by routing profiles.

The parent Route 53 zone must already be DNSSEC signed. Its KMS key and parent-zone signing configuration are external prerequisites; the current lab template does not create or configure them.

# Running outside AWS

The host and LXD scripts can be adapted for another Ubuntu environment, but the current implementation assumes AWS integrations for:

- Route 53 parent-zone records and DNSSEC DS publication;
- S3 distribution of deployment files;
- EC2 public IPv4 and IPv6 discovery;
- CloudFormation lifecycle management.

At minimum, copy `configs/deploy-parameters.cfg` to `scripts/deploy-parameters.cfg`, provide valid values, and replace the AWS-specific DNS publication flow before running:

```bash
cd scripts
./setup-host.sh
./setup-containers.sh
./setup-lab.sh --deploy
```

# Engineering documentation

The Architecture & Engineering Handbook is under [`docs/`](docs/README.md). It separates:

- current architecture;
- implementation reference;
- engineering decisions;
- future design;
- development history;
- technical debt and backlog.

# License

Copyright © 2025 Internet Corporation for Assigned Names and Numbers (ICANN) and Network Startup Resource Center (NSRC). All rights reserved.

This repository is licensed under the 3-Clause BSD License. See [`LICENSE.md`](LICENSE.md).
