# Lab 01 — Azure Foundation & Resource Lifecycle — Execution

Status: **active**

This file is the working execution guide for Lab 01.

The lab contract and scope are defined in `README.md`.

Execution flow:

```text
Prepare
  ↓
Build
  ↓
Inspect
  ↓
Map
  ↓
Observe
  ↓
Lifecycle
  ↓
Cleanup
```

Do not move to the next phase until the current phase makes sense.

---

# 1. Prepare

Status: **completed**

## Goal

Confirm the working context before creating Azure resources.

## Actions

### 1.1 Confirm the Azure subscription

Identify the Azure subscription that will contain the lab.

You should be able to answer:

- Which subscription am I using?
- Is this the intended subscription for temporary learning resources?
- Do I have permission to create and delete resources?

Do not record full subscription IDs in public documentation.

Verified for Lab 01:

```text
Subscription: Azure subscription 1
Status: Active
Role: Owner
Current resources: none
```

The subscription is active and the current role is sufficient to create and delete Lab 01 resources.

### 1.2 Choose one Azure region

Choose one region for the Lab 01 resources unless Azure requires otherwise.

Record only the region name in your notes.

Selected region:

```text
Region: Austria East
```

Preparation checks completed:

```text
Microsoft.Compute resource provider: Registered
Standard Bsv2 Family quota: available
Current Bsv2 usage: 0
Bsv2 quota limit: 4 vCPUs
```

The learning goal is consistency, not comparing regions.

### 1.3 Confirm the naming pattern

Use recognizable project-oriented names.

Confirmed:

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

### 1.4 Predict the resource inventory

Before deployment, write down what you expect to exist after creating a basic Linux VM.

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

Important distinctions:

- Resource Group is the management and lifecycle boundary for the lab resources.
- VNet is a top-level Azure resource.
- Subnet is a configuration / child object within a VNet rather than a separate top-level resource in the same sense as a VM.
- NIC is a top-level Azure resource and is the VM's network attachment point.
- Managed OS Disk is a separate Azure resource.
- NSG is a separate Azure resource.
- Public IP is a separate Azure resource and is optional for Lab 01.
- Linux VM is a separate compute resource.

Prediction summary:

```text
RG, VNet, Subnet, NSG, NIC, Linux VM, Managed OS Disk, optional Public IP for direct SSH.
```

This prediction will be compared with the actual Azure resource inventory later.

### 1.5 Cost check

Before deployment:

- confirm that a low-cost VM size will be used;
- avoid unnecessary additional disks;
- avoid optional paid services;
- plan to stop or delete resources when the lab is not actively being used.

Budget alerts are useful but do not automatically stop Azure resources.

```text
2026.08.23 - Subscription 'Azure subscription 1' has a remaining credit of €175.72.
```

Verified cost baseline:

```text
Subscription status: Active
Current cost: $0```
Free trial credit: $200 confirmed on Azure signup screen
Monthly budget: $50
Budget scope: Subscription
Budget alerts: 50% / 80% / 100% of actual cost
Region: Austria East
Compute quota: available
Lab resources: none
```

Deployment cost rules:

- Use a low-cost B-series / Bsv2 VM size.
- Use only the OS disk required for the VM.
- Do not add unnecessary data disks.
- Do not enable optional paid services in Lab 01.
- Create a Public IP only if direct SSH is intentionally used.
- Stop/deallocate the VM when it is not actively needed.
- Delete the Lab 01 Resource Group unless the environment is immediately reused by Lab 02.
- Remember that a budget alert does not automatically stop Azure resources or charges.

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
Naming pattern: confirmed
Expected resources: predicted
Cost safety: checked
Cleanup intention: delete the Lab 01 Resource Group unless immediately reused by Lab 02
```

Do not begin Build until these preparation checks remain valid.

# 2. Build

## Goal

Create one small Azure IaaS workload and observe what Azure creates around a VM.

## Build target

Create:

1. One Resource Group.
2. One Linux Virtual Machine.
3. One Virtual Network.
4. One Subnet.
5. One Network Security Group.
6. One Network Interface.
7. One managed OS disk.
8. One Public IP only if direct SSH connectivity is used.

Prefer using the Azure Portal for the first deployment so the resource relationships remain visible.

Azure CLI is used later for inspection.

## While building

Do not treat the VM deployment screen as only a form to complete.

Pay attention to:

- Resource Group;
- region;
- VM size;
- authentication method;
- VNet;
- subnet;
- Public IP choice;
- NSG / inbound port configuration;
- OS disk;
- final validation summary.

If Azure creates dependent resources automatically, allow that when appropriate.

The goal is not to manually create every object.

The goal is to understand every object that exists afterward.

## Initial verification

After deployment:

- confirm deployment succeeded;
- confirm the VM resource exists;
- confirm the VM reaches a running state;
- do not modify networking yet.

## Phase checkpoint

Before continuing, answer:

- Did the deployment succeed?
- Is the VM resource present?
- Is the VM running?
- Which resources did I explicitly configure?
- Which resources did Azure create or connect as part of deployment?

Do not continue if any resource in the Resource Group is unexplained.

---

# 3. Inspect

## Goal

Build a complete resource inventory before thinking about troubleshooting.

## 3.1 Resource Group inventory

Open the Lab 01 Resource Group.

List all resources.

For each resource, identify:

- resource type;
- resource name;
- region/location where applicable;
- whether it is clearly chargeable;
- whether it is directly related to the VM workload.

Compare the actual list with the prediction from the Prepare phase.

Record only the differences that taught you something.

## 3.2 Inspect the Virtual Machine

Identify:

- VM name;
- VM size;
- power state;
- operating system;
- attached NIC;
- OS disk;
- Resource Group;
- region.

Understand the distinction:

```text
VM resource exists
≠
VM guest operating system is running
```

## 3.3 Inspect the Network Interface

Identify:

- which VM references the NIC;
- NIC private IP;
- IP configuration name;
- referenced subnet;
- Public IP reference, if present;
- NSG association or effective NSG influence.

The NIC is the central attachment point between the VM and the Azure virtual network.

## 3.4 Inspect the Virtual Network and Subnet

Identify:

- VNet address space;
- subnet address range;
- which NIC/IP configuration references the subnet.

Understand:

```text
VNet
└── Subnet
    └── NIC IP configuration
        └── VM network attachment
```

## 3.5 Inspect the Network Security Group

Identify:

- whether the NSG is associated with a NIC, subnet, or relevant traffic path;
- inbound rules;
- outbound rules;
- the rule that permits SSH if direct SSH is enabled.

Do not change the NSG in this phase.

## 3.6 Inspect the managed OS disk

Identify:

- disk name;
- disk type/SKU;
- size;
- relationship to the VM;
- whether the disk exists as its own Azure resource.

Understand that the disk is not merely a hidden file inside the VM resource.

## 3.7 Inspect a resource ID

Choose one top-level resource, such as the VM.

Locate its Azure resource ID.

Identify the logical segments:

```text
/subscriptions/<subscription>
/resourceGroups/<resource-group>
/providers/<provider-namespace>
/<resource-type>/<resource-name>
```

Do not memorize the ID.

Understand what it tells you.

## Phase checkpoint

You should now be able to identify every Lab 01 resource without relying on the VM creation wizard.

Do not continue until you can answer:

- What is the VM?
- What connects it to the network?
- Where does its private IP live?
- Where does the subnet live?
- What controls allowed network traffic?
- Where is the OS disk?
- Which objects are separate Azure resources?

---

# 4. Map

## Goal

Reconstruct the resource relationships from understanding rather than from the Portal resource list.

## Create the dependency map

Write a concise map in your lab notes.

Expected model:

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

## Explain the map

In your own words, explain:

