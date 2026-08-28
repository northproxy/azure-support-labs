# Lab 02 — Azure Compute & Administration
## Phase 2 — VM Lifecycle & Configuration Administration

Status: **completed**

## Purpose

Practice Azure virtual machine lifecycle management and basic compute configuration administration using Azure CLI, while observing the same state changes in Azure Portal.

This phase focuses on:

- VM runtime states;
- the difference between provisioning state and power state;
- start, stop, and deallocate operations;
- the difference between `Stopped` and `Deallocated`;
- VM size inspection;
- VM resize options;
- temporary resize to another SKU;
- verification after resize;
- restoring the original VM configuration.

---

## Starting baseline

The retained VM from Lab 01 entered this phase with:

```text
VM name:             vm-azsl-01
VM size:             Standard_B2ats_v2
OS type:             Linux
Provisioning state:  Succeeded
Power state:         VM deallocated
```

The VM was intentionally left deallocated before lifecycle and configuration exercises.

---

# Part 1 — VM Lifecycle Administration

## Step 1 — Start the VM

Command:

```powershell
az vm start `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01
```

Verification:

```powershell
az vm get-instance-view `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "instanceView.statuses[].displayStatus" `
  --output table
```

Observed result:

```text
Provisioning succeeded
VM running
```

State transition:

```text
Deallocated
    ↓
Running
```

---

## Step 2 — Stop the VM

Command:

```powershell
az vm stop `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01
```

Verification:

```powershell
az vm get-instance-view `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "instanceView.statuses[].displayStatus" `
  --output table
```

Observed result:

```text
Provisioning succeeded
VM stopped
```

State transition:

```text
Running
    ↓
Stopped
```

---

## Step 3 — Deallocate the VM

Command:

```powershell
az vm deallocate `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01
```

Verification:

```powershell
az vm get-instance-view `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "instanceView.statuses[].displayStatus" `
  --output table
```

Observed result:

```text
Provisioning succeeded
VM deallocated
```

Full tested lifecycle:

```text
Deallocated
    ↓ az vm start
Running
    ↓ az vm stop
Stopped
    ↓ az vm deallocate
Deallocated
```

---

## Understanding VM power states

### Running

```text
VM running
```

The VM is powered on and the guest operating system is active.

Simplified model:

```text
CPU capacity   → allocated
RAM capacity   → allocated
Guest OS       → running
Compute state  → active
```

The VM is able to run workloads and accept connections according to its network and guest configuration.

### Stopped

```text
VM stopped
```

The guest operating system is stopped, but the VM has not yet been deallocated.

Simplified model:

```text
CPU/RAM allocation → still retained
Guest OS           → stopped
VM resource        → still exists
```

Important:

```text
Stopped != Deallocated
```

Stopping the guest does not necessarily release the allocated Azure compute capacity.

### Deallocated

```text
VM deallocated
```

The VM is stopped and its allocated compute capacity is released.

Simplified model:

```text
CPU capacity   → released
RAM capacity   → released
Guest OS       → stopped
VM resource    → retained
OS disk        → retained
NIC            → retained
Network config → retained
```

The VM configuration remains in Azure and can later be started again.

---

## Provisioning state vs power state

Throughout the lifecycle exercise, Azure continued to report:

```text
Provisioning succeeded
```

while the power state changed between:

```text
VM running
VM stopped
VM deallocated
```

This confirms that provisioning state and runtime power state describe different aspects of the VM.

### Provisioning state

Describes whether Azure successfully created or updated the resource configuration.

Example:

```text
ProvisioningState = Succeeded
```

### Power state

Describes the current runtime state of the VM.

Examples:

```text
VM running
VM stopped
VM deallocated
```

---

## Azure Portal observation

The VM state changes were observed in Azure Portal while the lifecycle operations were performed through Azure CLI.

Observed behavior:

```text
CLI operation          Azure Portal state
--------------------   -------------------------
az vm start            Running
az vm stop             Stopped
az vm deallocate       Stopped (deallocated)
```

This demonstrated that Azure Portal and Azure CLI are different administration interfaces operating against the same Azure resource state.

Simplified model:

```text
Azure Portal ─┐
Azure CLI    ─┼─→ Azure control plane / ARM ─→ VM resource
PowerShell   ─┤
ARM/Bicep    ─┘
```

---

# Part 2 — VM Configuration Administration

## Step 1 — Inspect current VM size

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "hardwareProfile.vmSize" `
  --output tsv
```

Observed result:

```text
Standard_B2ats_v2
```

This was recorded as the original compute configuration baseline.

---

## Step 2 — List available resize options

Command:

```powershell
az vm list-vm-resize-options `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --output table
```

The full command returned a large list.

A filtered query was then used to inspect B-series options:

```powershell
az vm list-vm-resize-options `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "[?starts_with(name, 'Standard_B')].{Name:name, vCPUs:numberOfCores, MemoryMB:memoryInMB}" `
  --output table
```

