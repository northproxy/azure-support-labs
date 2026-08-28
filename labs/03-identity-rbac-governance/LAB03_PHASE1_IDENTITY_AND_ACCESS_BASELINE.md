# Lab 03 — Phase 1: Identity and Access Baseline

Status: **completed**

## Purpose

Establish the Microsoft Entra identity and Azure access baseline used by the rest of Lab 03, and distinguish tenant identity context from Azure subscription and RBAC scope.

## Reused environment

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VM size:        Standard_B2ats_v2
OS disk:        30 GiB StandardSSD_LRS
Data disks:     none
```

The exercise reused the existing Azure subscription and Resource Group. No broad access changes were made to the primary administrative account.

---
### Observed account context

Azure CLI account context was inspected with `az account show`.

Observed concepts:

- Azure public cloud environment (`AzureCloud`).
- One active default Azure subscription.
- Microsoft Entra tenant context.
- Tenant and subscription are different concepts: the tenant is the identity boundary; the subscription is an Azure resource, billing, and RBAC scope.

### Signed-in identity

The current signed-in user was inspected with:

```powershell
az ad signed-in-user show --query "{displayName:displayName,userPrincipalName:userPrincipalName,objectId:id}" -o json
```

The UPN contained the `#EXT#` marker, showing that the account is represented in the tenant as an external/guest user object.

Important distinctions:

```text
displayName        → human-readable name
userPrincipalName  → sign-in/name representation in the tenant
objectId           → unique Entra object identifier used as the security principal identity
```

Azure RBAC reported the principal type as `User`.

### Existing Owner assignments

The signed-in user had two separate `Owner` role assignment objects at subscription scope.

Both assignments had the same:

- principal;
- role definition (`Owner`);
- subscription scope;
- no condition.

They differed only by role assignment object ID.

Conclusion:

> Two duplicate Owner role assignment objects exist for the same principal, role, and scope. They do not provide additional effective permissions.

The duplicate Owner assignments were intentionally left unchanged during the lab to avoid modifying the primary administrative access path.

---

---

## Phase result

The identity and access baseline was established. The primary external/guest user and duplicate subscription-level `Owner` assignment objects were identified and intentionally left unchanged.
