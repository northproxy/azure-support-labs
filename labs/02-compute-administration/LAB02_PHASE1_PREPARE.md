# Lab 02 — Azure Compute & Administration
## Phase 1 — Prepare

Status: **completed**

## Purpose

Prepare the retained Azure environment from Lab 01 for compute administration exercises.

This phase verifies that:

- Azure CLI is available and authenticated;
- the expected Azure subscription is active;
- the retained Resource Group is accessible;
- the retained Lab 01 resources still exist;
- the virtual machine runtime state is known;
- the VM configuration baseline is recorded before lifecycle changes begin.

---

## Retained environment

Resource Group:

```text
rg-azsl-01
```

Retained resources:

```text
rg-azsl-01
├── vm-azsl-01
├── vm-azsl-01284
├── vnet-azsl-01
│   └── subnet-azsl-01
├── nsg-azsl-01
├── vm-azsl-01-ip
├── vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
└── vm-azsl-01-key
```

Local SSH private key:

```text
vm-azsl-01-key.pem
```

The private key remains local and must not be committed to the repository.

---

## Step 1 — Verify Azure CLI and administrative context

### Azure CLI version

Command:

```powershell
az version
```

Observed result:

```text
azure-cli: 2.89.1
azure-cli-core: 2.89.1
azure-cli-telemetry: 1.1.0
extensions: none
```

Result:

```text
Azure CLI is installed and working.
```

### Active subscription

Command:

```powershell
az account show --output table
```

Observed result:

```text
Environment: AzureCloud
Default subscription: True
Subscription state: Enabled
Subscription name: Azure subscription 1
```

Result:

```text
Azure CLI is authenticated and the expected subscription is active.
```

### Resource Group availability

Command:

```powershell
az group show `
  --name rg-azsl-01 `
  --output table
```

Observed result:

```text
Location: austriaeast
Name: rg-azsl-01
```

Result:

```text
The retained Resource Group exists and is accessible.
```

---

## Step 2 — Verify retained resource inventory

Command:

```powershell
az resource list `
  --resource-group rg-azsl-01 `
  --output table
```

Observed resources:

| Resource | Type | Provisioning status |
|---|---|---|
| `vm-azsl-01-key` | `Microsoft.Compute/sshPublicKeys` | Succeeded |
| `nsg-azsl-01` | `Microsoft.Network/networkSecurityGroups` | Succeeded |
| `vm-azsl-01-ip` | `Microsoft.Network/publicIPAddresses` | Succeeded |
| `vnet-azsl-01` | `Microsoft.Network/virtualNetworks` | Succeeded |
| `vm-azsl-01284` | `Microsoft.Network/networkInterfaces` | Succeeded |
| `vm-azsl-01` | `Microsoft.Compute/virtualMachines` | Succeeded |
| `vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870` | `Microsoft.Compute/disks` | Succeeded |

### Important observation

`vm-azsl-01-key` is an Azure resource of type:

```text
Microsoft.Compute/sshPublicKeys
```

It represents the public SSH key resource in Azure.

It is different from the local private key file:

```text
vm-azsl-01-key.pem
```

The local private key must remain outside version control.

---

## Step 3 — Verify VM runtime state

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --show-details `
  --output table
```

Observed result:

```text
Name:          vm-azsl-01
ResourceGroup: rg-azsl-01
PowerState:    VM deallocated
Location:      austriaeast
Public IP:     assigned
```

### Interpretation

The VM currently has:

```text
PowerState = VM deallocated
```

This means the VM exists, but its compute resources are not currently allocated.

The Public IP still appears because it is a separate Azure resource associated with the VM networking configuration.

---

## Step 4 — Record the VM configuration baseline

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query '{name:name, vmSize:hardwareProfile.vmSize, provisioningState:provisioningState, osType:storageProfile.osDisk.osType, osDisk:storageProfile.osDisk.name, nic:networkProfile.networkInterfaces[0].id}' `
  --output json
```

Observed result:

```json
{
  "name": "vm-azsl-01",
  "nic": "/subscriptions/<subscription-id>/resourceGroups/rg-azsl-01/providers/Microsoft.Network/networkInterfaces/vm-azsl-01284",
  "osDisk": "vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870",
  "osType": "Linux",
  "provisioningState": "Succeeded",
  "vmSize": "Standard_B2ats_v2"
}
```

Baseline:

```text
VM name              vm-azsl-01
VM size              Standard_B2ats_v2
OS type              Linux
Provisioning state   Succeeded
Power state          VM deallocated
OS disk              vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
NIC                   vm-azsl-01284
```

---

## Provisioning state vs power state

These two states describe different things.

```text
ProvisioningState = Succeeded
PowerState        = VM deallocated
```

### Provisioning state

Describes whether Azure successfully created or updated the VM resource configuration.

```text
Succeeded
```

means the VM resource is correctly provisioned.

### Power state

Describes the current runtime state of the virtual machine.

```text
VM deallocated
```

means the VM is not currently consuming allocated compute capacity.

A VM can therefore be successfully provisioned while also being deallocated.

---

## Confirmed resource relationships

The baseline query confirms these compute dependencies:

```text
vm-azsl-01
├── NIC
│   └── vm-azsl-01284
└── OS Disk
    └── vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
```

These resources were created during Lab 01 and are intentionally reused for Lab 02.

---

## Phase 1 checkpoint

```text
[✓] Azure CLI verified
[✓] Azure authentication verified
[✓] Active subscription verified
[✓] Resource Group verified
[✓] Retained resources verified
[✓] VM runtime state verified
[✓] VM configuration baseline recorded
[✓] VM remains deallocated before lifecycle exercises
```

Phase 1 is complete.

---

## Next phase

```text
Phase 2 — VM Lifecycle
```

Planned lifecycle:

```text
Deallocated
    ↓
Start
    ↓
Running
    ↓
Stop
    ↓
Deallocate
```

The next phase will use the retained VM to practice Azure VM lifecycle administration and compare runtime state changes with resource provisioning state.
