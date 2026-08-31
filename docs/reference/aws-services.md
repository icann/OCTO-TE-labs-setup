# AWS Services Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This document describes the AWS services used by OCTO-TE Labs and the boundary between AWS-managed infrastructure and the internal LXD laboratory.

---

# Service Summary

| AWS service | Responsibility |
|---|---|
| CloudFormation | stack lifecycle and resource dependency management |
| EC2 | single Ubuntu laboratory host |
| VPC | public dual-stack network |
| Elastic IP | stable public IPv4 during the stack lifetime |
| Route 53 | parent delegation, glue, access records, and DS storage |
| S3 | rendered deployment content |
| IAM | permissions for EC2 and Lambda |
| Lambda | custom IPv6 lookup and DS cleanup |
| Systems Manager Parameter Store | current Ubuntu Noble AMI ID |
| EBS | encrypted EC2 root volume |
| CloudWatch Logs | Lambda logging through standard execution permissions |

---

# CloudFormation

CloudFormation owns the AWS infrastructure lifecycle.

It creates:

- networking;
- EC2;
- storage mappings;
- IAM;
- Lambda custom resources;
- Route 53 record sets.

It does not know when the internal LXD deployment is ready.

```text
CloudFormation status
    -> AWS resource state

cloud-init status
    -> internal deployment state
```

CloudFormation deletion is the normal lab teardown path.

---

# EC2

One EC2 instance hosts:

- LXD;
- all containers;
- nginx;
- WebSSH;
- certificate tooling;
- NAT and routing;
- cron;
- deployment scripts.

This is a stateful single-host architecture.

Replacing the EC2 instance effectively rebuilds the laboratory. Therefore update change sets require careful review.

---

# VPC and Internet Gateway

The stack creates an isolated VPC and public dual-stack subnet.

The Internet gateway provides:

- operator SSH;
- DNS;
- HTTPS;
- outbound package and repository access.

The internal participant topology is not represented as AWS subnets. It exists inside the EC2 host through Linux and LXD bridges.

---

# Route 53

Route 53 has two roles.

## CloudFormation-owned records

- lab NS delegation;
- `ns1` A/AAAA glue;
- `ec2-` A/AAAA access records.

## EC2-owned dynamic record

- lab DS record.

The parent hosted zone must already exist and be DNSSEC signed.

The DS cleanup Lambda removes the externally-created DS during stack deletion.

Route 53 stores the parent DS for the lab zone. Group DS automation is separate: `cdsupdate.pl` uses authenticated `nsupdate` against the internal `ns1` platform zone and does not write group DS records to Route 53.

---

# S3

The repository publication workflow renders placeholders and publishes branch content to S3.

During UserData, the EC2 role runs a recursive S3 copy into `/root`.

The selected template URL and `S3Bucket` parameter must refer to matching branch content.

S3 is an external deployment artifact store; the stack does not create the bucket.

---

# IAM

## EC2 permissions

The instance role permits:

- S3 reads;
- Route 53 listing and record updates;
- Route 53 change-status lookup.

## Lambda permissions

The IPv6 lookup function can describe network interfaces.

The DNS cleanup function can:

- locate hosted zones;
- list record sets;
- delete the DS;
- log execution.

IAM role naming must avoid collisions across concurrent stacks.

---

# Lambda Custom Resources

## IPv6 lookup

CloudFormation cannot use the required public IPv6 value directly in the existing record flow, so the custom resource queries the EC2 network interface.

## DS cleanup

The DS is created after the platform zone is signed, inside the EC2 deployment. The cleanup function bridges that lifecycle gap during `DeleteStack`.

Custom resources must always send a success or failure response to CloudFormation. A timeout can otherwise block stack operations.

---

# Systems Manager Parameter Store

`LatestUbuntu` references:

```text
/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id
```

New stacks therefore use the current Canonical Noble AMI.

For an existing stack update, a newer resolved AMI can mark the EC2 instance for replacement.

`AmiOverride` allows an operator to pass the existing instance AMI explicitly. The change set must still be inspected for other replacements.

---

# EBS

The EC2 root block device is:

```text
512 GiB
gp3
encrypted
delete on termination
```

The host creates a 250 GB file-backed ZFS pool for LXD inside this volume.

Swap, logs, package caches, web content, and deployment files consume the remaining host filesystem.

---

# CloudWatch Logs

Lambda roles include permissions to create log groups and streams and write events.

The template does not define explicit log-group retention. Default Lambda log-group lifecycle and retention therefore apply unless managed externally.

Adding retention and deletion policy is a possible hardening improvement.

---

# GitHub Actions Boundary

GitHub Actions is not an AWS service, but it is part of the AWS deployment supply chain.

It:

- renders placeholders;
- selects the branch bucket;
- uploads the repository content.

Legacy substitutions should be removed or justified so the publication workflow matches the current template inputs.

---

# Failure Boundaries

| Failure | Primary service |
|---|---|
| invalid template or parameter | CloudFormation |
| unavailable instance type | EC2 |
| route or subnet error | VPC |
| IAM collision or denial | IAM |
| missing rendered object | S3 |
| parent-zone record conflict | Route 53 |
| custom resource timeout | Lambda/CloudFormation |
| current AMI changed during update | SSM/EC2 replacement planning |
| internal package or container failure | EC2/cloud-init, not CloudFormation |

---

# Regional Considerations

- The stack region controls EC2, VPC, Lambda, and the SSM AMI lookup.
- Route 53 is global but accessed from the stack.
- Parent DNSSEC KMS requirements are external to the current template.
- EC2 instance-type availability differs by region.
- An AMI ID is region-specific.

An `AmiOverride` from another region is invalid.

---

# Operational Checks

```bash
aws cloudformation describe-stacks
aws cloudformation describe-stack-resources
aws ec2 describe-instances
aws ec2 describe-security-groups
aws route53 list-hosted-zones-by-name
aws route53 list-resource-record-sets
aws s3 ls s3://<BUCKET>/
aws ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id
```

---

# Review Status

**Current Status:** In Review

**Next Review:** After CloudWatch retention, IAM hardening, and update-lifecycle testing.
