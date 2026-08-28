# Lab 02 — Phase 4: Azure PowerShell Administration

Status: **active**

## Purpose

Administer the retained Azure VM environment through Azure PowerShell and compare the PowerShell administration model with the Azure CLI workflow used in earlier phases.

---

# Phase 4A — Azure PowerShell Prepare

Status: **completed**

## Goal

Verify the local PowerShell environment, Azure PowerShell modules, Azure authentication, active subscription context, and access to the retained Lab 02 resources before performing configuration changes.

## Starting baseline

```text
VM:         vm-azsl-01
VM size:    Standard_B2ats_v2
State:      deallocated
OS disk:    30 GiB StandardSSD_LRS
Data disks: none
```

## PowerShell environment

The local shell was verified with:

```powershell
$PSVersionTable
```

Observed environment:

```text
PSVersion:   5.1.26100.9168
PSEdition:   Desktop
```

Azure CLI was also confirmed to remain available:

```text
azure-cli: 2.89.1
```

## Azure PowerShell module inspection

The `Az` package was already installed through PowerShellGet:

```text
Az: 16.2.0
Installed location:
C:\Users\northproxy\Documents\WindowsPowerShell\Modules\Az\16.2.0
```

The current user's module directory was present in `$env:PSModulePath`.

`Connect-AzAccount` was resolved successfully from:

```text
Module:  Az.Accounts
Version: 5.5.2
```

This confirmed that the required Azure PowerShell account cmdlets were available.

## Authentication and Azure context

Authentication was performed with:

```powershell
Connect-AzAccount
```

The active context was verified with Azure PowerShell.

```text
Subscription: Azure subscription 1
Tenant:       Default Directory
```

## Resource Group verification

The retained Resource Group was queried with:

```powershell
Get-AzResourceGroup -Name rg-azsl-01
```

Verified state:

```text
ResourceGroupName:  rg-azsl-01
Location:           austriaeast
ProvisioningState:  Succeeded
```

## VM verification

The existing VM resource was inspected with:

```powershell
Get-AzVM -ResourceGroupName rg-azsl-01 -Name vm-azsl-01
```

The object exposed the expected VM configuration groups, including:

```text
HardwareProfile
NetworkProfile
SecurityProfile
OSProfile
StorageProfile
DiagnosticsProfile
```

Runtime status was then checked with:

```powershell
Get-AzVM `
    -ResourceGroupName rg-azsl-01 `
    -Name vm-azsl-01 `
    -Status
```

Verified VM state:

```text
ProvisioningState/succeeded
PowerState/deallocated
```

The OS disk reported a successful provisioning state and remained attached to the VM.

## Key observation

Azure PowerShell exposes the same Azure control-plane resource state already observed through Azure Portal and Azure CLI.

The VM again demonstrated that provisioning state and runtime power state are independent:

```text
Provisioning state:  Succeeded
Power state:         VM deallocated
```

## Changes made

None. Phase 4A was inspection and environment preparation only.

## Final checkpoint

```text
[✓] PowerShell verified
[✓] Azure CLI presence confirmed
[✓] Az package installation confirmed
[✓] Az.Accounts cmdlets available
[✓] Azure authentication completed
[✓] Subscription context verified
[✓] rg-azsl-01 verified through Azure PowerShell
[✓] vm-azsl-01 verified through Azure PowerShell
[✓] VM runtime state confirmed as deallocated
```

Current baseline remains unchanged:

```text
VM:                 vm-azsl-01
VM size:            Standard_B2ats_v2
Provisioning state: Succeeded
Power state:        VM deallocated
OS disk:            30 GiB StandardSSD_LRS
Data disks:         none
```

---

# Phase 4B — VM Administration with Azure PowerShell

Status: **completed**

## Goal

Use Azure PowerShell to inspect and administer the retained VM, validate lifecycle behavior, perform a controlled VM resize and rollback, and inspect storage and network dependencies.

## VM configuration inspection

The VM was loaded into a PowerShell object and key configuration properties were inspected.

Verified configuration:

```text
VM:                  vm-azsl-01
Location:            austriaeast
Provisioning state:  Succeeded
VM size:             Standard_B2ats_v2
```

The VM storage and network references were also inspected through:

```text
StorageProfile.OsDisk
NetworkProfile.NetworkInterfaces
```

This confirmed the existing OS disk and NIC relationships.

## VM lifecycle administration

The VM was started through Azure PowerShell and verified as:

```text
ProvisioningState/succeeded
PowerState/running
```

A standard stop operation was then tested:

```powershell
Stop-AzVM `
    -ResourceGroupName rg-azsl-01 `
    -Name vm-azsl-01
