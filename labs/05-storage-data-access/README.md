# Lab 05 — Azure Storage & Data Access

## Status

**In progress — Phases 1–4 completed**

## Purpose

Understand Azure Storage architecture, data-access paths, authorization models, network controls, and common Storage access failures through practical hands-on exercises.

## Learning Method

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

## Reused Azure Baseline

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
```

The retained VM and networking baseline should remain unchanged unless a phase explicitly requires temporary integration with Azure Storage.

---

## Phases

### Phase 1 — Storage Account Baseline & Architecture — **completed**

Completed:

- created low-cost StorageV2 account `stazsl05npx01`;
- selected Standard performance, LRS redundancy, and Hot access tier;
- inspected Portal security, networking, data protection, and encryption settings;
- verified the Storage Account baseline through Azure CLI;
- identified Blob, File, Queue, Table, DFS, and Web service endpoints;
- inspected the `blobServices/default` child resource and Blob soft-delete settings;
- diagnosed a generic `az resource show` nested-resource addressing failure;
- established a clean Storage baseline before creating data objects.

Documentation:

- `LAB05_PHASE1_STORAGE_ACCOUNT_BASELINE_AND_ARCHITECTURE.md`

---

### Phase 2 — Blob Storage & Data Access — **completed**

Purpose:

Build and inspect a real Blob Storage data path, then compare the main ways a client can access Blob data.

Completed:

#### Blob hierarchy and object access

- created private Blob Container `azsl05-data`;C
- created and uploaded test Blob `hello-storage.txt`;
- inspected the Storage Account → Blob service → Container → Blob hierarchy;
- verified Blob URL structure and object addressing;
- confirmed that direct anonymous access was denied with `PublicAccessNotPermitted`.

#### Microsoft Entra authorization

- attempted Blob data operations using Microsoft Entra authentication through Azure CLI;
- reproduced a real data-plane authorization failure despite having subscription-level `Owner` access;
- compared management-plane role `Actions` with Storage data-plane `DataActions`;
- assigned `Storage Blob Data Contributor` at Storage Account scope;
- verified successful Blob upload and download after the RBAC assignment became effective.

#### User delegation SAS

- generated a read-only user delegation SAS using Microsoft Entra authorization;
- verified that the SAS allowed reading the intended Blob;
- verified that write access failed with `AuthorizationPermissionMismatch`;
- reproduced `AuthenticationFailed / Signature did not match` when a Blob-scoped SAS was reused against a different Blob path;
- confirmed that SAS scope and the signed resource path are part of the authorization boundary.

#### Account-key-based SAS

- generated and tested a read-only SAS signed with a Storage Account key;
- verified successful read access;
- compared user delegation SAS with account-key-based SAS without exposing account credentials;
- confirmed that the two SAS types can grant similar data access while relying on different trust models.

#### Client-side troubleshooting observation

- observed a Windows `az.cmd` / query-string parsing issue while working with SAS URLs;
- separated the local shell/client behavior from Azure Storage authentication and authorization errors.

Key result:

```text
Anonymous access            → denied
Microsoft Entra + no data role → denied
Microsoft Entra + Blob Data Contributor → read/write allowed
Read-only user delegation SAS → read allowed, write denied
Read-only account-key SAS     → read allowed
```

Documentation:

- `LAB05_PHASE2_BLOB_STORAGE_AND_DATA_ACCESS.md`

---

### Phase 3 — Storage Authorization Troubleshooting — **completed**

Purpose:

Create a controlled Microsoft Entra authorization failure and restore only the access actually required, using a narrower role and narrower scope.

Completed:

#### Establish known-good state

- verified working Microsoft Entra Blob access inherited from the Phase 2 `Storage Blob Data Contributor` assignment;
- identified the existing data-plane role assignment at Storage Account scope.

#### Break access deliberately

- removed `Storage Blob Data Contributor` from the Storage Account;
- observed that configured RBAC state and effective data access did not change at exactly the same moment;
- refreshed the Microsoft Entra CLI session without modifying Storage configuration;
- reproduced a Blob data-plane authorization failure after the previous role was no longer effective.

#### Diagnose the failure

- confirmed that Microsoft Entra authentication still succeeded;
- isolated the problem to Blob data-plane authorization rather than authentication, networking, or object existence;
- confirmed that subscription-level `Owner` grants management-plane control but does not automatically grant Blob data access.

#### Apply least-privilege remediation

- replaced the previous write-capable role with `Storage Blob Data Reader`;
- reduced scope from the complete Storage Account to container `azsl05-data`;
- verified Blob read recovery;
- verified Blob write denial under the read-only role.

#### Separate unrelated authentication noise

- encountered an independent Azure CLI authentication/session incident during token refresh;
- kept that incident separate from the Storage RBAC diagnosis so the controlled failure remained attributable to authorization state.

Final authorization state:

```text
Management-plane role: Owner @ subscription
Blob data-plane role:  Storage Blob Data Reader
Blob data role scope:  container azsl05-data
Read:                  allowed
Write:                 denied
```

Key lesson:

> Successful Microsoft Entra authentication does not imply Blob data authorization, and broad management-plane access does not replace Storage data-plane roles.

Documentation:

- `LAB05_PHASE3_STORAGE_AUTHORIZATION_TROUBLESHOOTING.md`

---

### Phase 4 — Storage Networking Troubleshooting — **completed**

Purpose:

Create controlled Storage network failures, distinguish them from authentication and data-plane authorization problems, and verify recovery through both public IP and VNet-based access paths.

Completed:

#### Establish networking baseline

- confirmed `PublicNetworkAccess = Enabled`;
- confirmed Storage firewall `defaultAction = Allow`;
- confirmed no IP rules and no virtual network rules were present;
- verified known-good Blob read before making network changes.

#### Create controlled network denial

- changed only the Storage firewall default action from `Allow` to `Deny`;
- left Microsoft Entra authentication, Blob RBAC, Blob path, and object state unchanged;
- reproduced Blob access failure caused by Storage network rules;
- distinguished the network denial from the Phase 3 authorization failure.

#### Restore access with a public IP rule

- identified the administrator workstation public IPv4 address;
- added it as a Storage firewall IP rule while keeping `defaultAction = Deny`;
- verified that the same Blob read succeeded again;
- demonstrated that valid identity and Blob RBAC still depend on an allowed network path.

#### Test VNet / service endpoint access

- enabled the `Microsoft.Storage` service endpoint on `subnet-azsl-01`;
- added `subnet-azsl-01` as a Storage virtual network rule;
- started retained VM `vm-azsl-01`;
- kept the Storage firewall in `Deny` mode;
- used the same temporary read-only SAS credential for a network-focused comparison;
- executed the Blob request from inside the VM through Azure VM Run Command;
- verified successful Blob access from the allowed subnet.

#### Separate unrelated troubleshooting noise

- encountered `Permission denied (publickey)` during direct SSH and classified it as an SSH authentication issue;
- encountered `curl: (3) URL rejected: Malformed input to a URL function` while transporting a SAS URL through PowerShell → Azure CLI → Run Command → bash;
- resolved the URL transport problem using Base64 encoding/decoding;
- verified Run Command independently before continuing;
- kept these client/tooling issues separate from the Storage network diagnosis.

#### Cleanup and baseline restoration

- removed the temporary Storage virtual network rule;
- removed the `Microsoft.Storage` service endpoint from `subnet-azsl-01`;
- restored Storage firewall `defaultAction = Allow`;
- removed the temporary public IP rule;
- verified empty IP and VNet rule lists;
- returned `vm-azsl-01` to `VM deallocated`;
- restored the retained Azure networking baseline.

Key result:

```text
DefaultAction = Allow
→ Blob read succeeds

