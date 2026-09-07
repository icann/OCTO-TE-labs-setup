# ADR-0004 - Deployment Reporting and Software Freshness

**Status:** In Review

**Date:** 2026-09-07

---

# Context

OCTO-TE Labs currently executes the internal deployment as three consecutive scripts from EC2 UserData:

```text
setup-host.sh
setup-containers.sh
setup-lab.sh --deploy
```

CloudFormation can reach `CREATE_COMPLETE` before the internal deployment finishes. Operators must inspect `cloud-init`, deployment logs, container state, DNS, and service health to determine whether a LAB is actually usable.

The current scripts also contain legacy cleanup paths that can print warnings while the final deployment remains functional. A plain search for the word `ERROR` is therefore not a reliable deployment result. Conversely, some legacy functions can fail to propagate a nonzero status unless they validate and return errors explicitly.

The platform is also beginning to depend on externally released security components. Authelia and OAuth2 Proxy should be deployed from exact validated artifacts, while Redis, SQLite, and other operating-system packages should remain within the supported Ubuntu release. Operators need to know when the installed software matches the validated baseline and when a newer stable release is available.

The LAB must remain reproducible. A newly published upstream release must not silently alter an active or future deployment that uses the same OCTO-TE Labs commit.

---

# Decision

## Top-level deployment wrapper

The platform will introduce a top-level deployment wrapper named:

```text
scripts/deploy-platform.sh
```

EC2 UserData will eventually invoke this wrapper instead of calling the three setup scripts directly.

The wrapper will:

1. initialize report state before the first deployment stage;
2. execute `setup-host.sh`;
3. execute `setup-containers.sh`;
4. execute `setup-lab.sh --deploy`;
5. execute explicit final health validation;
6. execute bounded, non-mutating software and image freshness checks;
7. always attempt to generate the deployment report;
8. preserve and return the original fatal deployment status.

A report-generation failure must never replace an earlier deployment failure. If all deployment stages succeed but the required local report cannot be generated, the wrapper must return a nonzero status.

## Deployment result model

The human-readable deployment result has exactly three states:

```text
PASS
PASS_WITH_WARNINGS
FAIL
```

The result is determined primarily by:

- the exit status of each deployment stage;
- explicit final health checks;
- installed-versus-pinned integrity checks;
- classified warnings.

A simple log-text search is supplemental evidence and is not the source of truth.

### PASS

All required stages and health checks succeed, installed versions match the validated baseline, and no classified warning remains.

### PASS_WITH_WARNINGS

All required stages and health checks succeed, but one or more nonfatal conditions exist, such as:

- a known cleanup warning;
- a newer stable software version being available;
- a freshness source being temporarily unavailable;
- a non-blocking image-comparison result that cannot yet be determined reliably.

### FAIL

At least one required stage or final health check fails, a required installed version does not match its pin, a required checksum does not match, or the mandatory local report cannot be generated after an otherwise successful deployment.

## Report outputs

The latest deployment writes two canonical files:

```text
/var/log/octo-te/deployment-summary.txt
/var/log/octo-te/deployment-report.json
```

The text file is intentionally short and suitable for displaying at the end of `cloud-init`. The JSON file preserves structured detail for troubleshooting and future automation.

The platform will provide:

```text
lab-report
lab-version-check
```

`lab-report` displays the latest human-readable summary. `lab-version-check` repeats only the non-mutating integrity and freshness checks and never installs or upgrades software.

## Concise summary contract

A successful summary should remain comparable to:

```text
================ OCTO-TE DEPLOY SUMMARY ================
Result:       PASS_WITH_WARNINGS
Domain:       example.te-labs.training
Profile:      Type 1 | Groups 3 | Instructions NO
Duration:     14m 31s

Health:       containers OK | identity OK | nginx OK | DNS OK
Errors:       0 fatal
Warnings:     1

Software freshness:
  Authelia       4.39.22 -> 4.39.23   UPDATE_AVAILABLE
  OAuth2 Proxy   7.15.4  -> 7.15.4    CURRENT
  Redis          7.0.15  -> 7.0.15    CURRENT
  SQLite         3.45.1  -> 3.45.1    CURRENT

Recommendation:
  Test available updates in a dedicated disposable VM before updating the pinned versions.

Details:
  /var/log/octo-te/deployment-report.json
========================================================
```

