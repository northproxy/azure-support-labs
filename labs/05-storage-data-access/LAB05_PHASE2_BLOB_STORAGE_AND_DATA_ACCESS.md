# Lab 05 — Phase 2: Blob Storage & Data Access

## Status

**Completed**

## Purpose

Create and inspect real Blob Storage data objects, compare common data-access methods, and build a practical troubleshooting model for Blob authorization and SAS behavior.

This phase focused on:

- Blob containers and blobs;
- Blob URLs and object hierarchy;
- Microsoft Entra-based data-plane authorization;
- Azure RBAC data roles;
- anonymous access behavior;
- user delegation SAS;
- account-key-based SAS;
- SAS permission and signature troubleshooting.

## Learning Method

**Topic → Build → Observe → Break → Diagnose → Fix → Verify**

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
```

Blob service baseline:

```text
Blob service:           default
Blob soft delete:       Enabled, 7 days
Container soft delete:  Enabled, 7 days
Static website:         Disabled
CORS rules:             none
```

---

## Blob Container Created

A private Blob Container was created through Azure Portal:

```text
Container: azsl05-data
Anonymous access: Private
```

Resulting hierarchy:

```text
Storage Account: stazsl05npx01
└── Blob service: default
    └── Container: azsl05-data
```

The container was initially empty.

---

## Initial Microsoft Entra Data Access Test

The container was listed through Azure CLI using the signed-in Microsoft Entra identity:

```powershell
az storage container list `
  --account-name stazsl05npx01 `
  --auth-mode login `
  --output table
```

Observed result:

```text
Name
-----------
azsl05-data
```

This confirmed that:

- the Storage Account was reachable;
- the Blob endpoint was reachable;
- Microsoft Entra authentication worked;
- the container existed.

---

## Test Blob Preparation

A minimal local file was created:

```powershell
"Hello from Azure Support Labs - Lab 05 Phase 2" |
  Set-Content .\hello-storage.txt
```

Content:

```text
Hello from Azure Support Labs - Lab 05 Phase 2
```

---

## Real Data-Plane Authorization Failure

The first Blob upload was attempted with Microsoft Entra authorization:

```powershell
az storage blob upload `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --file .\hello-storage.txt `
  --auth-mode login `
  --output table
```

Observed failure:

```text
You do not have the required permissions needed to perform this operation.
```

Azure CLI suggested data-plane roles such as:

```text
Storage Blob Data Owner
Storage Blob Data Contributor
Storage Blob Data Reader
```

This became a real authorization troubleshooting case.

---

## RBAC Diagnosis

The current signed-in identity was inspected:

```powershell
$me = az ad signed-in-user show --query id -o tsv
```

Current role assignments:

```text
Role    Scope
------  ----------------------------
Owner   /subscriptions/<GUID-1>
Owner   /subscriptions/<GUID-1>
```

The two duplicate subscription-level `Owner` assignments were already known from Lab 03 and were intentionally left unchanged.

### Role Definition Comparison

The `Owner` role definition was inspected:

```powershell
az role definition list `
  --name Owner `
  --query "[0].{Role:roleName,Actions:permissions[0].actions,DataActions:permissions[0].dataActions}" `
  --output json
```

Observed:

```json
{
  "Actions": [
    "*"
  ],
  "DataActions": [],
  "Role": "Owner"
}
```

The `Storage Blob Data Contributor` role definition was then inspected:

```powershell
az role definition list `
  --name "Storage Blob Data Contributor" `
  --query "[0].{Role:roleName,Actions:permissions[0].actions,DataActions:permissions[0].dataActions}" `
  --output json
```

Observed relevant permissions:

```text
Actions:
- containers/delete
- containers/read
- containers/write
- generateUserDelegationKey/action

DataActions:
- blobs/delete
- blobs/read
- blobs/write
- blobs/move/action
- blobs/add/action
```

### Core Finding

```text
Owner
├── Actions: *
└── DataActions: none