DefaultAction = Deny + no matching rule
→ Blob read blocked by Storage network rules

DefaultAction = Deny + matching public IP rule
→ Blob read succeeds

DefaultAction = Deny + matching VNet rule
+ Microsoft.Storage service endpoint
→ VM in subnet-azsl-01 can read the Blob
```

Key lesson:

> Storage networking is an independent access-control layer. Valid authentication and sufficient Blob data-plane authorization do not guarantee access when the Storage network path is blocked.

Documentation:

- `LAB05_PHASE4_STORAGE_NETWORKING_TROUBLESHOOTING.md`

---

### Phase 5 — Azure Files

Goals:

- create an Azure File Share;
- understand SMB-based access;
- compare Azure Files with Blob Storage;
- optionally test access from the retained VM when useful and cost-effective.

---

### Phase 6 — Cleanup & Documentation

Goals:

- delete temporary data and Storage resources;
- verify that the retained Azure baseline is unchanged;
- document final troubleshooting findings;
- update project-level `README.md`, `ROADMAP.md`, and `AZURE_MAP.md`.

---

## Current Checkpoint

```text
[x] Phase 1 — Storage Account Baseline & Architecture
[x] Phase 2 — Blob Storage & Data Access
[x] Phase 3 — Storage Authorization Troubleshooting
[x] Phase 4 — Storage Networking Troubleshooting
[ ] Phase 5 — Azure Files
[ ] Phase 6 — Cleanup & Documentation
```

## Current Storage Baseline

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
Minimum TLS:            1.2
Secure transfer:        Required
HNS:                    Disabled
Private endpoint:       none
Storage firewall:       Allow by default
IP rules:               none
VNet rules:             none
Subnet service endpoint: none

Blob Container:         azsl05-data
Test Blob:              hello-storage.txt

Current user:
Management-plane role:  Owner @ subscription
Blob data-plane role:   Storage Blob Data Reader
Blob data role scope:   container azsl05-data
Previous Blob role:     Storage Blob Data Contributor @ Storage Account — removed

Azure File shares:      none created for Lab 05 yet
```

