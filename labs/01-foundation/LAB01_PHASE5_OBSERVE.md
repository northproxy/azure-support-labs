# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 5 Observe

Status: **completed**

This file documents the completed Observe phase for Lab 01.

The lab contract and full execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 5. Observe

Status: **completed**

## Goal

Observe the same Lab 01 workload through different Azure management and runtime surfaces and collect basic evidence from each layer.

The purpose of this phase is to connect:

```text
Azure Portal
Azure CLI
Azure Activity Log
SSH / Linux guest
```

to the same underlying workload while understanding that each surface answers different questions.

---

## 5.1 Verify connectivity

The VM was started and direct SSH connectivity was tested again as part of the Observe phase.

Verified:

```text
VM: vm-azsl-01
Guest OS: Ubuntu 24.04.4 LTS
Architecture: x86_64
SSH connectivity: verified
```

A successful SSH session confirmed that the workload was usable from the client side.

Observed path:

```text
Client
  ↓
Public IP
  ↓
NSG
  ↓
NIC
  ↓
vm-azsl-01
  ↓
Ubuntu SSH service
```

This verifies more than resource existence alone.

A successful SSH session requires:

```text
VM runtime state: running
Azure network path: reachable
NSG rule: permits SSH
Guest OS: running
SSH service: responding
```

No credentials, private key material, or public IP values are recorded in this file.

---

## 5.2 Compare Azure Portal and Azure CLI

Azure CLI was installed on the local Windows workstation and authenticated to the Azure subscription used by Lab 01.

The active CLI context confirmed:

```text
Subscription: Azure subscription 1
State: Enabled
Default subscription: Yes
```

### Resource Group inspection

Command:

```powershell
az group show --name rg-azsl-01 --output table
```

Observed:

```text
Resource Group: rg-azsl-01
Location: austriaeast
```

This matched the Resource Group already inspected through Azure Portal.

### Resource inventory inspection

Command:

```powershell
az resource list --resource-group rg-azsl-01 --output table
```

Azure CLI listed the same seven top-level resources identified earlier through the Portal:

```text
vm-azsl-01-key
nsg-azsl-01
vm-azsl-01-ip
vnet-azsl-01
vm-azsl-01284
vm-azsl-01
vm-azsl-01_OsDisk_1_...
```

Observed resource types included:

```text
Microsoft.Compute/sshPublicKeys
Microsoft.Network/networkSecurityGroups
Microsoft.Network/publicIPAddresses
Microsoft.Network/virtualNetworks
Microsoft.Network/networkInterfaces
Microsoft.Compute/virtualMachines
Microsoft.Compute/disks
```

This confirmed that Portal and Azure CLI expose the same Azure control-plane resources through different interfaces.

### VM inspection

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --show-details `
  --output table
```

Observed:

```text
VM: vm-azsl-01
Resource Group: rg-azsl-01
Power state: VM running
Location: austriaeast
```

The public IP value is intentionally omitted.

### Public IP inspection

Command:

```powershell
az network public-ip show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01-ip `
  --query "{Name:name, Allocation:publicIPAllocationMethod, SKU:sku.name, ProvisioningState:provisioningState}" `
  --output table
```

Observed:

```text
Name: vm-azsl-01-ip
Allocation: Static
SKU: Standard
Provisioning state: Succeeded
```

### Provisioning state versus power state

The CLI output demonstrated an important distinction:

```text
ProvisioningState: Succeeded
≠
PowerState: VM running
```

`ProvisioningState: Succeeded` describes successful Azure resource provisioning.

`PowerState: VM running` describes the current runtime state of the virtual machine.

This reinforces the earlier observation that:

```text
VM resource existence
≠
VM runtime state
```

---

## 5.3 Inspect Activity Log

The Activity Log for the Lab 01 scope was inspected.

A representative VM control-plane operation was identified:

```text
Operation: Start Virtual Machine
Timestamp: 2026-08-25 02:59:32 CEST
Status: Succeeded
Caller: <my-account>
Affected resource: vm-azsl-01
Resource type: Microsoft.Compute/virtualMachines
```

