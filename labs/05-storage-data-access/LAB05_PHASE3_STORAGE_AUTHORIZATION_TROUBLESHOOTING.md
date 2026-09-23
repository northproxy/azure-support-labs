# Lab 05 — Phase 3: Storage Authorization Troubleshooting

## Status

**Completed**

## Purpose

Create a deliberate Blob data-plane authorization failure, diagnose it before changing access, and restore only the minimum permissions required at the narrowest practical Azure RBAC scope.

This phase focused on:

- Microsoft Entra authentication versus Azure Storage authorization;
- Azure RBAC data-plane roles;
- role assignment scope;
- effective versus configured RBAC state;
- RBAC propagation behavior;
- least-privilege remediation;
- read-versus-write verification.

## Learning Method

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

---

## Reused Azure Baseline

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
NIC:            vm-azsl-01284
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
Public IP:      vm-azsl-01-ip
```

The retained VM and networking baseline was not modified during this phase.

---

## Storage Baseline

```text
Storage Account:        stazsl05npx01
Resource Group:         rg-azsl-01
Region:                 Austria East
Kind:                   StorageV2
SKU:                    Standard_LRS
Access tier:            Hot
Public network access:  Enabled
Anonymous Blob access:  Disabled
Shared Key access:      Enabled
Minimum TLS:            TLS 1.2
Secure transfer:        Required
Hierarchical namespace: Disabled
Private endpoint:       none

Blob Container:         azsl05-data
Test Blob:              hello-storage.txt
```

Initial authorization state:

```text
Current user management-plane role:
Owner at subscription scope
(two duplicate Owner assignments already known from Lab 03; left unchanged)

Current Blob data-plane role:
Storage Blob Data Contributor

Scope:
Storage Account stazsl05npx01
```

---

## Known-Good Baseline Verification

Before introducing the failure, the current role assignments were inspected and the Blob was read successfully.

Observed role assignments:

```text
Owner                          /subscriptions/<GUID-1>
Owner                          /subscriptions/<GUID-1>
Storage Blob Data Contributor  .../storageAccounts/stazsl05npx01
```

Blob verification:

```powershell
az storage blob show `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --auth-mode login `
  --query "{Name:name,Size:properties.contentLength}" `
  --output table
```

Observed:

```text
Name               Size
-----------------  ----
hello-storage.txt  48
```

This established a known-good state:

```text
Microsoft Entra authentication works
+
Blob exists
+
Blob data authorization works
=
known-good baseline
```

---

## Controlled Break

The exact `Storage Blob Data Contributor` role assignment object was identified and its resource ID was captured.

The role assignment was then deleted by ID so that only the intended Blob data-plane assignment was removed.

No changes were made to:

```text
Microsoft Entra identity
Owner assignments
Storage Account configuration
Blob Container
Blob object
Storage networking
Shared Key configuration
Retained VM/network baseline
```

Only this access path was changed:

```text
Storage Blob Data Contributor
@ Storage Account scope
→ removed
```

---

## Configured RBAC vs Effective Access

After the role assignment was removed, Azure RBAC inspection returned no `Storage Blob Data Contributor` assignment for the current user.

However, the existing CLI session and Azure Portal initially continued to read `hello-storage.txt` successfully.

This produced an important support observation:

```text
Configured RBAC state
→ role assignment removed

Effective Blob access
→ temporarily still allowed
```

The practical lesson was not to assume that a role assignment change becomes effective on every data-plane request immediately.

Troubleshooting rule:

```text
RBAC configuration changed
        ↓
Verify configured role assignments
        ↓
Retest the actual data-plane operation
        ↓
Account for propagation / cached authorization state
```

No additional RBAC changes were made while this state was being observed.

---

## Authentication-Side Incident During Session Refresh

To obtain a fresh Microsoft Entra session, Azure CLI authentication was refreshed.

An initial login attempt produced:

```text
AADSTS50076
```

The message required multi-factor authentication for the Azure CLI sign-in.

A device-code login attempt then produced:

```text
Error Code: 530035
App name: Microsoft Azure CLI
Device platform: Windows 10
Device state: Unregistered
```

The related Entra sign-in details showed:

```text
Policy: Security Defaults
Policy state: Enabled
Result: Success
Resource: Azure Resource Manager
Client app: Browser
```

Because the visible sign-in evidence did not identify a blocking policy, no security policy, MFA configuration, or device registration setting was changed.

A normal tenant-specific interactive login was then retried:

```powershell
az login --tenant <GUID-1>
```

This login succeeded and the expected subscription was selected.

### Support Finding

The authentication-side errors were treated as a separate incident from Blob authorization.

They did not change the Storage configuration and were not used as evidence for the root cause of the Blob access failure.

This preserved the troubleshooting distinction:

```text
Authentication problem
→ can the identity obtain a valid session/token?

Authorization problem
→ does the authenticated identity have permission for the requested Blob operation?
```

---

## Authorization Failure Reproduced

After obtaining a fresh Microsoft Entra session, the same Blob data-plane read was repeated:

```powershell
az storage blob show `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --auth-mode login `
  --query "{Name:name,Size:properties.contentLength}" `
  --output table
```

Observed:

```text
You do not have the required permissions needed to perform this operation.
```

Azure CLI suggested Blob data-plane roles such as:

```text
Storage Blob Data Owner
Storage Blob Data Contributor
Storage Blob Data Reader
```

At this point the evidence was clean:

```text
Microsoft Entra login
→ successful

