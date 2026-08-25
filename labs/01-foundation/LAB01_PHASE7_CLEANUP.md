# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 7 Cleanup

Status: **completed**

This file documents the completed Cleanup phase for Lab 01.

The lab contract and full execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 7. Cleanup

Status: **completed**

## Goal

End the Lab 01 lifecycle safely and verify the intended final state.

For this run, the full Azure environment is intentionally retained because it will be reused immediately by Lab 02.

Therefore, Cleanup follows the retention path rather than deleting the complete Resource Group.

---

## 7.1 Cleanup path selected

Selected path:

```text
Retention path
```

Reason:

```text
The Lab 01 base environment will be reused immediately by Lab 02.
```

Full Resource Group deletion is intentionally deferred.

---

## 7.2 Verify VM runtime state

The VM was stopped and confirmed in:

```text
VM: vm-azsl-01
State: Stopped (deallocated)
```

This prevents unnecessary VM compute runtime while preserving the environment for follow-on work.

Verified:

```text
VM resource exists
VM compute runtime is deallocated
```

---

## 7.3 Verify retained resources

The retained Lab 01 environment is:

```text
rg-azsl-01
├── vm-azsl-01
├── vm-azsl-01284
├── vm-azsl-01_OsDisk_1_...
├── vnet-azsl-01
│   └── subnet-azsl-01
├── nsg-azsl-01
├── vm-azsl-01-ip
└── vm-azsl-01-key
```

All retained objects are known and were inspected during earlier phases.

No unexplained Lab 01 resource remains in the Resource Group.

---

## 7.4 Retention rationale

The following resources are retained for Lab 02:

```text
Resource Group
Virtual Machine
Network Interface
Managed OS Disk
Virtual Network
Subnet
Network Security Group
Public IP
SSH Key
```

Reason:

```text
Lab 02 — Azure Compute & Administration
will reuse the existing base workload and its dependencies.
```

The environment therefore remains available without rebuilding the foundation.

---

## 7.5 Cost-aware retained state

The VM remains:

```text
Stopped (deallocated)
```

This avoids unnecessary compute runtime.

However, Lifecycle observations already confirmed that some retained resources may continue to contribute cost:

```text
Managed OS Disk
Standard Public IP
```

Therefore the retained environment should continue to be monitored and should be deleted when it is no longer needed.

---

## 7.6 Repository cleanup and evidence policy

Lab 01 documentation retains only useful learning evidence.

Do not commit:

```text
SSH private keys
credentials
full subscription IDs
tenant-sensitive identifiers
billing details
raw private screenshots
unnecessary public IP values
```

Sanitized resource names, architecture relationships, CLI observations, and Activity Log evidence are sufficient for the lab record.

---

## 7.7 Final Lab 01 answers

### A Resource Group is:

```text
A management and lifecycle boundary that contains related Azure resources.
```

### A VM depends on:

```text
Compute configuration, a NIC for networking, and a managed OS disk.
Its network path also depends on subnet/VNet configuration, NSG rules,
and a Public IP when direct public connectivity is used.
```

### The role of a NIC is:

```text
To attach the VM to Azure networking and hold IP configuration references.
```

### The relationship between VNet and Subnet is:

```text
A subnet is a network configuration object inside a VNet.
```

### The role of an NSG is:

```text
To control allowed Azure network traffic using security rules.
```

### Public IP versus private IP:

```text
The private IP is a value in the NIC IP configuration.
The Public IP is a separate Azure resource referenced by that configuration.
```

### Managed OS disk versus VM resource:

```text
The managed OS disk is a separate Azure resource referenced by the VM.
Its lifecycle can differ from the VM runtime state.
```

### Resource existence versus VM runtime state:

```text
A VM resource can continue to exist while the VM is stopped/deallocated.
```

### Activity Log is useful for:

```text
Identifying Azure control-plane operations, including operation name,
time, status, caller, and affected resource.
```

### One dependency/lifecycle fact that was important:

```text
Resource dependency does not automatically mean shared lifecycle.
Related resources can remain after a VM is stopped or deleted,
depending on references and delete options.
```

### Resources retained for Lab 02:

```text
rg-azsl-01
vm-azsl-01
vm-azsl-01284
vm-azsl-01_OsDisk_1_...
vnet-azsl-01
subnet-azsl-01
nsg-azsl-01
vm-azsl-01-ip
vm-azsl-01-key
```

---

## Completion checklist

- [x] Subscription, Resource Group, and resource hierarchy understood
- [x] Lab resources created successfully
- [x] Resource inventory inspected
- [x] VM / NIC / IP / subnet / VNet relationship understood
- [x] NSG role understood
- [x] Managed OS disk relationship understood
- [x] Resource ID inspected
- [x] Portal and Azure CLI both used for inspection
- [x] Activity Log inspected
- [x] Working connectivity verified
- [x] Runtime state versus resource existence understood
- [x] Resource lifecycle/dependency reasoning completed
- [x] Temporary resources deleted or explicitly retained for immediate Lab 02
- [x] Retention state verified
- [x] Sensitive evidence excluded from repository documentation
- [x] Lab 01 documentation completed

---

# Phase 7 Result

Cleanup is complete using the retention path.

Final state:

```text
Lab 01: completed
Base environment: retained for Lab 02
VM: Stopped (deallocated)
Full Resource Group deletion: deferred
```

Lab 01 execution flow is complete:

```text
Prepare      ✓
Build        ✓
Inspect      ✓
Map          ✓
Observe      ✓
Lifecycle    ✓
Cleanup      ✓
```

Next:

```text
Lab 02 — Azure Compute & Administration
```
