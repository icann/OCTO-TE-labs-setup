# AWS Resources Reference

**Status:** In Review

**Last Updated:** 2026-09-01

---

# Purpose

This document lists the AWS resources created or consumed by the current CloudFormation template and identifies their lifecycle ownership.

The source of truth is:

```text
lab-ec2.yaml
```

---

# Stack Inputs

Important parameters include:

- `DnsParent`;
- `DnsName`;
- `Owner`;
- `Participants`;
- `LabType`;
- `LatestUbuntu`;
- `AmiOverride`;
- `S3Bucket`;
- `labInstanceType`;
- `IntegratedInstructions`;
- `labInstructions`;
- `labSinglePassword`.

`AmiOverride` is empty for normal deployments. `IntegratedInstructions` defaults to `YES`; `labInstructions` is required by the internal deployment only when that capability is enabled.

---

# Parameter Interface Metadata

`AWS::CloudFormation::Interface` groups all twelve parameters in the console as:

| Group | Parameters |
|---|---|
| Lab Identity | `DnsName`, `DnsParent`, `Owner` |
| Lab Configuration | `LabType`, `Participants`, `labInstanceType` |
| Lab Instructions | `IntegratedInstructions`, `labInstructions` |
| Access | `labSinglePassword` |
| Advanced Deployment | `AmiOverride`, `LatestUbuntu`, `S3Bucket` |

The metadata also provides friendly labels. It affects the CloudFormation console only; CLI and API calls continue to use the logical IDs.

The stack name is not a template parameter. The verified Quick Create URL pre-fills it as `LAB-YYYYMMDD-LOCATION`, while the manual creation path leaves it empty. The operator must always confirm the active CloudFormation region before submission.

---
# Network Resources

| Logical resource | Type | Responsibility |
|---|---|---|
| `labVPC` | `AWS::EC2::VPC` | `10.0.0.0/16` VPC |
| `labIpv6CidrBlock` | `AWS::EC2::VPCCidrBlock` | Amazon-provided VPC IPv6 |
| `labSubnet` | `AWS::EC2::Subnet` | public dual-stack subnet |
| `InternetGateway` | `AWS::EC2::InternetGateway` | Internet attachment |
| `AttachGateway` | `AWS::EC2::VPCGatewayAttachment` | attach gateway to VPC |
| `PublicRouteTable` | `AWS::EC2::RouteTable` | public routes |
| `PublicIPv4Route` | `AWS::EC2::Route` | `0.0.0.0/0` |
| `PublicIPv6Route` | `AWS::EC2::Route` | `::/0` |
| `SubnetRouteTableAssociation` | `AWS::EC2::SubnetRouteTableAssociation` | associate subnet |
| `labSecurityGroup` | `AWS::EC2::SecurityGroup` | public ingress boundary |

The Security Group currently permits:

```text
TCP/8484
TCP/53
UDP/53
TCP/80
TCP/443
```

for IPv4 and IPv6.

WireGuard UDP ingress is not present.

---

# Address Resources

| Logical resource | Type | Responsibility |
|---|---|---|
| `IPAddress` | `AWS::EC2::EIP` | public IPv4 |
| `IPAssoc` | `AWS::EC2::EIPAssociation` | associate EIP with EC2 |

The public IPv6 address is assigned to the instance network interface by the subnet configuration and retrieved through a custom resource.

---

# Compute and Storage

| Logical resource | Type | Responsibility |
|---|---|---|
| `labKey` | `AWS::EC2::KeyPair` | operator SSH public key |
| `labInstance` | `AWS::EC2::Instance` | Ubuntu LXD host |

Current EC2 storage:

```text
512 GiB
gp3
encrypted
delete on termination
```

AMI selection:

```text
AmiOverride, when nonempty
otherwise LatestUbuntu SSM parameter
```

Changing the resolved AMI can require EC2 replacement.

---

# EC2 IAM Resources

| Logical resource | Type |
|---|---|
| `labInstanceRole` | `AWS::IAM::Role` |
| `labInstanceS3Policy` | `AWS::IAM::Policy` |
| `labInstanceRoute53Policy` | `AWS::IAM::Policy` |
| `labInstanceProfile` | `AWS::IAM::InstanceProfile` |

The EC2 role can:

- read deployment content from the rendered S3 bucket;
- list the parent hosted zone;
- list and change Route 53 record sets;
- wait for Route 53 changes.

The EC2 role name and instance profile include the stack name, supporting concurrent stacks.

---

# IPv6 Custom Resource