Storage Blob Data Contributor
├── container management actions
└── Blob data-plane DataActions
```

This demonstrated that broad management-plane ownership does not automatically grant Blob data-plane access through Microsoft Entra authorization.

---

## Least-Privilege RBAC Fix

The Storage Account resource ID was retrieved:

```powershell
$storageId = az storage account show `
  --name stazsl05npx01 `
  --resource-group rg-azsl-01 `
  --query id `
  --output tsv
```

The role was assigned only at the Storage Account scope:

```powershell
az role assignment create `
  --assignee-object-id $me `
  --assignee-principal-type User `
  --role "Storage Blob Data Contributor" `
  --scope $storageId `
  --output table
```

Verified assignments:

```text
Role                           Scope
-----------------------------  -----------------------------------------------------------------------
Owner                          /subscriptions/<GUID-1>
Owner                          /subscriptions/<GUID-1>
Storage Blob Data Contributor  .../storageAccounts/stazsl05npx01
```

This preserved least privilege better than assigning the Blob data role at Resource Group or subscription scope.

---

## Blob Upload Verification

The original failed command was repeated without changing the operation:

```powershell
az storage blob upload `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --file .\hello-storage.txt `
  --auth-mode login `
  --output table
```

Observed result:

```text
Finished [...] 100.0000%
Request_server_encrypted: True
```

The upload succeeded after the RBAC change.

Resulting hierarchy:

```text
Storage Account: stazsl05npx01
└── Blob service: default
    └── Container: azsl05-data
        └── Blob: hello-storage.txt
```

---

## Blob URL

The Blob URL follows the standard structure:

```text
https://stazsl05npx01.blob.core.windows.net/azsl05-data/hello-storage.txt
```

Mental model:

```text
https://<storage-account>.blob.core.windows.net/<container>/<blob>
```

The URL identifies the object but is not itself authorization.

---

## Anonymous Access Test

The Blob URL was opened directly in a browser without credentials.

Observed result:

```xml
<Error>
  <Code>PublicAccessNotPermitted</Code>
</Error>
```

This confirmed that:

```text
Blob exists
        ↓
Blob URL is valid
        ↓
Anonymous browser request
        ↓
Storage Account public Blob access disabled
        ↓
PublicAccessNotPermitted
```

The correct action was not to enable public access, because this denial matched the intended security baseline.

---

## Microsoft Entra Read Verification

The same Blob was downloaded through Azure CLI using Microsoft Entra authorization:

```powershell
az storage blob download `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --file .\hello-storage-download.txt `
  --auth-mode login
```

Verification:

```powershell
Get-Content .\hello-storage-download.txt
```

Observed:

```text
Hello from Azure Support Labs - Lab 05 Phase 2
```

This provided a clean comparison:

```text
Anonymous request
→ denied

Microsoft Entra + Blob Data role
→ allowed
```

---

# SAS Access

## User Delegation SAS

A read-only user delegation SAS was generated for the Blob.

Expiry was created dynamically:

```powershell
$expiry = (Get-Date).ToUniversalTime().AddHours(1).ToString("yyyy-MM-ddTHH:mmZ")
```

User delegation SAS:

```powershell
$sasUrl = az storage blob generate-sas `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --permissions r `
  --expiry $expiry `
  --auth-mode login `
  --as-user `
  --full-uri `
  --output tsv
```

The SAS URL was treated as a secret and was not committed or shared.

The URL opened successfully in a private browser window and returned:

```text
Hello from Azure Support Labs - Lab 05 Phase 2
```

The Blob remained private. The SAS delegated temporary access without enabling anonymous public access.

---

## Read-Only SAS Verification

The SAS was created with:

```text
sp=r
```

A write attempt was performed to verify least privilege.

### Initial CLI Parsing Failure

The SAS query string contained `&` separators.

When the SAS token was passed to Azure CLI on Windows, the execution path through `az.cmd` resulted in parts of the SAS being interpreted as separate commands:

```text
'sp' is not recognized as an internal or external command
'sv' is not recognized as an internal or external command
'sr' is not recognized as an internal or external command
...
'sig' is not recognized as an internal or external command
```

Azure returned:

```text
ErrorCode: NoAuthenticationInformation
```

This was not a Storage permission failure.

The request was malformed before Azure received the complete SAS token.

### Support Finding

```text
NoAuthenticationInformation
        ↓
