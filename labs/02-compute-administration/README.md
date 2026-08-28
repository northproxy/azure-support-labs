# Lab 02 — Azure Compute & Administration

Status: **active**

## Purpose

Learn how Azure compute workloads are administered through Azure Portal and Azure CLI, then extend the same environment into PowerShell and ARM-based administration.

This lab reuses the retained infrastructure from Lab 01 and focuses on practical VM administration, configuration changes, storage administration, repeatable queries, and deployment methods.

---

## Learning objectives

- Manage the Azure VM lifecycle.
- Distinguish provisioning state from runtime power state.
- Understand the difference between `Stopped` and `Deallocated`.
- Inspect and modify VM compute configuration.
- Query VM properties with Azure CLI and JMESPath.
- Compare Azure Portal and Azure CLI as administration interfaces.
- Inspect and administer managed disks.
- Build toward Azure PowerShell and ARM-based administration.
- Understand App Service as a PaaS compute option.
- Practice basic deployment and configuration troubleshooting.

---

## Retained environment

The lab reuses the environment created in Lab 01.

```text
Resource Group: rg-azsl-01

rg-azsl-01
├── Virtual Machine
│   └── vm-azsl-01
├── Network Interface
│   └── vm-azsl-01284
├── Virtual Network
│   └── vnet-azsl-01
│       └── subnet-azsl-01
├── Network Security Group
│   └── nsg-azsl-01
├── Public IP
│   └── vm-azsl-01-ip
├── Managed OS Disk
│   └── vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
└── SSH Public Key resource
    └── vm-azsl-01-key
```

Local SSH private key:

```text
vm-azsl-01-key.pem
```

The private key remains local and must not be committed to the repository.

---

## Current baseline

```text
VM name:             vm-azsl-01
VM size:             Standard_B2ats_v2
OS type:             Linux
Provisioning state:  Succeeded
Power state:         VM deallocated
Region:              austriaeast
```

The VM is intentionally left deallocated when compute capacity is not required.

---

## Execution flow

```text
Phase 1 — Prepare
    ↓
Phase 2 — VM Lifecycle & Configuration Administration
    ↓
Phase 3 — VM Storage Administration
    ↓
Phase 4 — Azure PowerShell Administration
    ↓
Phase 5 — ARM-based Deployment
    ↓
Phase 6 — App Service Fundamentals
    ↓
Cleanup / handoff
```

The lab is developed incrementally. Later phases are defined only when they are ready to be executed.

---

# Phase 1 — Prepare

Status: **completed**

Goals:

- verify Azure CLI;
- verify authentication and active subscription;
- verify the retained Resource Group;
- inventory retained resources;
- verify VM runtime state;
- record the VM configuration baseline.

Completed checks:

```text
[✓] Azure CLI verified
[✓] Azure subscription verified
[✓] rg-azsl-01 verified
[✓] Retained resource inventory verified
[✓] VM runtime state verified
[✓] VM configuration baseline recorded
```

Detailed notes:

```text
LAB02_PHASE1_PREPARE.md
```

---

# Phase 2 — VM Lifecycle & Configuration Administration

Status: **completed**

## VM lifecycle

The following lifecycle was tested through Azure CLI:

```text
Deallocated
    ↓ az vm start
Running
    ↓ az vm stop
Stopped
    ↓ az vm deallocate
Deallocated
```

Key distinction:

```text
Running      = guest OS active, compute allocated
Stopped      = guest OS stopped, compute not yet deallocated
Deallocated  = guest OS stopped, compute allocation released
```

Provisioning state remained:

```text
Provisioning succeeded
```

while runtime power state changed independently.

The same state transitions were observed in Azure Portal.

## VM configuration administration

Original VM size:

```text
Standard_B2ats_v2
2 vCPU
1024 MB RAM
```

Temporary resize target:

```text
Standard_B2als_v2
2 vCPU
4096 MB RAM
```

Tested configuration flow:

```text
Standard_B2ats_v2
    ↓ resize
Standard_B2als_v2
    ↓ start and verify
VM running
    ↓ stop and deallocate
VM deallocated
    ↓ resize back
Standard_B2ats_v2
```

The temporary resize was successfully verified and then reversed.

Final baseline:

```text
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
```

Detailed notes:

```text
LAB02_PHASE2_VM_LIFECYCLE_CONFIGURATION.md
```

---

# Phase 3 — VM Storage Administration

Status: **completed**

## Phase 3A — Storage Baseline / Inspection