| Logical resource | Type |
|---|---|
| `labLambdaGetIntstanceIpv6Role` | `AWS::IAM::Role` |
| `labLambdaGetIntstanceIpv6Function` | `AWS::Lambda::Function` |
| `labInstanceIpv6` | custom resource |

The function:

1. receives the EC2 instance ID;
2. calls `DescribeNetworkInterfaces`;
3. extracts the first IPv6 address;
4. returns it to CloudFormation.

The role deliberately has no fixed global `RoleName`, avoiding the multi-stack collision that existed previously.

The logical identifier retains the historical `Intstance` typo.

---

# DNS Cleanup Custom Resource

| Logical resource | Type |
|---|---|
| `labDnsCleanupRole` | `AWS::IAM::Role` |
| `labDnsCleanupFunction` | `AWS::Lambda::Function` |
| `labDnsCleanup` | custom resource |

On stack deletion, the function:

1. normalizes the parent and lab domain names;
2. locates the exact parent hosted zone;
3. finds the exact DS record set;
4. deletes it when present;
5. returns success when no DS or parent zone exists;
6. returns failure for real AWS API errors.

The resource exists because the EC2-side deployment creates the DS outside CloudFormation.

---

# Route 53 Record Resources

| Logical resource | Type | Record |
|---|---|---|
| `labNS` | `AWS::Route53::RecordSet` | `<DOMAIN>` NS |
| `ns1A` | `AWS::Route53::RecordSet` | `ns1.<DOMAIN>` A |
| `ns1AAAA` | `AWS::Route53::RecordSet` | `ns1.<DOMAIN>` AAAA |
| `ec2A` | `AWS::Route53::RecordSet` | `ec2-<DOMAIN>` A |
| `ec2AAAA` | `AWS::Route53::RecordSet` | `ec2-<DOMAIN>` AAAA |

These records are owned directly by CloudFormation.

The DS is not a native record resource in this stack and is owned by the EC2 deployment plus cleanup custom resource.

---

# External Resources Consumed

The stack expects these to exist:

| Resource | Ownership |
|---|---|
| Parent Route 53 hosted zone | external prerequisite |
| Parent-zone DNSSEC configuration | external prerequisite |
| KMS key used by parent Route 53 DNSSEC | external prerequisite |
| Branch S3 bucket and rendered content | repository publication workflow |
| Ubuntu SSM AMI parameter | AWS/Canonical |
| Participant instruction archive | external URL required only when `IntegratedInstructions=YES` |
| VPN peer and endpoint | external routing environment |

The template does not create the parent zone or its DNSSEC signing key.

---

# Resource Ownership Matrix

| Object | Creator | Deleter |
|---|---|---|
| VPC/subnet/routes/EC2/IAM/Lambda | CloudFormation | CloudFormation |
| NS and glue records | CloudFormation | CloudFormation |
| `ec2-` records | CloudFormation | CloudFormation |
| signed lab zone | EC2 internal deployment | EC2 disappears with stack |
| parent DS | EC2 internal deployment | cleanup custom resource |
| LXD instances and networks | internal orchestrator | internal wipe or EC2 deletion |
| S3 content | GitHub workflow | external bucket lifecycle |

---

# Update and Replacement Risks

Potential replacement-sensitive resources include:

- EC2 when `ImageId` changes;
- EIP association when the instance changes;
- dependent AAAA records when the custom IPv6 result changes;
- IAM resources when names or immutable properties change.

Use a nonexecuted change set before updating an active lab.

When preserving the host:

1. retrieve its current AMI;
2. pass it through `AmiOverride`;
3. inspect all proposed replacements.

The `AmiOverride` path is template-validated but still requires a live disposable-stack change-set test.

---

# Deletion Validation

After stack deletion:

```bash
aws cloudformation describe-stacks \
    --stack-name <STACK_NAME>
```

should report that the stack does not exist.

Route 53 should contain no matching lab records:

```bash
aws route53 list-resource-record-sets \
    --hosted-zone-id <ZONE_ID> \
    --query "ResourceRecordSets[?contains(Name, '<DOMAIN>')]"
```

The deletion lifecycle has been validated from both CLI and console.

---

# Naming and Concurrency

Resources with explicit or derived names must support concurrent labs.

A previous fixed Lambda IAM role name caused a collision between stacks. The role now uses a generated physical name.

Future additions should avoid account-global fixed names unless the resource is intentionally shared.

---

# Review Status

**Current Status:** In Review

**Next Review:** After routing ingress and live AMI-override change-set testing.
