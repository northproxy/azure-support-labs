# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 2 Build

Status: **completed**

This file documents the completed Build phase for Lab 01.

The lab contract and full execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 2. Build

Status: **completed**

## Goal

Create one small Azure IaaS workload and observe what Azure creates around a VM.

The purpose of this phase is not only to deploy a VM, but to understand the main configuration choices, identify the dependent Azure resources, verify the workload reaches a running state, and confirm basic SSH connectivity.

---

## 2.1 Create the Resource Group

Created:

```text
Resource Group: rg-azsl-01
Region: Austria East
```

The Resource Group is the lifecycle boundary for the Lab 01 workload.

It will later allow the complete temporary environment to be reviewed and deleted as one unit.

---

## 2.2 Create the Linux Virtual Machine

Created:

```text
VM: vm-azsl-01
Region: Austria East
Image: Ubuntu Server 24.04 LTS
Architecture: x64
Size: Standard_B2ats_v2
Security type: Trusted launch virtual machines
Authentication: SSH public key
Admin username: azureuser
```

The selected VM size is a small B-series / Bsv2 option suitable for a low-cost learning workload.

The VM was created without unnecessary production-oriented features.

Disabled or not configured:

- Microsoft Entra ID login
- Backup
- Guest diagnostics
- Recommended alert rules
- Application health monitoring
- Extensions
- Hibernation
- Accelerated networking
- Load balancing

Boot diagnostics remained enabled.

---

## 2.3 Configure the managed OS disk

The VM uses one managed OS disk only.

Configured:

```text
OS disk type: StandardSSD_LRS
OS disk size: Image default
Delete option: Delete with VM
Additional data disks: none
Ephemeral OS disk: none
```

The disk configuration follows the Lab 01 cost rule:

```text
Use only the OS disk required for the VM.
```

The managed OS disk will later be inspected as a separate Azure resource.

---

## 2.4 Configure the Virtual Network and Subnet

Created:

```text
Virtual Network: vnet-azsl-01
VNet address space: 172.16.0.0/24

Subnet: subnet-azsl-01
Subnet address range: 172.16.0.0/24
```

Expected relationship:

```text
vnet-azsl-01
└── subnet-azsl-01
    └── VM NIC IP configuration
```

The subnet is part of the VNet rather than a separate top-level Azure resource in the same sense as the VM, NIC, or NSG.

---

## 2.5 Configure the Public IP

Direct SSH connectivity was intentionally used for Lab 01.

Created:

```text
Public IP: vm-azsl-01-ip
SKU: Standard
Allocation: Static
```

After deployment, the VM reported:

```text
Public IP: 68.210.102.95
```

The Public IP is a separate Azure resource.

It is referenced through the NIC IP configuration rather than existing inside the Linux guest operating system.

---

## 2.6 Configure the Network Interface

Azure created the NIC automatically during deployment.

Observed name:

```text
NIC: vm-azsl-01284
```

This name was generated automatically by Azure rather than explicitly chosen in the naming pattern.

After deployment, the NIC / VM network configuration showed:

```text
Private IP: 172.16.0.4
VNet: vnet-azsl-01
Subnet: subnet-azsl-01
Public IP: vm-azsl-01-ip
```

This confirmed that the NIC acts as the VM network attachment point.

---

## 2.7 Configure the Network Security Group

Created:

```text
NSG: nsg-azsl-01
```

During VM creation, the Azure Portal Preview wizard behaved inconsistently when configuring an SSH rule.

A deployment attempt failed because the generated security rule did not include a required source address value.

Observed failure category:

```text
Network Security Group rule validation failure
Missing SourceAddressPrefix / SourceAddressPrefixes / SourceApplicationSecurityGroups
```

Resolution:

1. Remove the manually configured SSH rule from the VM creation wizard.
2. Deploy the VM with no custom NSG rules.
3. Wait for deployment to complete.
4. Open the deployed `nsg-azsl-01` resource directly.
5. Add the SSH rule manually.

After successful deployment, the NSG initially contained:

```text
Custom inbound rules: 0
Custom outbound rules: 0
```

Only Azure default rules were present.

A restricted SSH rule was then added directly to the NSG:

```text
Name: allow-ssh-myip
Priority: 1000
Source: 84.115.231.124/32
Source port ranges: *
Destination: Any
Service: SSH
Destination port: 22
Protocol: TCP
Action: Allow
Description: Allow SSH from my current public IP
```

The standard Azure rule:

```text
DenyAllInBound
Priority: 65500
```

remains in place.

Result:

```text
SSH is allowed only from the configured public IPv4 address.
```

---

## 2.8 Review the generated deployment configuration

During troubleshooting, the generated ARM template and parameters were inspected.

The generated configuration confirmed important deployment details such as:

```text
Region: austriaeast
VM: vm-azsl-01
VM size: Standard_B2ats_v2
OS disk type: StandardSSD_LRS
VNet: vnet-azsl-01
Subnet: subnet-azsl-01
Public IP: vm-azsl-01-ip
NSG: nsg-azsl-01
```

The generated parameters also showed:

```text
networkSecurityGroupRules: []
```

for the successful no-custom-rule deployment path.