1. Why the VM does not directly contain the VNet.
2. Why the NIC is central to VM networking.
3. Why the subnet is part of the VNet.
4. Where the private IP configuration belongs.
5. How the Public IP relates to the NIC.
6. How the managed disk relates to the VM.
7. How the NSG affects connectivity without becoming part of the guest OS.

## Resource versus configuration

Identify examples of each:

### Top-level Azure resources

Examples:

- VM
- NIC
- VNet
- NSG
- Public IP
- Managed Disk

### Configuration / nested object

Examples:

- subnet;
- NIC IP configuration;
- NSG rule.

The goal is not to learn every Azure resource-model nuance yet.

The goal is to stop thinking of every visible Portal item as the same type of object.

## Phase checkpoint

Close the Portal view or stop looking at the resource list.

Try to reconstruct the main resource graph from memory.

If you cannot explain the graph, return to Inspect.

---

# 5. Observe

## Goal

Observe the same workload through different Azure management surfaces and collect basic control-plane evidence.

## 5.1 Verify connectivity

If a Public IP and SSH access were configured:

- connect to the Linux VM with SSH;
- confirm the guest responds;
- disconnect normally.

Record only:

```text
SSH connectivity: verified
```

Do not store credentials or private key material.

If direct SSH was intentionally not configured, record that decision instead.

## 5.2 Compare Portal and Azure CLI

Use Azure CLI to inspect the same environment already understood in the Portal.

At minimum, inspect:

- Resource Group;
- resource list in the Resource Group;
- VM;
- Public IP if present.

The goal is to connect CLI output to known Azure objects.

For each query, identify a few useful properties rather than copying large JSON responses.

Useful examples:

- name;
- resource type;
- Resource Group;
- location;
- provisioning state;
- VM power-related information where appropriate;
- IP information where appropriate.

Detailed CLI administration belongs to Lab 02.

## 5.3 Inspect Activity Log

Open Activity Log for the relevant scope.

Find recent management operations associated with Lab 01.

Look for examples such as:

- Resource Group creation;
- VM deployment;
- network resource creation;
- resource updates.

For one or two operations, identify where available:

- operation name;
- timestamp;
- status;
- caller;
- affected resource.

Understand:

```text
Activity Log
= Azure control-plane operations
```

It is not the same as:

```text
Linux system logs
application logs
```

## 5.4 Record minimal evidence

Keep only useful evidence.

Recommended notes:

- final resource inventory;
- dependency map;
- one representative CLI observation;
- one Activity Log observation;
- verified connectivity state.

Avoid documenting every click.

## Phase checkpoint

You should be able to explain:

- why Portal and CLI show the same Azure resources;
- what Activity Log can tell a support engineer;
- what Activity Log cannot tell you about the Linux guest;
- whether the workload is currently usable.

---

# 6. Lifecycle

## Goal

Understand the difference between resource existence, runtime state, dependencies, and deletion.

This phase is primarily observational and reasoning-based.

Do not perform unnecessary destructive experiments.

## 6.1 VM runtime state

Observe the VM's current state.

Understand the distinction between:

```text
Running
Stopped
Deallocated
Deleted
```

At minimum, understand:

```text
stopping a workload
≠
deleting the Azure resource
```

## 6.2 Stop/deallocate observation

When appropriate, stop/deallocate the VM.

Then inspect:

- Does the VM resource still exist?
- Does the NIC still exist?
- Does the managed disk still exist?
- Does the VNet still exist?
- Does the Public IP resource still exist if one was created?
- Can you still inspect configuration in the Portal?

Start the VM again only if needed for the remaining Lab 01 work or immediate Lab 02 reuse.

## 6.3 Dependency reasoning

Without deleting resources individually, answer:

- What would happen to networking resources if only the VM resource were deleted?
- Would the VNet automatically disappear?
- Would the NIC necessarily disappear?
- Would the managed disk necessarily disappear?
- Why can Azure prevent deletion of a resource that is still referenced?
- Why should support engineers inspect dependencies before changing infrastructure?

