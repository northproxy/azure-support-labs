# Lab 05 — Phase 1: Storage Account Baseline & Architecture

## Status

**Completed**

## Purpose

Create and inspect a low-cost Azure Storage Account baseline before introducing Blob containers, test data, authorization failures, or network restrictions.

This phase focused on understanding the Storage Account as both:

- an Azure Resource Manager resource;
- a configuration boundary for multiple storage services;
- a provider of service-specific endpoints;
- a baseline for later authorization and networking troubleshooting.

## Learning Method

**Topic → Build → Observe → Diagnose → Verify**

No controlled storage failure was introduced in this phase. The goal was to establish a clean baseline first.

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

## Storage Account Created

```text
Storage Account: stazsl05npx01
Resource Group:  rg-azsl-01
Region:          Austria East
Kind:            StorageV2
Performance:     Standard
Redundancy:      LRS
Access tier:     Hot
```

The account name was checked before creation:

```powershell
az storage account check-name --name stazsl05npx01
```

Result:

```text
"nameAvailable": true
```

---

## Portal Configuration Baseline

The Storage Account was created deliberately through Azure Portal.

### Basics

```text
Primary service: Azure Blob Storage or Azure Data Lake Storage
Performance:     Standard
Redundancy:      Locally-redundant storage (LRS)
```

### Advanced

```text
Hierarchical namespace: Disabled
SFTP:                   Disabled
NFS v3:                 Disabled
Cross-tenant replication: Disabled
Access tier:            Hot
Managed Identity for SMB: Disabled
Encryption in transit for SMB: Enabled
```

Hierarchical namespace, SFTP, and NFS were intentionally left disabled to keep the baseline simple.

### Networking

```text
Public network access:        Enabled
Public network access scope:  Enabled from all networks
Private endpoint:             None
Routing preference:           Microsoft network routing
```

No firewall restriction or Private Endpoint was introduced in Phase 1. Those controls are reserved for later networking troubleshooting.

### Data protection

```text
Point-in-time restore:          Disabled
Soft delete for blobs:          Enabled, 7 days
Soft delete for containers:     Enabled, 7 days
Blob versioning:                Disabled
Blob change feed:               Disabled
Version-level immutability:     Disabled
Azure Files soft delete:        Enabled, 7 days
```

### Security

```text
Secure transfer required:                    Enabled
Anonymous access on individual containers:   Disabled
Storage account key access:                  Enabled
Default to Microsoft Entra authorization:    Disabled
Minimum TLS version:                         TLS 1.2
Permitted scope for copy operations:         From any storage account
```

Shared Key access was intentionally left enabled because later phases will compare Microsoft Entra authorization, account keys, and SAS-based access.

### Encryption

```text
Encryption type:              Microsoft-managed keys
Customer-managed key support: Blobs and files only
Infrastructure encryption:   Disabled
```

Customer-managed keys were not introduced in this phase to avoid unnecessary Key Vault, RBAC, and key-lifecycle dependencies.

---

## Azure CLI Verification

The Storage Account was inspected through Azure CLI from PowerShell.

```powershell
az storage account show `
  --name stazsl05npx01 `
  --resource-group rg-azsl-01 `
  --query '{name:name,location:location,kind:kind,sku:sku.name,provisioningState:provisioningState,accessTier:accessTier,publicNetworkAccess:publicNetworkAccess,allowBlobPublicAccess:allowBlobPublicAccess,allowSharedKeyAccess:allowSharedKeyAccess,minimumTlsVersion:minimumTlsVersion,supportsHttpsTrafficOnly:enableHttpsTrafficOnly,hierarchicalNamespace:isHnsEnabled}' `
  --output json
```

Observed baseline:

```json
{
  "accessTier": "Hot",
  "allowBlobPublicAccess": false,
  "allowSharedKeyAccess": true,
  "hierarchicalNamespace": null,
  "kind": "StorageV2",
  "location": "austriaeast",
  "minimumTlsVersion": "TLS1_2",
  "name": "stazsl05npx01",
  "provisioningState": "Succeeded",
  "publicNetworkAccess": "Enabled",
  "sku": "Standard_LRS",
  "supportsHttpsTrafficOnly": true
}
```

Important observations:

- `StorageV2` confirms a general-purpose v2 account.
- `Standard_LRS` combines the performance tier and redundancy selection.
- `allowBlobPublicAccess: false` confirms that anonymous Blob access is disabled.
- `allowSharedKeyAccess: true` confirms that Shared Key authorization is available.
- `TLS1_2` and HTTPS-only behavior confirm the secure transport baseline.
- `hierarchicalNamespace: null` was observed with HNS disabled.

---

## Service Endpoints

The account exposes separate endpoints for different storage services.

```powershell
az storage account show `
  --name stazsl05npx01 `
  --resource-group rg-azsl-01 `
  --query 'primaryEndpoints' `
  --output json
```

Observed endpoints:

```text
Blob  → https://stazsl05npx01.blob.core.windows.net/
DFS   → https://stazsl05npx01.dfs.core.windows.net/
File  → https://stazsl05npx01.file.core.windows.net/
Queue → https://stazsl05npx01.queue.core.windows.net/
Table → https://stazsl05npx01.table.core.windows.net/
Web   → https://stazsl05npx01.z49.web.core.windows.net/
```

The endpoint itself is not a credential. Secrets such as account keys, connection strings, and SAS tokens must not be committed or shared.

### Mental model

```text
Storage Account
├── Blob endpoint
├── File endpoint
├── Queue endpoint
├── Table endpoint
├── DFS endpoint
└── Web endpoint
```

A working Storage Account does not guarantee successful data access. A request can still fail because of:

```text
Wrong service endpoint
        ↓
Network path denied
        ↓
Authentication failure
        ↓
Authorization failure
        ↓
Missing container / object
```

This becomes the troubleshooting model for later phases.

---

## Blob Service Child Resource

Azure Portal showed service-level child resources created with the Storage Account, including:

```text
Microsoft.Storage/storageAccounts/blobServices
Microsoft.Storage/storageAccounts/fileServices
```

No Blob Container or Azure File Share was created in Phase 1.

### Initial CLI inspection issue

A generic nested-resource query was attempted:

```powershell
az resource show `
  --resource-group rg-azsl-01 `
  --resource-type "Microsoft.Storage/storageAccounts/blobServices" `
  --name "stazsl05npx01/default" `
  --output json
```

It returned:

```text
HttpResourceNotFound
```

The generated ARM request path omitted the `blobServices` segment and effectively addressed:

```text
.../storageAccounts/stazsl05npx01/default
```

instead of the correct nested hierarchy:

```text
.../storageAccounts/stazsl05npx01/blobServices/default
```

The failure was therefore an addressing problem in the generic ARM-resource command, not evidence that the Blob service was missing.

### Correct Blob service inspection

The specialized Storage command was then used:

```powershell
az storage account blob-service-properties show `
  --account-name stazsl05npx01 `
  --resource-group rg-azsl-01 `
  --output json
```

Observed resource identity:

```text
Type: Microsoft.Storage/storageAccounts/blobServices
Name: default
SKU:  Standard_LRS
```

Correct ARM hierarchy:

```text
Storage Account: stazsl05npx01
└── blobServices
    └── default
```

The resource ID confirmed:

```text
.../storageAccounts/stazsl05npx01/blobServices/default
```

Observed Blob service properties:

```text
Container soft delete:
  enabled: true
  days: 7

Blob soft delete:
  enabled: true
  days: 7
  allowPermanentDelete: false

Static website:
  enabled: false

CORS:
  no rules configured
```

---

## Troubleshooting Finding

A useful support lesson emerged during baseline inspection:

```text
HttpResourceNotFound
        ↓
Do not immediately conclude that the resource is absent
        ↓
Inspect the actual ARM request path
        ↓
Check nested-resource hierarchy
        ↓
Use the service-specific Azure CLI command when available
```

Another CLI finding occurred when a multiline JMESPath object was passed to `--query` from PowerShell. Azure CLI received only `{` and returned:

```text
argument --query: invalid jmespath_type value: '{'
```

The query worked when passed as one single-quoted expression.

This was a PowerShell/Azure CLI argument-parsing issue, not an Azure Storage failure.

---

## Phase 1 Architecture Summary

```text
Azure Resource Group: rg-azsl-01
└── Storage Account: stazsl05npx01
    ├── Kind: StorageV2
    ├── SKU: Standard_LRS
    ├── Access tier: Hot
    ├── Public network access: Enabled
    ├── Anonymous Blob access: Disabled
    ├── Shared Key access: Enabled
    ├── Secure transfer: Required
    ├── Minimum TLS: 1.2
    ├── Encryption: Microsoft-managed keys
    │
    ├── Blob service: default
    │   ├── Blob soft delete: 7 days
    │   ├── Container soft delete: 7 days
    │   ├── Static website: Disabled
    │   └── CORS rules: none
    │
    ├── File service: default
    ├── Queue endpoint
    ├── Table endpoint
    ├── DFS endpoint
    └── Web endpoint
```

---

## Verification Checkpoint

Phase 1 is complete because:

- the Storage Account was successfully created;
- account name uniqueness was verified before deployment;
- `StorageV2`, Standard performance, LRS redundancy, and Hot access tier were confirmed;
- Portal and Azure CLI views were compared;
- network, security, data-protection, and encryption baselines were inspected;
- service-specific endpoints were identified;
- the Blob service child resource and its ARM hierarchy were inspected;
- Blob and container soft-delete settings were verified;
- no Blob Container or File Share was created yet;
- the retained VM and networking baseline remained unchanged;
- a real nested-resource CLI inspection failure was diagnosed without changing Azure configuration.

---

## Next

**Phase 2 — Blob Storage & Data Access**

Planned next steps:

- create a Blob Container;
- upload minimal test data;
- inspect container and blob hierarchy;
- understand Blob URLs;
- compare Portal and Azure CLI data access;
- begin comparing Microsoft Entra authorization, Shared Key, and SAS access methods.
