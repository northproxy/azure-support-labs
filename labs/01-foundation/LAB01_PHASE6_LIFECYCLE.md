# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 6 Lifecycle

Status: **completed**

This file documents the completed Lifecycle phase for Lab 01.

The lab contract and full execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 6. Lifecycle

Status: **completed**

## Goal

Understand the difference between Azure resource existence, VM runtime state, resource dependencies, deletion behavior, and continuing cost.

The purpose of this phase is to reason about lifecycle safely without performing unnecessary destructive experiments.

---

## 6.1 Observe VM runtime state

The VM was first confirmed in a running state during Phase 5 and then stopped from Azure Portal.

Final observed VM state:

```text
VM: vm-azsl-01
State: Stopped (deallocated)
```

This confirmed the distinction:

```text
VM resource exists
≠
VM guest operating system is running
```

Deallocation stopped the VM runtime while preserving the Azure resource and its configuration.

---

## 6.2 Stop/deallocate observation

After the VM reached:

```text
Stopped (deallocated)
```

the Resource Group still contained the full Lab 01 environment:

```text
nsg-azsl-01
vm-azsl-01
vm-azsl-01-ip
vm-azsl-01-key
vm-azsl-01284
vm-azsl-01_OsDisk_1_...
vnet-azsl-01
```

The subnet also remained as configuration inside the VNet:

```text
vnet-azsl-01
└── subnet-azsl-01
```

This demonstrated:

```text
deallocate VM
≠
delete VM
≠
delete NIC
≠
delete Managed Disk
≠
delete VNet
≠
delete Public IP
≠
delete NSG
```

Observed result:

```text
VM resource:        exists
NIC:                exists
Managed OS Disk:    exists
VNet:               exists
Subnet:             exists
Public IP resource: exists
NSG:                exists
SSH Key:            exists

VM runtime:         stopped/deallocated
```

---

## 6.3 Dependency reasoning

No destructive dependency experiment was performed.

Reasoning was based on the relationships already verified during Inspect and Map.

### VM delete behavior

The VM JSON previously showed:

```text
OS disk deleteOption: Delete
NIC deleteOption:     Detach
```

For this specific VM configuration, deleting the VM would therefore be expected to have different effects on attached resources.

Expected behavior:

```text
Delete vm-azsl-01
├── VM → deleted
├── OS disk → configured to delete with VM
├── NIC → configured to detach
├── VNet → remains
├── NSG → remains
├── Public IP → remains unless separately configured for deletion
└── SSH Key → remains
```

The important principle is:

```text
resource dependency
≠
shared lifecycle
```

Resources can depend on or reference one another without necessarily being deleted together.

### Dependency constraints

Azure can block deletion of a resource when another resource still references it.

Example dependency chain:

```text
NIC IP configuration
→ references subnet
→ subnet belongs to VNet
```

This means dependency inspection should happen before infrastructure changes.

Support-oriented rule:

```text
Before delete/change:
1. inspect dependencies
2. understand references
3. predict impact
4. perform the change
5. verify the result
```

---

## 6.4 Cost reasoning

Azure Cost Management was inspected while the VM was deallocated.

Observed cost values:

```text
Current total observed cost: €0.18

vm-azsl-01-ip:       €0.11
Managed OS Disk:     €0.07
vm-azsl-01 compute:  €0.00
```

This provided direct evidence that:

```text
VM deallocated
≠
total lab cost = 0
```

The VM compute charge was shown as zero while deallocated, but independently billed resources still contributed cost.

Main cost-sensitive resources observed:

```text
Virtual Machine compute
Managed OS Disk
Standard Public IP
```

The lifecycle implication is:

```text
Stopping compute
does not remove
storage or Public IP resources
```

Therefore cost review must consider all resources in the workload, not only VM runtime state.

---

## 6.5 Decide persistence

Path selected:

```text
Path A — retain the base environment for Lab 02
```

Reason:

```text
The existing Lab 01 base environment will be reused immediately by Lab 02.
```

Retained resources:

```text
rg-azsl-01
vm-azsl-01
vm-azsl-01284
vnet-azsl-01
subnet-azsl-01
nsg-azsl-01
vm-azsl-01-ip
vm-azsl-01_OsDisk_1_...
vm-azsl-01-key
```

Current VM state:

```text
Stopped (deallocated)
```

This keeps the environment available for the next lab while avoiding unnecessary VM compute runtime.

The retained Managed Disk and Standard Public IP can still contribute cost and should remain under cost observation.

---

## Phase checkpoint

Lifecycle is complete because the following can now be explained:

### Resource existence versus runtime state

```text
A VM can exist as an Azure resource while being stopped/deallocated.
```

### Why related resources have independent lifecycles

```text
VM, NIC, disk, VNet, NSG, Public IP, and SSH Key are separate Azure resources or configurations with their own lifecycle behavior.
```

### Why dependencies matter before deletion

```text
Azure resources can reference one another, and Azure may block deletion when a reference is still active.
```

### Why stopping a VM does not eliminate all cost

```text
Managed disks and Public IP resources can remain billable even when VM compute is deallocated.
```

### Persistence decision

```text
The Lab 01 base environment is retained for immediate Lab 02 reuse.
The VM remains Stopped (deallocated).
```

---

# Phase 6 Result

Lifecycle is complete.

Verified learning outcomes:

```text
Running versus Stopped (deallocated): understood
VM runtime versus Azure resource existence: understood
Deallocation behavior: observed
Independent resource lifecycle: understood
Delete option differences: understood
Dependency-aware deletion reasoning: understood
Cost persistence after deallocation: observed
Persistence decision for Lab 02: completed
```

The main lifecycle model is now:

```text
Azure resource exists
        │
        ├── runtime state may change independently
        │
        ├── related resources may remain
        │
        ├── dependencies may constrain deletion
        │
        └── cost may continue on retained resources
```

Next phase:

```text
Lifecycle
  ↓
Cleanup
```

For this Lab 01 run, full Azure resource deletion is intentionally deferred because the environment is retained for immediate Lab 02 reuse.

The Cleanup phase should therefore document retention, confirm that the VM remains deallocated, and verify that no unnecessary Lab 01-only resources remain.