Status: **completed**

The existing managed OS disk was inspected from both the VM configuration and the Managed Disk resource.

Verified baseline:

```text
OS disk:             vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
Disk size:           30 GiB
SKU:                 StandardSSD_LRS
OS type:             Linux
Caching:             ReadWrite
Create option:       FromImage
Delete option:       Delete
Provisioning state:  Succeeded
Disk state:          Reserved
Disk controller:     SCSI
Data disks:          none
```

The VM → Managed Disk relationship was verified through:

```text
storageProfile.osDisk.managedDisk.id
```

The reverse Managed Disk → VM relationship was verified through:

```text
managedBy
```

A key lifecycle distinction was confirmed:

```text
VM power state:  VM deallocated
Disk state:      Reserved
```

Deallocating the VM releases compute allocation but does not delete the persistent managed OS disk. The disk remains associated with the VM and retains its data.

The complete VM storage profile was also inspected and confirmed:

```json
"dataDisks": []
```

No storage configuration changes were made during Phase 3A.

Detailed notes:

```text
LAB02_PHASE3_VM_STORAGE_ADMINISTRATION.md
```

## Phase 3B — Managed Data Disk Administration

Status: **completed**

A temporary 4 GiB `StandardSSD_LRS` managed data disk was created and administered through its complete lifecycle:

```text
Create
    ↓
Inspect Unattached state
    ↓
Attach to vm-azsl-01
    ↓
Verify LUN / managedDisk.id / managedBy
    ↓
Start VM
    ↓
Inspect /dev/sdb from Linux
    ↓
Create GPT partition and ext4 filesystem
    ↓
Mount at /mnt/data
    ↓
Verify read/write
    ↓
Unmount
    ↓
Detach
    ↓
Verify Unattached state
    ↓
Delete
    ↓
Restore VM deallocated baseline
```

The temporary data disk was deleted after validation, and the VM was returned to its original storage baseline with no attached data disks.

---

# Phase 4 — Azure PowerShell Administration

Status: **completed**

## Phase 4A — Azure PowerShell Prepare

Status: **completed**

The local PowerShell and Azure PowerShell environment was inspected before performing administration actions.

Verified tooling:

```text
PowerShell:          5.1.26100.9168
PSEdition:           Desktop
Azure CLI:           2.89.1
Az package:          16.2.0
Az.Accounts:         available
```

The `Az` package was already installed under the current user's PowerShell module path. The `Connect-AzAccount` cmdlet was resolved from `Az.Accounts`, confirming that the Azure PowerShell account module was available to the session.

Azure authentication and subscription context were then verified:

```text
Azure login:         successful
Subscription:        Azure subscription 1
Tenant:              Default Directory
```

The retained Resource Group was queried successfully through Azure PowerShell:

```text
Resource Group:       rg-azsl-01
Location:             austriaeast
Provisioning state:   Succeeded
```

The existing VM was also inspected through Azure PowerShell. Runtime status verification confirmed the expected baseline:

```text
VM:                  vm-azsl-01
Provisioning state:  Succeeded
Power state:         VM deallocated
OS disk:             vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
```

The distinction between VM provisioning state and runtime power state was therefore confirmed again through Azure PowerShell:

```text
ProvisioningState/succeeded
PowerState/deallocated
```

No Azure resource configuration changes were made during Phase 4A.

Detailed notes:

```text
LAB02_PHASE4_AZURE_POWERSHELL_ADMINISTRATION.md
```

## Phase 4B — VM Administration with Azure PowerShell

Status: **completed**

Completed administration work:

```text
[✓] VM configuration inspection
[✓] VM lifecycle administration
[✓] Stop-AzVM behavior verification
[✓] Stop-AzVM -StayProvisioned behavior verification
[✓] VM resize to Standard_B2als_v2
[✓] VM resize rollback to Standard_B2ats_v2
[✓] Managed OS disk inspection with Get-AzDisk
[✓] NIC and network dependency inspection
```

The lifecycle difference between Azure CLI and Azure PowerShell was verified practically:

```text
Azure CLI:
az vm stop        → Stopped
az vm deallocate  → Deallocated

Azure PowerShell:
Stop-AzVM -StayProvisioned → Stopped
Stop-AzVM                  → Deallocated
```

The temporary resize was successfully reversed, and the VM was returned to the intended baseline:

```text
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:          none
```

Detailed notes:

```text
LAB02_PHASE4_AZURE_POWERSHELL_ADMINISTRATION.md
```

