# Reference

**Status:** In Review

**Last Updated:** 2026-08-31

---

# Purpose

This directory contains exact technical reference information for the current OCTO-TE Labs implementation.

Reference documents record names, values, ports, resources, services, and profile mappings. They do not define future architecture.

---

# Documents

| Document | Responsibility |
|---|---|
| [`acronyms.md`](acronyms.md) | Acronyms and project abbreviations |
| [`aws-resources.md`](aws-resources.md) | CloudFormation parameters and AWS resource inventory |
| [`aws-services.md`](aws-services.md) | AWS service responsibilities and lifecycle notes |
| [`container-naming.md`](container-naming.md) | LXD templates, shared containers, and per-group instance names |
| [`dns-naming.md`](dns-naming.md) | Public names, zone ownership, group names, and DNSSEC cleanup |
| [`lab-types.md`](lab-types.md) | Numeric profile mapping, components, counts, and validation status |
| [`lxd.md`](lxd.md) | LXD storage, profile, templates, limits, and inventory methods |
| [`network-addressing.md`](network-addressing.md) | IPv4, IPv6, NAT64, backbone, and group addressing |
| [`ports.md`](ports.md) | Public and internal ports and protocols |
| [`software-stack.md`](software-stack.md) | Host, container, DNS, routing, RPKI, web, and documentation software |

---

# Reference Rules

- Values describe the current implementation unless explicitly labeled otherwise.
- Environment-specific values are identified as examples or parameters.
- Known defects are documented alongside affected values.
- Future proposals belong under [`../design/`](../design/README.md).
- Stable relationships belong under [`../architecture/`](../architecture/README.md).
- Source code and current deployment evidence take precedence over stale reference text.

---

# Common Starting Points

For operations:

- [`lab-types.md`](lab-types.md);
- [`dns-naming.md`](dns-naming.md);
- [`network-addressing.md`](network-addressing.md);
- [`ports.md`](ports.md).

For implementation review:

- [`container-naming.md`](container-naming.md);
- [`lxd.md`](lxd.md);
- [`aws-resources.md`](aws-resources.md);
- [`software-stack.md`](software-stack.md).

---

# Review Status

**Current Status:** In Review

**Next Review:** Whenever implementation values, names, ports, software, or profile mappings change.