The version numbers shown above are illustrative. The report must use the values actually pinned, installed, and discovered at runtime.

A failure summary should identify the failed stage and exit status without exposing the full command line or secret-bearing environment variables.

## Software and image status model

Each checked component uses one of these states:

```text
CURRENT
UPDATE_AVAILABLE
INSTALLED_MISMATCH
CHECK_UNAVAILABLE
NOT_APPLICABLE
```

- `CURRENT`: the installed or active version matches the validated pin or current supported source.
- `UPDATE_AVAILABLE`: the deployment is valid, but a newer stable version is available.
- `INSTALLED_MISMATCH`: the active version differs from the required validated pin; this is fatal.
- `CHECK_UNAVAILABLE`: the freshness source could not be queried within a bounded timeout; this is nonfatal.
- `NOT_APPLICABLE`: the comparison does not apply, for example when an intentional AMI override is active.

The generic update recommendation is:

```text
Test available updates in a dedicated disposable VM before updating the pinned versions.
```

The recommendation must not name a particular development branch. It applies equally to maintainers, forks, and future deployment environments.

## External identity binaries

Authelia and OAuth2 Proxy will use:

- an exact version;
- an exact release artifact name;
- an exact SHA-256 checksum;
- a recorded installed version.

Deployment integrity requires:

```text
installed version == pinned version
artifact checksum == pinned checksum
```

A newer stable release is advisory and does not change the deployment result from valid to failed.

The platform never resolves `latest` at installation time and never upgrades these components automatically during deployment.

## Ubuntu packages

Redis, SQLite, and similar operating-system dependencies are installed from the configured Ubuntu release repositories.

The report compares:

```text
installed package version
candidate package version
```

A newer candidate is reported as `UPDATE_AVAILABLE`; it is not installed automatically. Package-family or compatibility constraints may be added where a major-version boundary would be unsafe.

## EC2 AMI and LXD image

The report will include, when reliably discoverable:

- the EC2 AMI used by the current instance;
- the current AMI resolved by the configured Canonical SSM parameter;
- whether an explicit `AmiOverride` is active;
- the local LXD Ubuntu image alias, fingerprint, release, and serial;
- the current stable remote image metadata used for comparison.

AMI and LXD freshness checks are advisory. If a deterministic comparison is unavailable, the report uses `CHECK_UNAVAILABLE` rather than guessing.

## Network and provider failures

Freshness lookups use bounded timeouts and must not delay a deployment indefinitely.

A failure to query GitHub, Ubuntu package metadata, AWS SSM, or image metadata is recorded as `CHECK_UNAVAILABLE` and produces at most `PASS_WITH_WARNINGS`. It must not become `FAIL` when all locally required stages, versions, checksums, and health checks succeed.

## Warning classification

Warnings are classified explicitly. Known lifecycle warnings such as current TAYGA/NAT64 or repeated iptables cleanup messages may be reported without becoming fatal only while final health checks prove that the deployed environment is correct.

Unknown or newly introduced warnings are not silently added to the accepted list. Their classification requires an explicit code or documentation change.

The long-term objective remains to make the underlying functions idempotent and to propagate errors correctly; reporting does not replace fixing defects.

## Security and privacy

The summary and JSON report must never include:

- plaintext passwords;
- password hashes;
- SSH private keys;
- VPN private keys;
- OIDC client secrets;
- session or cookie secrets;
- Redis credentials;
- complete secret-bearing environment dumps;
- full commands that may contain secret values.

Failure records are limited to safe fields such as:

```text
stage
health check
exit status
timestamp
safe classification
```

Files are created with root-controlled permissions. The exact permission model is an implementation detail that must be validated before deployment reporting is enabled.

## No automatic upgrades

The reporting system is observational and advisory. It must never:

- alter version pins;
- install a newer release automatically;
- execute an unattended major-version upgrade;
- modify the deployment because a freshness source reports an update.

