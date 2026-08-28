# Lab 03 — Identity, RBAC & Governance

Status: **active**

## Purpose

Build a practical understanding of Microsoft Entra identity, authentication versus authorization, Azure RBAC, scope and inheritance, least privilege, group-based access, and basic Azure governance.

Learning cycle:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

## Reused Azure environment

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VM size:        Standard_B2ats_v2
VM state:       Stopped (deallocated)
OS disk:        30 GiB StandardSSD_LRS
Data disks:     none
```

## Current access model

```text
Primary administrative account
└── Owner @ Subscription
    ├── duplicate assignment object A
    └── duplicate assignment object B

AZSL RBAC Test User
└── member of AZSL RBAC VM Operators
    └── Virtual Machine Contributor @ rg-azsl-01
        └── inherited by vm-azsl-01
```

The duplicate subscription-level `Owner` assignment objects were observed and intentionally left unchanged.

## Lab phases

| Phase | Topic | Status | Documentation |
|---|---|---|---|
| 1 | Identity and access baseline | completed | [`LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md`](LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md) |
| 2 | Role definitions, scope, inheritance, and least privilege | completed | [`LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md`](LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md) |
| 3 | Azure RBAC versus Microsoft Entra roles | completed | [`LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md`](LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md) |
| 4 | Group-based RBAC | completed | [`LAB03_PHASE4_GROUP_BASED_RBAC.md`](LAB03_PHASE4_GROUP_BASED_RBAC.md) |
| 5 | Azure Policy basics | completed | [`LAB03_PHASE5_AZURE_POLICY_BASICS.md`](LAB03_PHASE5_AZURE_POLICY_BASICS.md) |

## Completed practical coverage

```text
Microsoft Entra user and group objects
External/guest user representation
Authentication versus authorization
Azure RBAC role definitions
Role assignments
Scope and inheritance
Owner / Contributor / Reader / Virtual Machine Contributor
Least privilege
Controlled AuthorizationFailed troubleshooting
Session refresh after RBAC changes
Azure RBAC versus Microsoft Entra roles
Group-based RBAC
Azure Policy definitions and assignments
Policy scope and inheritance
Policy initiatives
Compliance evaluation
Audit and Deny effects
RequestDisallowedByPolicy troubleshooting
RBAC versus Policy versus platform restriction diagnosis
Policy cleanup and baseline verification
```

## Key troubleshooting distinctions

```text
AuthorizationFailed
→ Azure RBAC / authorization problem

RequestDisallowedByPolicy
→ Azure Policy governance problem

RequestDisallowedByAzure + locationineligible
→ Azure platform / regional eligibility restriction
```

## Temporary objects and cleanup

Phase 5 temporary managed identities and the Resource Group scoped Policy assignment were deleted after verification.

Current retained Lab 03 test access:

```text
AZSL RBAC Test User
└── member of AZSL RBAC VM Operators
    └── Virtual Machine Contributor @ rg-azsl-01
```

The inherited subscription-level `ASC Default` / Microsoft cloud security benchmark Policy assignment was observed only and was not modified.

Final Lab 03 cleanup should remove the remaining temporary test user, group, and RBAC assignment when they are no longer needed.

## Completion criteria

Lab 03 is complete when:

- identity, authentication, and authorization are clearly distinguished;
- Microsoft Entra users and groups have been inspected and used;
- Azure RBAC role definitions, assignments, scope, and inheritance are understood;
- least-privilege access has been practiced;
- an `AuthorizationFailed` scenario has been reproduced, diagnosed, fixed, and verified;
- group-based access has been verified;
- Azure RBAC and Microsoft Entra roles have been distinguished;
- Azure Policy basics have been practiced through `Audit` and `Deny`;
- temporary Lab 03 identity and RBAC objects have been removed;
- the Azure baseline has been restored;
- `ROADMAP.md` and `AZURE_MAP.md` reflect the completed work.

## Related project documentation

- [`../../README.md`](../../README.md) — project overview
- [`../../ROADMAP.md`](../../ROADMAP.md) — project roadmap
- [`../../AZURE_MAP.md`](../../AZURE_MAP.md) — Azure knowledge map

## Current checkpoint

Phases 1–5 are completed.

The VM is confirmed as:

```text
VM deallocated
```

Lab 03 remains **active** until the remaining temporary identity/RBAC objects are reviewed and final cleanup is completed.