Do not guess silently.

Use the Portal resource relationships and Azure documentation/help surfaces when needed.

## 6.4 Cost reasoning

Identify which lab resources deserve cost attention.

At minimum consider:

- VM compute;
- managed disks;
- Public IP depending on SKU/state;
- any optional service created accidentally.

Understand that:

```text
VM not actively used
```

does not automatically mean:

```text
all related Azure cost = zero
```

## 6.5 Decide persistence

Choose one of two paths.

### Path A — Lab 02 will follow immediately

Retain only resources that Lab 02 will reuse.

Document:

```text
Retained for Lab 02:
- ...
Reason:
- ...
```

Do not leave the VM running unnecessarily.

### Path B — Lab 02 will not follow immediately

Proceed to full cleanup.

## Phase checkpoint

Before cleanup, you should be able to explain:

- resource existence versus runtime state;
- why related resources have independent lifecycles;
- why dependency awareness matters before deletion;
- why Resource Group deletion is useful for temporary labs.

---

# 7. Cleanup

## Goal

End the Lab 01 resource lifecycle safely and verify the result.

## Full cleanup path

If resources are not being retained for immediate Lab 02 reuse:

1. Review the Resource Group one last time.
2. Confirm it contains only Lab 01 resources.
3. Delete the complete Lab 01 Resource Group.
4. Wait until deletion completes.
5. Verify the Resource Group no longer exists.
6. Check that the VM and related resources are gone.
7. Review Cost Management for unexpected remaining resources or costs.

Do not assume deletion succeeded only because the delete request was accepted.

## Retention path

If the base environment is retained for immediate Lab 02:

- document every retained resource;
- state why it is needed;
- stop/deallocate the VM when appropriate;
- delete any Lab 01-only resource not needed by Lab 02.

## Repository cleanup

Do not commit:

- passwords;
- SSH private keys;
- credentials;
- full subscription IDs unless sanitized and genuinely needed;
- billing data;
- raw private screenshots;
- tenant-sensitive identifiers.

Update documentation only with useful learning evidence.

## Final completion questions

Complete these in your own words:

- A Resource Group is:
- A VM depends on:
- The role of a NIC is:
- The relationship between VNet and Subnet is:
- The role of an NSG is:
- Public IP versus private IP:
- Managed OS disk versus VM resource:
- Resource existence versus VM runtime state:
- Activity Log is useful for:
- One dependency/lifecycle fact that surprised me:
- Resources retained for Lab 02, if any:

## Completion checklist

- [ ] Subscription, Resource Group, and resource hierarchy understood
- [ ] Lab resources created successfully
- [ ] Resource inventory inspected
- [ ] VM / NIC / IP / subnet / VNet relationship understood
- [ ] NSG role understood
- [ ] Managed OS disk relationship understood
- [ ] Resource ID inspected
- [ ] Portal and Azure CLI both used for inspection
- [ ] Activity Log inspected
- [ ] Working connectivity verified where applicable
- [ ] Runtime state versus resource existence understood
- [ ] Resource lifecycle/dependency reasoning completed
- [ ] Temporary resources deleted or explicitly retained for immediate Lab 02
- [ ] Cleanup verified
- [ ] `AZURE_MAP.md` updated only with topics actually studied or practiced
- [ ] `ROADMAP.md` updated when Lab 01 status changes

---

# Lab 01 Exit Condition

Lab 01 is complete only when you can reconstruct and explain this model without assistance:

```text
Subscription
└── Resource Group
    ├── VNet
    │   └── Subnet
    ├── NSG
    ├── Public IP [optional]
    ├── NIC
    │   └── IP configuration
    ├── Managed OS Disk
    └── VM
```

and explain how Azure Portal, Azure CLI, and Activity Log expose different views of the same managed environment.

Detailed administration, PowerShell, ARM deployments, advanced networking, identity, monitoring, storage accounts, backup, and controlled support incidents belong to later phases/labs.