Do not assume SAS permissions are wrong
        ↓
Inspect how the credential was passed
        ↓
Separate local shell/CLI parsing from Azure authorization
```

---

## SAS Resource Signature Test

To bypass the local `az.cmd` parsing behavior, PowerShell `Invoke-WebRequest` was used.

An initial test reused the SAS signature but changed the target Blob name.

Original signed Blob:

```text
hello-storage.txt
```

Modified request target:

```text
sas-write-test.txt
```

Observed result:

```text
AuthenticationFailed
Signature did not match
```

The error included a `String to sign` containing the modified Blob path.

### Finding

A Blob-level SAS is bound to the signed resource path.

Changing the Blob path changes the canonicalized resource used during signature validation.

Therefore:

```text
Valid SAS for blob A
+
request to blob B
=
AuthenticationFailed / Signature did not match
```

This is different from an authorization failure.

---

## Read-Only Permission Test

The write test was corrected to target the same Blob for which the SAS had been generated.

A local replacement file was created:

```powershell
"Attempted overwrite through read-only SAS" |
  Set-Content .\sas-overwrite-test.txt
```

A direct PUT was attempted against the original `$sasUrl`:

```powershell
Invoke-WebRequest `
  -Uri $sasUrl `
  -Method Put `
  -InFile .\sas-overwrite-test.txt `
  -Headers @{
    "x-ms-blob-type" = "BlockBlob"
    "x-ms-version"   = "2026-04-06"
  }
```

Observed result:

```text
AuthorizationPermissionMismatch
This request is not authorized to perform this operation using this permission.
```

This proved that the SAS itself was valid, but its permission set was insufficient for write.

Result:

```text
Read-only SAS
├── read / GET  → allowed
└── write / PUT → denied
```

---

## SAS Failure Classification

Two distinct SAS failure classes were observed.

### Invalid signature/resource combination

```text
AuthenticationFailed
Signature did not match
```

Meaning:

```text
Credential/signature does not match the request resource or signed request properties.
```

### Valid SAS, insufficient permission

```text
AuthorizationPermissionMismatch
```

Meaning:

```text
SAS is accepted
but its permissions do not allow the requested operation.
```

This distinction is important for support troubleshooting.

---

# Account-Key-Based SAS

A second read-only SAS was generated using Shared Key authentication:

```powershell
$keySasUrl = az storage blob generate-sas `
  --account-name stazsl05npx01 `
  --container-name azsl05-data `
  --name hello-storage.txt `
  --permissions r `
  --expiry $expiry `
  --full-uri `
  --auth-mode key `
  --output tsv
```

The Storage Account key itself was not copied into the documentation.

The generated URL successfully returned:

```text
Hello from Azure Support Labs - Lab 05 Phase 2
```

---

## User Delegation SAS vs Account-Key SAS

The two SAS variants were compared without exposing their signatures.

Checks:

```powershell
$keySasUrl -match "sp=r"
$keySasUrl -match "skoid="
$sasUrl -match "skoid="
```

Observed:

```text
$keySasUrl -match "sp=r"     → True
$keySasUrl -match "skoid="   → False
$sasUrl -match "skoid="      → True
```

Interpretation:

```text
User delegation SAS
├── Microsoft Entra authentication
├── user delegation key
├── Blob data RBAC is relevant
└── user-delegation fields such as skoid are present

Account-key-based SAS
├── Shared Key trust model
├── signed using Storage Account key
└── user-delegation identity fields such as skoid are absent
```

Both can provide temporary read access, but their trust models are different.

---

## Access Method Summary

The same private Blob was tested through several access methods:

```text
Private Blob: hello-storage.txt
│
├── Anonymous plain URL
│   └── PublicAccessNotPermitted
│
├── Microsoft Entra without Blob Data role
│   └── upload denied
│
├── Microsoft Entra + Storage Blob Data Contributor
│   ├── upload allowed
│   └── download allowed
│
├── User delegation SAS, read-only
│   ├── browser read allowed
│   └── write denied: AuthorizationPermissionMismatch
│
└── Account-key-based SAS, read-only
    └── browser read allowed