---

# Phase 5 — ARM-based Deployment

Status: **completed**

## Phase 5A — ARM Template Fundamentals / Prepare

Status: **completed**

Completed fundamentals:

```text
[✓] ARM mental model
[✓] Imperative vs declarative administration
[✓] ARM template structure
[✓] Parameters and default values
[✓] Resource declarations
[✓] Resource Provider namespace and resource type
[✓] apiVersion
[✓] Dependencies
[✓] Resource Group deployment scope
[✓] ARM expressions and template functions
```

A temporary Storage Account was selected as the first controlled ARM deployment target.

## Phase 5B — First Controlled ARM Deployment

Status: **completed**

A parameterized ARM template was validated and deployed to `rg-azsl-01`.

Created temporary resource:

```text
Resource type:        Microsoft.Storage/storageAccounts
Name:                 stazslarm01284
Location:             austriaeast
Kind:                 StorageV2
SKU:                  Standard_LRS
Provisioning state:   Succeeded
```

Deployment records were inspected through Azure CLI and Azure Portal.

The distinction between deployment state and resource state was verified:

```text
Microsoft.Resources/deployments
≠
Microsoft.Storage/storageAccounts
```

The same desired state was redeployed successfully without creating a duplicate Storage Account.

The existing resource was then updated through ARM by setting:

```text
minimumTlsVersion = TLS1_2
```

## Phase 5C — Parameters & Repeatability

Status: **completed**

`minimumTlsVersion` was parameterized.

Both explicit parameter input and `defaultValue` behavior were verified:

```text
parameter supplied
→ supplied value used

parameter omitted
→ defaultValue used
```

## Phase 5D — Controlled Failure / Troubleshooting

Status: **completed**

A controlled validation failure was introduced with:

```text
TLS9_9
```

while the template allowed only:

```text
TLS1_0
TLS1_1
TLS1_2
TLS1_3
```

ARM returned:

```text
InvalidTemplate
```

The parameter constraint was diagnosed, corrected, and validation recovery was confirmed with:

```text
error: null
```

## Phase 5E — Cleanup / Documentation

Status: **completed**

The temporary Storage Account was removed.

The VM baseline remained unchanged:

```text
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:          none
```

Detailed notes:

```text
LAB02_PHASE5_ARM_BASED_DEPLOYMENT.md
```

---

# Phase 6 — App Service Fundamentals

Status: **completed**

## Phase 6A — Concepts / Prepare

Status: **completed**

The Resource Group initially contained no `Microsoft.Web/*` resources.

The `Microsoft.Web` Resource Provider was initially `NotRegistered`, then registered and verified as:

```text
Registered
```

Core resource types:

```text
Microsoft.Web/serverfarms  → App Service Plan
Microsoft.Web/sites        → Web App
```

## Phase 6B — First Controlled Deployment

Status: **completed**

A temporary Linux App Service Plan was created:

```text
Name:       asp-azsl-01
Location:   Austria East
SKU:        F1
Tier:       Free
Capacity:   1
```

A temporary Python Web App was created:

```text
Name:       web-azsl-01
Runtime:    Python 3.12
State:      Running
```

## Phase 6C — App Service Plan vs Web App

Status: **completed**

The Web App dependency on the plan was verified through:

```text
serverFarmId
```

```text
Microsoft.Web/sites/web-azsl-01
    ↓ serverFarmId
Microsoft.Web/serverfarms/asp-azsl-01
```

Key distinction:

```text
App Service Plan
→ compute capacity, region, OS family, SKU, tier

Web App
→ application runtime and application configuration
```

## Phase 6D — Runtime & Application Deployment

Status: **completed**

A minimal Flask application was packaged and deployed through `az webapp deploy`.

Build automation:

```text
SCM_DO_BUILD_DURING_DEPLOYMENT = true
```

Deployment result:

```text
RuntimeSuccessful
numberOfInstancesSuccessful: 1
numberOfInstancesFailed: 0
errors: null
```

The application was successfully verified through its public HTTPS endpoint.

## Phase 6E — Runtime & Application Configuration

Status: **completed**

An application setting was introduced:

```text
APP_MESSAGE = Azure Support Labs - configuration updated!
```

The Python application consumed the setting as an environment variable.

This verified that App Service configuration can change application behavior independently of source code.

## Phase 6F — Scaling Fundamentals

Status: **completed**

Baseline:

```text
SKU:       F1
Tier:      Free
Capacity:  1
```