This helped confirm that the Portal summary and the generated deployment configuration were not always presenting the same state clearly.

Learning point:

```text
Portal wizard configuration
!=
final generated deployment configuration
```

Generated ARM templates can be useful evidence when a Portal wizard behaves unexpectedly.

Do not commit exported templates containing unsanitized subscription IDs.

---

## 2.9 Deploy the workload

Final deployment result:

```text
Deployment: successful
Resource Group: rg-azsl-01
VM: vm-azsl-01
```

The Azure deployment page reported:

```text
Your deployment is complete
```

The deployment created or connected the expected workload resources.

Observed resources included:

```text
vm-azsl-01        Virtual Machine
vm-azsl-01284     Network Interface
vm-azsl-01-ip     Public IP Address
nsg-azsl-01       Network Security Group
vnet-azsl-01      Virtual Network
Managed OS Disk   separate managed disk resource
```

The exact managed disk name will be recorded during the Inspect phase.

---

## 2.10 Verify VM state

After deployment, VM Overview confirmed:

```text
VM: vm-azsl-01
Status: Running
Resource Group: rg-azsl-01
Location: Austria East
OS: Ubuntu 24.04
Size: Standard B2ats v2
Public IP: 68.210.102.95
Private IP: 172.16.0.4
NIC: vm-azsl-01284
VNet/Subnet: vnet-azsl-01 / subnet-azsl-01
```

This confirmed:

```text
VM resource exists
and
VM guest is running
```

These are related but distinct states that will be explored further in the Lifecycle phase.

---

## 2.11 Verify SSH connectivity

SSH was tested from Windows PowerShell.

Command:

```powershell
ssh -i "R:\_labs\Azure-support-labs\notes\vm-azsl-01-key.pem" azureuser@68.210.102.95
```

The first connection attempt reached the Azure VM but failed locally because Windows OpenSSH rejected the private key file permissions.

Observed error:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions ... are too open.
```

The Windows ACL was corrected so broad groups such as:

```text
Authenticated Users
BUILTIN\Users
```

no longer had access to the private key.

After correcting the ACL, SSH succeeded and an Ubuntu terminal was reached.

Verified path:

```text
Windows SSH client
   ↓
Public Internet
   ↓
Azure Public IP
   ↓
nsg-azsl-01
   ↓
allow-ssh-myip
   ↓
NIC
   ↓
vm-azsl-01
   ↓
Ubuntu SSH service
```

Recorded result:

```text
SSH connectivity: verified
```

Do not commit the SSH private key to the repository.

---

## 2.12 Cost observation

During Build, Azure Portal showed an active remaining credit:

```text
2026.08.23 - Subscription 'Azure subscription 1' has a remaining credit of €175.72.
```

The workload uses:

- a small Bsv2 VM;
- one Standard SSD OS disk;
- one Public IP;
- no additional data disks;
- no optional monitoring, backup, load-balancing, or identity services.

Cost-safety rules remain:

- stop/deallocate the VM when it is not actively needed;
- do not add unnecessary services;
- delete the complete Lab 01 Resource Group when the environment is no longer required;
- remember that budget alerts do not automatically stop resources.

---

## 2.13 Resource prediction versus actual deployment

The Prepare phase predicted:

```text
Resource Group
├── Virtual Network
│   └── Subnet
├── Network Security Group
├── Network Interface
├── Linux Virtual Machine
├── Managed OS Disk
└── Public IP
```

The Build phase confirmed that this model is substantially correct.

One important observation:

```text
NIC name was generated automatically by Azure:
vm-azsl-01284
```

This illustrates that some resources can be created or named automatically by the Portal deployment workflow even when their role is still explicit in the architecture.

The exact full inventory will be recorded in Phase 3 — Inspect.

---

## Phase checkpoint

Build is complete when you can answer:

```text
Did the deployment succeed?
Yes.

Is the VM resource present?
Yes.

Is the VM running?
Yes.

Was direct SSH connectivity verified?
Yes.

Was the NSG inspected and configured?
Yes.

Which resources were explicitly configured?
Resource Group, VM, VNet, subnet, NSG, Public IP, OS disk settings.

Which resource was automatically created/named by Azure?
The Network Interface: vm-azsl-01284.
```

You should now be able to explain at a high level:

- why creating a VM creates or connects multiple Azure objects;
- why the NIC is central to VM networking;
- why the Public IP is separate from the VM;
- why NSG rules control the Azure network path rather than the Linux guest itself;
- why generated deployment configuration can help diagnose Portal wizard issues;
- why a successful network connection and a successful SSH key load are separate troubleshooting layers.

---

# Phase 2 Result

Build is complete.

The workload exists and is usable.

Current verified model:

```text
Subscription
└── rg-azsl-01
    ├── vnet-azsl-01
    │   └── subnet-azsl-01
    ├── nsg-azsl-01
    │   └── allow-ssh-myip
    ├── vm-azsl-01-ip
    ├── vm-azsl-01284
    ├── Managed OS Disk
    └── vm-azsl-01
```

Next phase:

```text
Build
  ↓
Inspect
```

Proceed to **Phase 3 — Inspect**.

The next goal is to build a complete resource inventory and inspect each relationship directly in Azure rather than relying on the VM creation wizard.