```

---

## Control Plane vs Data Plane

This phase reinforced the distinction between two Azure permission categories.

```text
Control plane
├── ARM resource configuration
├── Storage Account configuration
├── role assignment management
└── governed primarily by Actions

Data plane
├── Blob read
├── Blob write
├── Blob delete
└── governed by DataActions for Microsoft Entra RBAC
```

The practical example:

```text
Owner at subscription scope
→ Storage Account management works
→ Blob write through --auth-mode login does not automatically work

Storage Blob Data Contributor at Storage Account scope
→ Blob read/write succeeds
```

---

## Troubleshooting Model

Phase 2 produced the following support-oriented diagnostic sequence:

```text
Blob operation fails
        ↓
Is the endpoint / Blob URL correct?
        ↓
Is the Storage Account reachable?
        ↓
Is the request authenticated?
        ↓
Which authorization method is being used?
        ├── Microsoft Entra
        ├── SAS
        └── Shared Key
        ↓
Does the identity / SAS have the required operation permission?
        ↓
Is the SAS signed for this exact resource?
        ↓
Is anonymous access expected or intentionally disabled?
```

Useful error mapping observed during this phase:

```text
PublicAccessNotPermitted
→ anonymous access denied by account policy

NoAuthenticationInformation
→ request reached Azure without usable authentication information
  in this case caused by local SAS argument parsing

AuthenticationFailed / Signature did not match
→ SAS signature did not match the requested resource

AuthorizationPermissionMismatch
→ authentication/SAS accepted but required permission missing
```

---

## Security Findings

- Blob URLs are addresses, not credentials.
- Anonymous access remained disabled throughout the phase.
- `Owner` does not automatically grant Blob `DataActions`.
- Storage data-plane RBAC should be assigned at the smallest practical scope.
- SAS URLs are credentials and must not be committed or shared.
- Read-only SAS can provide temporary access without making a Blob public.
- User delegation SAS and account-key-based SAS may provide similar access while using different trust models.
- Account keys have a larger blast radius than a narrowly scoped user delegation SAS and should be handled accordingly.

---

## Current Phase 2 State

```text
Storage Account: stazsl05npx01
└── Blob service: default
    └── Container: azsl05-data
        └── Blob: hello-storage.txt
```

Current access configuration relevant to the lab:

```text
Anonymous Blob access:            Disabled
Shared Key access:                Enabled
Current user management role:     Owner at subscription scope
Current user Blob data role:      Storage Blob Data Contributor
Blob data role scope:             stazsl05npx01 Storage Account
```

Temporary local files used during testing:

```text
hello-storage.txt
hello-storage-download.txt
sas-write-test.txt
sas-overwrite-test.txt
```

SAS values must not be committed.

---

## Verification Checkpoint

Phase 2 is complete because:

- a private Blob Container was created;
- a real Blob was uploaded;
- container/blob hierarchy was inspected;
- Blob URL structure was understood;
- anonymous access denial was verified;
- Microsoft Entra data access was tested;
- a real data-plane authorization failure was diagnosed;
- `Owner` Actions and Blob Data `DataActions` were compared;
- least-privilege `Storage Blob Data Contributor` access was assigned at Storage Account scope;
- the original failed upload succeeded after the RBAC fix;
- Blob download through Microsoft Entra authorization was verified;
- a user delegation SAS was created and tested;
- read-only SAS behavior was verified;
- SAS signature mismatch and permission mismatch were distinguished;
- an account-key-based SAS was created and compared with user delegation SAS;
- no Storage networking restrictions were introduced;
- the retained VM/network baseline remained unchanged.

---

## Next

**Phase 3 — Storage Authorization Troubleshooting**

Planned focus:

- create a deliberate, controlled authorization failure;
- inspect effective Blob data-plane RBAC scope;
- distinguish Microsoft Entra authentication from authorization;
- diagnose before changing access;
- apply the minimum required remediation;
- verify recovery;
- clean up temporary role assignments where appropriate.
