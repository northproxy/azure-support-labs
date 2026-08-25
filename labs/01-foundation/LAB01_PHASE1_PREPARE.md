# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 1 Prepare

Status: **completed**

This file documents the completed preparation phase for Lab 01.

The lab contract and full execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 1. Prepare

Status: **completed**

## Goal

Confirm the working context before creating Azure resources.

The purpose of this phase is to make sure the subscription, region, quota, naming, expected resource inventory, cost baseline, and cleanup intention are understood before deployment begins.

---

## 1.1 Confirm the Azure subscription

The Azure subscription selected for Lab 01 is:

```text
Subscription: Azure subscription 1
Status: Active
Role: Owner
Current resources: none
```

The subscription is active and the current role is sufficient to create and delete the resources required for Lab 01.

Do not record full subscription IDs in public project documentation.

### Checkpoint

You should be able to answer:

- Which subscription is being used?
- Is it active?
- Is it intended for temporary learning resources?
- Do you have permission to create and delete resources?

Confirmed:

```text
Subscription: Azure subscription 1
Status: Active
Role: Owner
```

---

## 1.2 Choose one Azure region

The selected region for Lab 01 is:

```text
Region: Austria East
```

The core Lab 01 resources should use the same region unless Azure requires otherwise.

The learning goal is consistency, not comparing Azure regions.

### Compute preparation checks

Verified:

```text
Microsoft.Compute resource provider: Registered
Standard Bsv2 Family quota: available
Current Bsv2 usage: 0
Bsv2 quota limit: 4 vCPUs
```

This quota is sufficient for the planned small B-series / Bsv2 virtual machine.

---

## 1.3 Confirm the naming pattern

Use recognizable project-oriented names.

Confirmed naming pattern:

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VNet:           vnet-azsl-01
NSG:            nsg-azsl-01
```

Naming logic:

```text
rg    = Resource Group
vm    = Virtual Machine
vnet  = Virtual Network
nsg   = Network Security Group
azsl  = Azure Support Labs
01    = Lab 01
```

Azure-created dependent resources may use generated or automatically derived names.

Do not spend time perfecting naming conventions in Lab 01.

The goal is recognizability.

---

## 1.4 Predict the resource inventory

Before deployment, predict what should exist after creating one basic Linux VM.

Expected Lab 01 resource inventory:

```text
Resource Group
├── Virtual Network
│   └── Subnet
├── Network Security Group
├── Network Interface
├── Linux Virtual Machine
├── Managed OS Disk
└── Public IP          [only if direct SSH is used]
```

### Important distinctions

- Resource Group is the management and lifecycle boundary for the lab resources.
- VNet is a top-level Azure resource.
- Subnet is a configuration / child object within the VNet.
- NIC is a top-level Azure resource and is the VM network attachment point.
- Managed OS Disk is a separate Azure resource.
- NSG is a separate Azure resource.
- Public IP is a separate Azure resource and is optional.
- Linux VM is a separate compute resource.

Prediction summary:

```text
RG, VNet, Subnet, NSG, NIC, Linux VM, Managed OS Disk,
optional Public IP for direct SSH.
```

This prediction will be compared with the actual Azure resource inventory after deployment.

---

## 1.5 Predict the dependency model

Before Build, the expected logical relationship is:

```text
Azure Subscription
└── Resource Group
    ├── Virtual Network
    │   └── Subnet
    │
    ├── Network Security Group
    │
    ├── Public IP                    [if used]
    │
    ├── Network Interface
    │   └── IP configuration
    │       ├── Private IP
    │       ├── Subnet reference
    │       └── Public IP reference  [if used]
    │
    ├── Managed OS Disk
    │
    └── Virtual Machine
        ├── NIC reference
        └── OS Disk reference
```

This is a prediction, not yet a verified map.

The actual relationships will be inspected after deployment.

---

## 1.6 Cost check

Before deployment:

- confirm that a low-cost VM size will be used;
- avoid unnecessary additional disks;
- avoid optional paid services;
- plan to stop or delete resources when the lab is not actively being used.

Budget alerts are useful but do not automatically stop Azure resources.

Confirmed Azure credit state:

```text
2026.08.23 - Subscription 'Azure subscription 1' has a remaining credit of €175.72.
```

Verified cost baseline:

```text
Subscription status: Active
Current cost: $0
Free trial credit: $200 confirmed on Azure signup screen
Remaining credit observed in Azure Portal: €175.72
Monthly budget: $50
Budget scope: Subscription
Budget alerts: 50% / 80% / 100% of actual cost
Region: Austria East
Compute quota: available
Lab resources: none
```

### Deployment cost rules

- Use a low-cost B-series / Bsv2 VM size.
- Use only the OS disk required for the VM.
- Do not add unnecessary data disks.
- Do not enable optional paid services in Lab 01.
- Create a Public IP only if direct SSH is intentionally used.
- Stop/deallocate the VM when it is not actively needed.
- Delete the Lab 01 Resource Group unless the environment is immediately reused by Lab 02.
- Remember that a budget alert does not automatically stop Azure resources or charges.

---

## 1.7 Cleanup intention

The default cleanup plan is:

```text
Delete the complete Lab 01 Resource Group
unless the environment is immediately reused by Lab 02.
```

The Resource Group is intentionally used as the lifecycle boundary for the temporary lab environment.

This allows the full workload to be removed as one unit after the learning objectives are complete.

---

## Phase checkpoint

Prepare is complete when you can explain:

```text
Subscription
  ↓
Resource Group
  ↓
Resources
```

Confirmed for Lab 01:

```text
Target subscription: Azure subscription 1
Target region: Austria East
Compute quota: checked
Naming pattern: confirmed
Expected resources: predicted
Expected dependencies: predicted
Cost safety: checked
Cleanup intention: defined
```

You should now be able to explain:

- why the subscription matters;
- why the Resource Group is useful as a lifecycle boundary;
- which resources are expected around a VM;
- why subnet is not the same type of object as VM, NIC, VNet, or NSG;
- why cost and cleanup decisions should be made before deployment.

---

# Phase 1 Result

Preparation is complete.

The environment is ready for deployment.

Next phase:

```text
Prepare
  ↓
Build
```

Proceed to **Phase 2 — Build** only while the preparation assumptions above remain valid.