Relevant available sizes included:

```text
Standard_B2ts_v2    2 vCPU   1024 MB
Standard_B2als_v2   2 vCPU   4096 MB
Standard_B2as_v2    2 vCPU   8192 MB
Standard_B2s_v2     2 vCPU   8192 MB
```

Current size:

```text
Standard_B2ats_v2
2 vCPU
1024 MB RAM
```

Selected temporary resize target:

```text
Standard_B2als_v2
2 vCPU
4096 MB RAM
```

The exercise therefore changed memory capacity while keeping the vCPU count unchanged.

---

## Step 3 — Inspect the target VM SKU

The initial command used was:

```powershell
az vm list-sizes `
  --location austriaeast `
  --query "[?name=='Standard_B2als_v2']" `
  --output table
```

Azure CLI returned a deprecation warning indicating that `az vm list-sizes` should be replaced by:

```text
az vm list-skus
```

Observed target SKU properties:

```text
Name:                  Standard_B2als_v2
NumberOfCores:         2
MemoryInMB:            4096
MaxDataDiskCount:      4
ResourceDiskSizeInMB:  0
```

For future work, the preferred command is:

```powershell
az vm list-skus `
  --location austriaeast `
  --resource-type virtualMachines `
  --size Standard_B2als_v2 `
  --output table
```

---

## Step 4 — Resize the VM

The VM was deallocated before the configuration change.

Command:

```powershell
az vm resize `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --size Standard_B2als_v2
```

Verification:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "hardwareProfile.vmSize" `
  --output tsv
```

Observed result:

```text
Standard_B2als_v2
```

---

## Step 5 — Verify size and runtime state

Command:

```powershell
az vm get-instance-view `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "{size:hardwareProfile.vmSize,statuses:instanceView.statuses[].displayStatus}" `
  --output json
```

Observed result:

```json
{
  "size": "Standard_B2als_v2",
  "statuses": [
    "Provisioning succeeded",
    "VM deallocated"
  ]
}
```

This confirmed that the VM hardware profile had changed while the runtime state remained deallocated.

Azure Portal showed the same updated VM size.

---

## Step 6 — Start the VM on the new size

Command:

```powershell
az vm start `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01
```

Verification confirmed:

```text
Provisioning succeeded
VM running
```

The VM therefore successfully booted using:

```text
Standard_B2als_v2
```

This completed the resize validation.

---

# Part 3 — Restore the Original Baseline

After validating the temporary resize, the VM was returned to its original size.

## Stop and deallocate

Commands:

```powershell
az vm stop `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01

az vm deallocate `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01
```

## Resize back to the original SKU

Command:

```powershell
az vm resize `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --size Standard_B2ats_v2
```

Final verification:

```powershell
az vm get-instance-view `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "{size:hardwareProfile.vmSize,statuses:instanceView.statuses[].displayStatus}" `
  --output json
```

Observed final result:

```json
{
  "size": "Standard_B2ats_v2",
  "statuses": [
    "Provisioning succeeded",
    "VM deallocated"
  ]
}
```

---

# Final baseline

The environment was returned to:

```text
VM name:             vm-azsl-01
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
```

The temporary configuration change was fully reversed.

---

# Phase 2 Checkpoint

## VM lifecycle

```text
[✓] Started VM through Azure CLI
[✓] Verified VM running state
[✓] Stopped VM through Azure CLI
[✓] Verified VM stopped state
[✓] Deallocated VM through Azure CLI
[✓] Verified VM deallocated state
[✓] Distinguished Stopped from Deallocated
[✓] Distinguished provisioning state from power state
[✓] Observed lifecycle changes in Azure Portal
```

## VM configuration administration

```text
[✓] Inspected current VM size
[✓] Listed VM-specific resize options
[✓] Filtered a large CLI result with JMESPath
[✓] Inspected a candidate B-series SKU
[✓] Identified deprecated az vm list-sizes usage
[✓] Resized VM to Standard_B2als_v2
[✓] Verified the changed hardware profile
[✓] Started VM successfully on the new size
[✓] Observed the size change in Azure Portal
[✓] Returned VM to Standard_B2ats_v2
[✓] Returned VM to deallocated state
```

Phase 2 is complete.

---

# Key learning points

```text
Running      = guest OS active, compute allocated
Stopped      = guest OS stopped, compute not yet deallocated
Deallocated  = guest OS stopped, compute allocation released
```

Azure Portal and Azure CLI represent different interfaces to the same Azure resource state.

VM size is part of the VM hardware profile and can be administered independently of the persistent OS disk and network resources.

A configuration change should be verified separately from runtime state.

Temporary lab changes should be reversed when they are no longer required.

---

## Next phase

```text
Phase 3 — VM Storage Administration
```

The next phase will inspect the managed OS disk, its properties, SKU, size, and relationship to the VM before making any storage-related changes.
