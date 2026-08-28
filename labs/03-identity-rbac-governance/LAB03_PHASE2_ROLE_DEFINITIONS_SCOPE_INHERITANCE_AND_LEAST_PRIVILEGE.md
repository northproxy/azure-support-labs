# Lab 03 — Phase 2: Role Definitions, Scope, Inheritance, and Least Privilege

Status: **completed**

## Purpose

Understand Azure RBAC role definitions, role assignments, scope, inheritance, and least privilege through a controlled authorization failure and remediation.

## Reused environment

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
Test user:      AZSL RBAC Test User
```

---
### Role definition model

The following built-in roles were reviewed:

- Owner
- Contributor
- Reader
- Virtual Machine Contributor

Key RBAC fields:

```text
Actions         → allowed control-plane operations
NotActions      → exclusions from Actions
DataActions     → allowed data-plane operations
NotDataActions  → exclusions from DataActions
```

Core role model:

```text
Security principal
        +
Role definition
        +
Scope
        =
Role assignment
```

### Scope and inheritance

The current Owner assignments exist at subscription scope.

When role assignments were listed for `rg-azsl-01` with inherited assignments included, the subscription-level Owner assignments appeared. Without inherited assignments, no direct role assignments existed on the resource group.

This demonstrated:

```text
Subscription
    ↓ inheritance
Resource Group
    ↓ inheritance
Resources
```

Support takeaway:

> Effective access can come from a parent scope even when no direct assignment exists on the resource being investigated.

### Test identity

A temporary Microsoft Entra user was created:

```text
AZSL RBAC Test User
```

A direct assignment was initially created:

```text
Reader @ rg-azsl-01
```

In the Azure portal, the test user could open `rg-azsl-01` and inspect `vm-azsl-01`.

This verified that Reader permissions inherited from the resource-group scope to the VM.

### Controlled authorization failure

The test user attempted to start the VM from the Azure portal.

The operation failed with an authorization error for:

```text
Microsoft.Compute/virtualMachines/start/action
```

Diagnosis:

```text
Authentication                         → successful
Read access to VM                      → successful
Scope                                  → correct
Microsoft.Compute/.../start/action     → not allowed by Reader
```

This separated authentication from authorization in a real scenario.

### Fix

The built-in `Virtual Machine Contributor` role definition was inspected. It contains:

```text
Microsoft.Compute/virtualMachines/*
```

The role was assigned to the test user at:

```text
rg-azsl-01
```

After the portal authentication session was refreshed, the test user successfully started the VM.

Troubleshooting cycle completed:

```text
Build      → Reader @ rg-azsl-01
Observe    → VM readable
Break      → Start VM
Diagnose   → missing virtualMachines/start/action
Fix        → Virtual Machine Contributor @ rg-azsl-01
Verify     → VM start succeeded after session refresh
```

### Least-privilege cleanup

The direct `Reader` assignment was removed after `Virtual Machine Contributor` was in place.

The test user's remaining direct role was temporarily:

```text
Virtual Machine Contributor @ rg-azsl-01
```

This demonstrated that redundant assignments should be removed when a more appropriate role already supplies the required access.

---

---

## Phase result

The controlled `AuthorizationFailed` scenario was reproduced, diagnosed as a missing `Reader` permission for VM start, fixed with `Virtual Machine Contributor`, verified after session refresh, and cleaned up by removing the redundant direct `Reader` assignment.