A maintainer deliberately updates pins only after testing the available release in a dedicated disposable VM and reviewing the resulting deployment, browser, lifecycle, and security behavior.

---

# Scope and Boundaries

This ADR decides:

- that reporting covers the complete internal deployment rather than only `setup-lab.sh`;
- the result and version-status models;
- the canonical text and JSON report paths;
- the `lab-report` and `lab-version-check` operator interfaces;
- that report generation occurs on success and failure;
- that the original fatal status is preserved;
- that exact pins and checksums are blocking integrity controls;
- that newer stable versions are advisory;
- that freshness-source failure is nonfatal;
- that updates are tested in a dedicated disposable VM before pins change;
- that reports never contain secrets;
- that automatic upgrades are prohibited.

This ADR does not yet decide:

- the final JSON schema version;
- the exact bounded timeout values;
- every final health check;
- every accepted legacy-warning signature;
- the final LXD remote-image comparison algorithm;
- whether historical reports are retained in addition to the latest canonical report;
- integration with an external monitoring or log-aggregation system.

---

# Consequences

## Positive

- Every deployment ends with an explicit, concise outcome.
- Failures in early stages can still produce a useful report.
- Operators can distinguish successful CloudFormation provisioning from successful internal deployment.
- Exact external pins remain reproducible while newer stable releases remain visible.
- Freshness checks do not silently mutate the LAB.
- Structured JSON enables later automation and CI validation.
- The same report model can support fresh deployments and internal redeployments.
- The generic recommendation remains appropriate outside `nico-auth` and for forks.

## Trade-offs and Risks

- A top-level wrapper changes the EC2 bootstrap path and requires deliberate failure-path testing.
- Legacy functions that swallow errors can reduce report accuracy until their propagation is corrected.
- Warning classification can become stale if accepted signatures are not reviewed.
- Network lookups add bounded deployment time and external dependencies, even though they are nonfatal.
- Version comparison across GitHub, APT, AWS SSM, and LXD uses different source semantics.
- A report can create false confidence if final health checks are incomplete.
- Secret redaction must be tested continuously as new stages and variables are added.

---

# Validation

The reporting architecture must not be merged into the stable deployment path until tests demonstrate:

- report generation after complete success;
- report generation after failure in `setup-host.sh`;
- report generation after failure in `setup-containers.sh`;
- report generation after failure in `setup-lab.sh --deploy`;
- preservation of the first fatal exit status;
- `PASS`, `PASS_WITH_WARNINGS`, and `FAIL` behavior;
- fatal handling of checksum and installed-pin mismatches;
- nonfatal handling of newer stable releases;
- nonfatal handling of freshness-source timeouts and failures;
- correct behavior with `AmiOverride`;
- concise output at the end of cloud-init;
- valid JSON output;
- secure local file ownership and permissions;
- no password, private key, token, session secret, client secret, or Redis credential in either report;
- `lab-report` and `lab-version-check` behavior;
- the exact generic recommendation text;
- no automatic installation or version-pin modification.

---

# Related Documents

- [`ADR-0003-unified-lab-identity-and-access.md`](ADR-0003-unified-lab-identity-and-access.md)
- [`../architecture/02-deployment-flow.md`](../architecture/02-deployment-flow.md)
- [`../architecture/03-orchestrator.md`](../architecture/03-orchestrator.md)
- [`../reference/software-stack.md`](../reference/software-stack.md)
- [`../development/engineering-backlog.md`](../development/engineering-backlog.md)
- [`../development/engineering-log.md`](../development/engineering-log.md)
- [`../development/todo.md`](../development/todo.md)

---

# Review Criteria

Promote this ADR to Approved only after:

- the wrapper and report generator pass all success and failure tests;
- required identity-component version pins and checksums are implemented;
- freshness checks are bounded, advisory, and non-mutating;
- secret-scanning tests pass against text, JSON, and cloud-init output;
- the original deployment exit status is preserved under reporting failures;
- operators confirm the summary is brief enough for routine deployment use;
- the implementation and documentation are ready for the stable branch.