```

Result:

```text
PowerState/deallocated
```

The alternative `-StayProvisioned` behavior was also validated:

```powershell
Stop-AzVM `
    -ResourceGroupName rg-azsl-01 `
    -Name vm-azsl-01 `
    -StayProvisioned
```

Result:

```text
PowerState/stopped
```

The practical distinction was confirmed:

```text
Stop-AzVM
→ Deallocated

Stop-AzVM -StayProvisioned
→ Stopped
```

The VM was returned to the cost-safe baseline:

```text
PowerState/deallocated
```

## VM resize and rollback

Available VM sizes were queried with Azure PowerShell.

Original size:

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

The resize was performed by modifying the VM object and submitting it with `Update-AzVM`.

Verified flow:

```text
Standard_B2ats_v2
→ Standard_B2als_v2
→ Standard_B2ats_v2
```

The original VM size was restored successfully.

## Storage inspection

The managed OS disk was inspected with `Get-AzDisk`.

Verified baseline:

```text
Disk size:           30 GiB
Disk state:          Reserved
OS type:             Linux
Provisioning state:  Succeeded
SKU:                 StandardSSD_LRS
ManagedBy:           vm-azsl-01
```

This matched the storage baseline established in Phase 3.

## Network inspection

The VM NIC was inspected with `Get-AzNetworkInterface`.

Verified network relationships:

```text
NIC:                 vm-azsl-01284
Location:            austriaeast
Provisioning state:  Succeeded
Private IP:          confirmed
Subnet:              vnet-azsl-01/subnet-azsl-01
Public IP reference: vm-azsl-01-ip
NSG reference:       nsg-azsl-01
```

A warning about unapproved PowerShell verbs was observed while importing the networking cmdlets. It did not prevent the commands from loading or executing successfully.

## Key observations

Azure PowerShell exposed and modified the same Azure control-plane state previously administered through Azure CLI.

The most important workflow difference observed was:

```text
Azure CLI:
az vm stop        → Stopped
az vm deallocate  → Deallocated

Azure PowerShell:
Stop-AzVM -StayProvisioned → Stopped
Stop-AzVM                  → Deallocated
```

The VM resize workflow also demonstrated the object-oriented PowerShell administration model:

```text
Get resource object
→ modify object property
→ submit object with Update-AzVM
→ query Azure again to verify
```

## Final checkpoint

```text
[✓] VM configuration inspected
[✓] VM started through Azure PowerShell
[✓] Running state verified
[✓] Stop-AzVM deallocation behavior verified
[✓] Stop-AzVM -StayProvisioned behavior verified
[✓] VM returned to deallocated baseline
[✓] Available VM sizes inspected
[✓] Temporary resize completed
[✓] Original VM size restored
[✓] Managed OS disk inspected with Get-AzDisk
[✓] NIC and network references inspected
```

Final baseline:

```text
VM:                 vm-azsl-01
VM size:            Standard_B2ats_v2
Provisioning state: Succeeded
Power state:        VM deallocated
OS disk:            30 GiB StandardSSD_LRS
Data disks:         none
```

---

# Phase 4C — Next Step

Status: **next**

The next PowerShell administration block can extend the lab into repeatable resource queries or controlled resource administration before moving to ARM-based deployment.
