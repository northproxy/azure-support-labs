# Lab 03 — Phase 3: Azure RBAC versus Microsoft Entra Roles

Status: **completed**

## Purpose

Separate Microsoft Entra administrative roles from Azure RBAC roles and establish the management boundary between directory administration and Azure resource authorization.

---
The Azure portal was used to inspect both Azure RBAC roles and Microsoft Entra administrative roles.

Examples reviewed:

```text
Azure RBAC roles                 Microsoft Entra roles
------------------------------   ------------------------------
Owner                            Global Administrator
Contributor                      User Administrator
Reader                           Global Reader
Virtual Machine Contributor      Groups Administrator
```

Conceptual boundary:

```text
Microsoft Entra roles
→ administer directory and identity objects
→ users, groups, applications, authentication, tenant settings

Azure RBAC roles
→ authorize operations on Azure resources
→ subscriptions, resource groups, VMs, networks, storage, etc.
```

Key conclusion:

```text
Global Administrator ≠ Owner
Owner ≠ Global Administrator
```

A subscription Owner is not automatically a Microsoft Entra Global Administrator, and a Global Administrator is not automatically an Azure subscription Owner.

---

---

## Phase result

The administrative boundary was confirmed:

```text
Microsoft Entra roles → directory and identity administration
Azure RBAC roles      → Azure resource authorization
```
