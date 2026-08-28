# Lab 03 — Phase 4: Group-based RBAC

Status: **completed**

## Purpose

Practice group-based Azure RBAC and verify that effective permissions can be inherited through Microsoft Entra group membership rather than direct user assignments.

## Test objects

```text
Test user:  AZSL RBAC Test User
Test group: AZSL RBAC VM Operators
Role:       Virtual Machine Contributor @ rg-azsl-01
```

---
A temporary Microsoft Entra security group was created:

```text
AZSL RBAC VM Operators
```

The test user was added as a group member.

The direct `Virtual Machine Contributor` assignment was removed from the user.

The same Azure RBAC role was then assigned to the group:

```text
AZSL RBAC VM Operators
└── Virtual Machine Contributor @ rg-azsl-01
```

The test user retained the ability to start `vm-azsl-01` through group membership.

Effective access path:

```text
AZSL RBAC Test User
        ↓ member of
AZSL RBAC VM Operators
        ↓ Azure RBAC assignment
Virtual Machine Contributor @ rg-azsl-01
        ↓
vm-azsl-01
```

Support takeaway:

> A user can have effective Azure access even when there is no direct role assignment on that user. Group membership and group-based role assignments must be checked during access troubleshooting.

---

---

## Phase result

Group-based RBAC was verified successfully. The test user retained VM operator access through membership in `AZSL RBAC VM Operators`, with no direct Azure RBAC assignment required on the user for this scenario.