Sanitized Resource ID:

```text
/subscriptions/<subscription-id>
/resourceGroups/rg-azsl-01
/providers/Microsoft.Compute
/virtualMachines/vm-azsl-01
```

The event showed the familiar Resource ID hierarchy:

```text
Subscription
→ Resource Group
→ Resource Provider
→ Resource Type
→ Resource Name
```

The Activity Log entry also showed lifecycle stages for the start operation:

```text
Accepted
→ Started
→ Succeeded
```

This demonstrates that Azure Activity Log records management operations performed through the Azure control plane.

### Activity Log scope

Activity Log can provide evidence such as:

```text
Who initiated an Azure management operation
What operation was requested
Which Azure resource was affected
When the operation occurred
Whether the operation succeeded or failed
```

Activity Log does not provide guest operating-system details such as:

```text
Linux system logs
SSH authentication logs
systemd service logs
application logs
```

Those belong to a different diagnostic layer.

### Additional observed events

Other Activity Log events were visible, including:

```text
Get DDoS protection status for a Public IP Address
Check Backup Status for Vault
```

These were not selected as the primary Lab 01 evidence.

The `Get DDoS protection status for a Public IP Address` event was treated as a control-plane status/read operation rather than evidence that DDoS Protection was manually enabled.

The backup-related event was outside the intended Lab 01 scope and was not used to infer a backup configuration problem.

---

## 5.4 Correlate the evidence

The most useful result of the Observe phase is the correlation between different evidence sources.

```text
Azure Activity Log
Start Virtual Machine → Succeeded
        ↓
Azure CLI
PowerState → VM running
        ↓
SSH
Ubuntu guest → reachable
```

Each layer answers a different support question.

### Activity Log

```text
What management operation occurred?
Who initiated it?
Did Azure complete it successfully?
```

### Azure CLI / Portal

```text
What resources exist?
What is their current Azure configuration or state?
```

### SSH / guest OS

```text
Is the operating system actually responding?
Is the workload usable from the client path?
```

This distinction prevents incorrect assumptions such as:

```text
Azure operation succeeded
≠
guest application is necessarily healthy
```

and:

```text
VM resource exists
≠
VM is necessarily running or reachable
```

---

## 5.5 Minimal evidence retained

The following evidence is sufficient for Phase 5:

```text
SSH connectivity: verified

Azure CLI:
- rg-azsl-01 found in austriaeast
- same seven top-level resources as Portal
- vm-azsl-01 PowerState: VM running
- vm-azsl-01-ip: Static, Standard, Succeeded

Activity Log:
- Start Virtual Machine
- 2026-08-25 02:59:32 CEST
- Status: Succeeded
- Caller: <my-account>
- Resource: vm-azsl-01
```

Sensitive values are intentionally excluded.

---

## Phase checkpoint

Observe is complete because the following can now be explained:

### Why do Portal and CLI show the same resources?

Both are management interfaces over the same Azure control plane and resource model.

### What can Activity Log tell a support engineer?

It can show Azure management operations, timestamps, status, caller, and affected resources.

### What can Activity Log not tell us about the Linux guest?

It does not explain guest-level system, SSH, service, or application behavior.

### Is the workload currently usable?

Yes.

Verified:

```text
VM power state: running
SSH connectivity: verified
Ubuntu guest: responding
```

---

# Phase 5 Result

Observe is complete.

Verified learning outcomes:

```text
SSH connectivity: verified
Portal versus CLI resource view: understood
Azure CLI resource inspection: practiced
VM power state inspection through CLI: practiced
Public IP properties through CLI: practiced
Provisioning state versus power state: understood
Activity Log inspection: practiced
Control-plane versus guest-level evidence: understood
Evidence correlation across layers: understood
```

The main support-oriented model is now:

```text
Activity Log
→ what Azure control plane did

Portal / CLI
→ what Azure resources exist and their current state

SSH / guest
→ whether the operating system is actually reachable and responding
```

Next phase:

```text
Observe
  ↓
Lifecycle
```

Proceed to **Phase 6 — Lifecycle**.