Scaling model:

```text
Scale up / down
→ change App Service Plan SKU / capabilities

Scale out / in
→ change the number of application instances
```

No paid scaling operation was performed.

## Phase 6G — Controlled Failure / Troubleshooting

Status: **completed**

A controlled startup failure was introduced with:

```text
gunicorn missingmodule:app
```

Observed symptom:

```text
HTTP 503
```

Logs identified:

```text
ModuleNotFoundError: No module named 'missingmodule'
Worker failed to boot
ContainerStartupFailure
Site startup probe failed
```

The prior deployment itself remained successful, proving:

```text
Deployment successful
≠
Application runtime healthy
```

The invalid startup command was removed and the Web App recovered successfully.

## Phase 6 Cleanup

Status: **completed**

Deleted temporary resources:

```text
Web App:           web-azsl-01
App Service Plan:  asp-azsl-01
```

Final verification:

```text
Microsoft.Web/*: none
```

The retained VM baseline remained unchanged.

Detailed notes:

```text
LAB02_PHASE6_APP_SERVICE_FUNDAMENTALS.md
```

## Administration interfaces

This lab progressively compares several Azure administration methods:

```text
Azure Portal
Azure CLI
Azure PowerShell
Azure Resource Manager / ARM templates
```

A key observation from the completed phases is that Portal and CLI expose and modify the same Azure resource state through the Azure control plane.

---

## Cost safety

- Keep the VM deallocated when compute is not required.
- Avoid unnecessary size increases.
- Return temporary configuration changes to the intended baseline.
- Delete temporary resources when they are no longer required.
- Do not assume that stopping a guest OS is equivalent to Azure deallocation.

---

## Security

Do not commit:

- SSH private keys;
- credentials;
- secrets;
- subscription identifiers when unnecessary;
- tenant-sensitive information;
- billing information;
- unreviewed private screenshots.

The local file:

```text
vm-azsl-01-key.pem
```

must remain outside version control.

---

## Files

```text
02-compute-administration/
├── README.md
├── LAB02_PHASE1_PREPARE.md
├── LAB02_PHASE2_VM_LIFECYCLE_CONFIGURATION.md
├── LAB02_PHASE3_VM_STORAGE_ADMINISTRATION.md
├── LAB02_PHASE4_AZURE_POWERSHELL_ADMINISTRATION.md
├── LAB02_PHASE5_ARM_BASED_DEPLOYMENT.md
├── LAB02_PHASE6_APP_SERVICE_FUNDAMENTALS.md
├── app-service-demo/
│   ├── app.py
│   └── requirements.txt
├── templateStorage.json
└── parameters.json
```

Additional files are added only when their corresponding phase is executed.

---

## Current progress

```text
[✓] Phase 1 — Prepare
[✓] Phase 2 — VM Lifecycle & Configuration Administration
[✓] Phase 3 — VM Storage Administration
    [✓] Phase 3A — Storage Baseline / Inspection
    [✓] Phase 3B — Managed Data Disk Administration
[✓] Phase 4 — Azure PowerShell Administration
    [✓] Phase 4A — Azure PowerShell Prepare
    [✓] Phase 4B — VM Administration with Azure PowerShell
[✓] Phase 5 — ARM-based Deployment
    [✓] Phase 5A — ARM Template Fundamentals / Prepare
    [✓] Phase 5B — First Controlled ARM Deployment
    [✓] Phase 5C — Parameters & Repeatability
    [✓] Phase 5D — Controlled Failure / Troubleshooting
    [✓] Phase 5E — Cleanup / Documentation
[✓] Phase 6 — App Service Fundamentals
    [✓] Phase 6A — Concepts / Prepare
    [✓] Phase 6B — First Controlled Deployment
    [✓] Phase 6C — App Service Plan vs Web App
    [✓] Phase 6D — Runtime & Application Deployment
    [✓] Phase 6E — Runtime & Application Configuration
    [✓] Phase 6F — Scaling Fundamentals
    [✓] Phase 6G — Controlled Failure / Troubleshooting
    [✓] Cleanup
```

Current lab state:

```text
Lab 02 — active
VM — Standard_B2ats_v2
Power state — VM deallocated
OS disk — 30 GiB StandardSSD_LRS
Data disks — none
Phase 5 — completed
Phase 6 — completed
Temporary ARM Storage Account — removed
Temporary App Service Plan — removed
Temporary Web App — removed
Microsoft.Web/* — none
Next — Cleanup / handoff
```