## Verified Access Matrix

| Access method | Read | Write | Result / observation |
|---|---:|---:|---|
| Anonymous Blob URL | No | No | `PublicAccessNotPermitted` |
| Microsoft Entra without Blob data role | No | No | data-plane authorization denied |
| Microsoft Entra + `Storage Blob Data Contributor` | Yes | Yes | verified during Phase 2 |
| Microsoft Entra after Contributor removal | No | No | authorization failure reproduced |
| Microsoft Entra + `Storage Blob Data Reader` @ container | Yes | No | least-privilege recovery verified |
| Read-only user delegation SAS | Yes | No | write returned `AuthorizationPermissionMismatch` |
| Read-only account-key SAS | Yes | No | read access verified |
| Microsoft Entra + valid Blob role + Storage firewall deny | No | No | blocked by network rules |
| Matching public IP rule with `defaultAction = Deny` | Yes | Depends on SAS/RBAC | network path restored |
| VM in allowed subnet + `Microsoft.Storage` service endpoint | Yes | Depends on SAS/RBAC | VNet-based access verified |

## Troubleshooting Model

For a Storage data-access failure, check the layers independently:

```text
Client / request
      ↓
Correct service endpoint and object path?
      ↓
Authentication valid?
      ↓
Data-plane authorization sufficient?
      ↓
Storage network path allowed?
      ↓
Container / Blob exists and is available?
```

The main diagnostic question is not simply "Does the user have access?" but:

> Is the failure caused by authentication, data-plane authorization, networking, request scope, or object state?

## Core Topics

```text
Storage Account
├── Performance tier
├── Redundancy
├── Service endpoints
├── Blob service
│   ├── Containers
│   └── Blobs
├── File service
│   └── File shares
├── Authentication
│   └── Microsoft Entra ID
├── Authorization
│   ├── Azure RBAC
│   │   ├── Actions
│   │   └── DataActions
│   └── Least privilege
├── SAS
│   ├── User delegation SAS
│   └── Account-key-based SAS
├── Account keys
├── Public network access
├── Firewall / network restrictions
│   ├── Default action
│   ├── Public IP rules
│   └── Virtual network rules
├── Service endpoints
│   └── Microsoft.Storage
└── Private Endpoint concepts
```

## Cost and Lifecycle

Use low-cost Standard storage and minimal test data.

Temporary Storage resources should be deleted after the lab unless they are intentionally retained for Lab 06 monitoring exercises.

## Completion Criteria

Lab 05 is complete when:

- Storage Account architecture has been inspected;
- Blob Storage has been used for real data operations;
- Microsoft Entra-based Blob authorization has been practiced;
- user delegation SAS and account-key-based SAS have been compared;
- at least one controlled authorization failure has been diagnosed and fixed;
- at least one controlled Storage networking failure has been diagnosed and fixed;
- Azure Files has been reviewed or practiced as planned;
- temporary resources have been deleted;
- the retained Azure baseline has been verified;
- project documentation has been updated.

## Next

**Phase 5 — Azure Files**
