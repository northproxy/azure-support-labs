# Azure Support Labs

Practical Microsoft Azure labs created alongside the **Microsoft Cloud Support Associate Professional Certificate** on Coursera.

## Goal

The goal of this project is to turn course topics into hands-on Azure support experience.

Learning cycle:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

Instead of only learning Azure concepts theoretically, each important topic is practiced using real Azure resources where practical.

## Current Progress

* Courses 1–7 completed
* Course 8 — **Azure Cloud Services** in progress
* Lab 01 — **completed**
* Lab 02 — **completed**
* Lab 03 — **completed**

Lab 03 completion summary:

* identity and authentication/authorization baseline completed;
* Azure RBAC role definitions, assignments, scope, inheritance, and least privilege practiced;
* controlled `AuthorizationFailed` scenario diagnosed, fixed, and verified;
* Azure RBAC versus Microsoft Entra roles compared;
* group-based RBAC access verified;
* Azure Policy definitions, assignments, scope, inheritance, initiatives, and compliance evaluation practiced;
* controlled `Audit` and `Deny` scenarios completed, including `RequestDisallowedByPolicy` troubleshooting;
* temporary Microsoft Entra test user and group deleted;
* temporary Lab 03 RBAC and Policy assignments removed;
* temporary Policy test resources deleted;
* `vm-azsl-01` returned to `VM deallocated`;
* primary administrative access and inherited subscription-level security governance left unchanged.

## Project Structure

```text
azure-support-labs/
├── README.md
├── PROJECT.md
├── ROADMAP.md
├── AZURE_MAP.md
├── LAB_TEMPLATE.md
├── docs/
│   ├── architecture/
│   └── screenshots/
├── tools/
│   ├── README.md
│   ├── azure-output-sanitizer.html
│   ├── azure-output-sanitizer.css
│   ├── azure-output-sanitizer.js
│   └── azure-output-sanitizer.png
└── labs/
    ├── course-07/
    ├── course-08/
    ├── course-09/
    ├── course-10/
    ├── course-11/
    └── course-12/
```

## Project Tools

### Azure Output Sanitizer

The repository includes a local browser-based helper for sanitizing Azure CLI and PowerShell output before sharing it with ChatGPT or saving it in project documentation.

Location:

```text
tools/
```

The sanitizer currently replaces GUIDs, IPv4 addresses, UPN/email addresses, MAC addresses, and SSH public keys while preserving useful Azure troubleshooting context such as resource names, provider paths, regions, VM sizes, ports, protocols, CIDR prefix lengths, and resource states.

The tool runs locally in the browser and does not make network requests. It is a lightweight project helper, not a production DLP or secret-scanning solution.

See [`tools/README.md`](tools/README.md) for current rules and limitations.

## Labs

* [x] Lab 01 — Azure Foundation & Resource Lifecycle
* [x] Lab 02 — Azure Compute & Administration
* [x] Lab 03 — Identity, RBAC & Governance — **completed**
* [ ] Lab 04 — Azure Networking & Connectivity Troubleshooting
* [ ] Lab 05 — Azure Storage & Data Access
* [ ] Lab 06 — Monitoring, Logs & Incident Diagnosis
* [ ] Lab 07 — Backup, Recovery, Updates & Compliance

Lab 03 practical work covered Microsoft Entra users and groups, Azure RBAC roles and assignments, scope and inheritance, least privilege, controlled authorization failure diagnosis, Microsoft Entra roles versus Azure RBAC, group-based access, Azure Policy definitions and assignments, initiatives, compliance evaluation, `Audit` versus `Deny`, controlled governance failure diagnosis, and final cleanup.

## Main Areas

* Azure resource management
* Compute
* Networking
* Identity and RBAC
* Monitoring
* Backup and recovery
* Security and compliance
* Cloud troubleshooting

## Documentation

* [`PROJECT.md`](PROJECT.md) — project goals and learning method
* [`ROADMAP.md`](ROADMAP.md) — learning phases and progress
* [`AZURE_MAP.md`](AZURE_MAP.md) — growing Azure knowledge map
* [`LAB_TEMPLATE.md`](LAB_TEMPLATE.md) — standard structure for practical labs
* [`labs/03-identity-rbac-governance/README.md`](labs/03-identity-rbac-governance/README.md) — Lab 03 overview and phase index
* [`labs/03-identity-rbac-governance/LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md`](labs/03-identity-rbac-governance/LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md) — identity and access baseline
* [`labs/03-identity-rbac-governance/LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md`](labs/03-identity-rbac-governance/LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md) — RBAC scope, inheritance, least privilege, and authorization troubleshooting
* [`labs/03-identity-rbac-governance/LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md`](labs/03-identity-rbac-governance/LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md) — Azure RBAC versus Microsoft Entra roles
* [`labs/03-identity-rbac-governance/LAB03_PHASE4_GROUP_BASED_RBAC.md`](labs/03-identity-rbac-governance/LAB03_PHASE4_GROUP_BASED_RBAC.md) — group-based RBAC
* [`labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md`](labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md) — Azure Policy basics, compliance, and governance troubleshooting

## Current Checkpoint

Labs 01–03 are completed.

Next:

**Lab 04 — Azure Networking & Connectivity Troubleshooting**

The retained VM baseline is:

```text
vm-azsl-01 → VM deallocated
```

## Certification Path

Planned progression:

**Microsoft Cloud Support Associate → AZ-900 → further Azure administration labs → AZ-104**

## Cost and Security

Labs are designed to use low-cost resources.

Temporary resources should normally be deleted after each lab.

Sensitive data such as credentials, secrets, tenant information, billing data and raw private screenshots are not stored in this repository.