Identity
→ authenticated

Blob
→ known to exist

Storage networking
→ unchanged

Storage Blob Data Contributor
→ removed

Blob read
→ denied
```

### Diagnosis

The failure was classified as an **authorization failure**, not an authentication failure.

The subscription-level `Owner` role remained present, but it did not provide the Blob data-plane permission required by `--auth-mode login`.

This reinforced the Phase 2 model:

```text
Owner
├── management-plane Actions
└── no automatic Blob DataActions

Blob data role
└── required for Microsoft Entra Blob data access
```

---

## Least-Privilege Remediation Design

The previous state granted:

```text
Storage Blob Data Contributor
@ Storage Account scope
```

For the current scenario, only read access to one container was required.

The remediation was therefore deliberately narrowed in two dimensions:

```text
Permission:
Contributor → Reader

Scope:
Storage Account → Blob Container
```

The target scope was:

```text
/subscriptions/<GUID-1>/resourceGroups/rg-azsl-01/providers/Microsoft.Storage/storageAccounts/stazsl05npx01/blobServices/default/containers/azsl05-data
```

The current user was assigned:

```text
Storage Blob Data Reader
@ container azsl05-data
```

---

## Read Recovery Verification

Immediately after the new assignment, the Blob read initially still returned the authorization error.

No additional access changes were made.

After the new role became effective, the same read operation succeeded:

```text
Name               Size
-----------------  ----
hello-storage.txt  48
```

This confirmed recovery using the narrower role and scope.

---

## Write Denial Verification

To verify least privilege, a temporary local file was created and an upload was attempted using Microsoft Entra authorization.

The upload failed with:

```text
You do not have the required permissions needed to perform this operation.
```

Result:

```text
Storage Blob Data Reader
@ azsl05-data container

read  → allowed
write → denied
```

The temporary local write-test file was deleted after verification.

No test Blob was created because the write operation was denied.

---

## Before and After Comparison

### Phase 2 state

```text
Storage Blob Data Contributor
@ Storage Account stazsl05npx01

Blob read  → allowed
Blob write → allowed
```

### Phase 3 final state

```text
Storage Blob Data Reader
@ container azsl05-data

Blob read  → allowed
Blob write → denied
```

The final state is narrower by both permission and scope.

---

## Troubleshooting Model

Phase 3 produced the following authorization-focused sequence:

```text
Blob data operation fails
        ↓
Can the user authenticate to Microsoft Entra?
        ↓
Is the Blob known to exist?
        ↓
Did Storage networking change?
        ↓
Which authorization method is being used?
        ↓
If Microsoft Entra:
inspect Blob data-plane role assignments
        ↓
Inspect role scope
        ↓
Compare required operation with granted DataActions
        ↓
Account for RBAC propagation / session state
        ↓
Apply minimum role at minimum scope
        ↓
Retest allowed operation
        ↓
Retest disallowed operation
```

---

## Key Findings

- Successful Microsoft Entra authentication does not imply successful Blob authorization.
- Subscription-level `Owner` access does not automatically grant Blob data-plane operations.
- Azure RBAC configuration state and effective data-plane access can temporarily differ after role changes.
- Role assignment scope is part of authorization, not only the role name.
- `Storage Blob Data Reader` is sufficient for the read-only requirement exercised here.
- Container-level scope can reduce access compared with assigning a data role at the whole Storage Account.
- Least privilege should be verified both positively and negatively:
  - required operation succeeds;
  - non-required operation remains denied.
- Authentication incidents encountered while refreshing a session should be diagnosed separately from Storage authorization failures.
- No security controls should be weakened when the available evidence does not establish them as the root cause.

---

## Current Phase 3 State

```text
Storage Account: stazsl05npx01
└── Blob service: default
    └── Container: azsl05-data
        └── Blob: hello-storage.txt
```

Current access configuration relevant to the lab:

```text
Anonymous Blob access:         Disabled
Shared Key access:             Enabled
Current user management role:  Owner at subscription scope
Current user Blob data role:   Storage Blob Data Reader
Blob data role scope:          container azsl05-data

Microsoft Entra Blob read:     allowed
Microsoft Entra Blob write:    denied
```

The previous `Storage Blob Data Contributor` assignment at Storage Account scope is no longer present.

---

## Verification Checkpoint

Phase 3 is complete because:

- a known-good Blob authorization baseline was verified;
- the existing Blob data Contributor assignment was identified precisely;
- the assignment was removed as a controlled failure;
- configured RBAC state was inspected before remediation;
- temporary continued access after role removal was observed;
- Microsoft Entra authentication was refreshed independently of Storage authorization;
- the Blob data-plane authorization failure was reproduced with a fresh session;
- authentication was distinguished from authorization;
- subscription-level `Owner` was confirmed insufficient for Blob data access;
- the remediation was reduced from Contributor to Reader;
- the remediation scope was narrowed from Storage Account to Blob Container;
- Blob read recovery was verified;
- Blob write denial was verified;
- the temporary local write-test file was deleted;
- the retained VM/network baseline was unchanged.

---

## Next

**Phase 4 — Storage Networking Troubleshooting**

Planned focus:

- inspect the current public network access path;
- understand Storage Account firewall and selected-network controls;
- create a controlled network-access failure;
- distinguish network denial from authentication and authorization failures;
- diagnose before changing network configuration;
- restore access and verify the Blob data path.
