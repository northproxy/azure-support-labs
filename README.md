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
* Lab 03 — **active**

Current Lab 03 checkpoint:

* identity and authentication/authorization baseline completed;
* Azure RBAC role definitions, assignments, scope, and inheritance practiced;
* least-privilege `AuthorizationFailed` scenario diagnosed and fixed;
* Azure RBAC versus Microsoft Entra roles compared;
* group-based RBAC access verified;
* Azure Policy definitions, assignments, scope, inheritance, initiatives, and compliance evaluation practiced;
* controlled `Audit` and `Deny` scenarios completed, including `RequestDisallowedByPolicy` troubleshooting;
* temporary Policy test resources deleted and `vm-azsl-01` returned to `VM deallocated`.

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
└── labs/
    ├── course-07/
    ├── course-08/
    ├── course-09/
    ├── course-10/
    ├── course-11/
    └── course-12/
```

## Labs

* [x] Lab 01 — Azure Foundation & Resource Lifecycle
* [x] Lab 02 — Azure Compute & Administration
* [ ] Lab 03 — Identity, RBAC & Governance — **active**
* [ ] Lab 04 — Azure Networking & Connectivity Troubleshooting
* [ ] Lab 05 — Azure Storage & Data Access
* [ ] Lab 06 — Monitoring, Logs & Incident Diagnosis
* [ ] Lab 07 — Backup, Recovery, Updates & Compliance

Lab 03 practical work currently covers Microsoft Entra users and groups, Azure RBAC roles and assignments, scope and inheritance, least privilege, controlled authorization failure diagnosis, Microsoft Entra roles versus Azure RBAC, group-based access, Azure Policy definitions and assignments, initiatives, compliance evaluation, `Audit` versus `Deny`, and controlled governance failure diagnosis.

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
* [`labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md`](labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md) — Azure Policy basics, compliance, and governance troubleshooting

## Certification Path

Planned progression:

**Microsoft Cloud Support Associate → AZ-900 → further Azure administration labs → AZ-104**

## Cost and Security

Labs are designed to use low-cost resources.

Temporary resources should normally be deleted after each lab.

Sensitive data such as credentials, secrets, tenant information, billing data and raw private screenshots are not stored in this repository.
