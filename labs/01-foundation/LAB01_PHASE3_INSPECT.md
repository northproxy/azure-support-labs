# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 3 Inspect

Status: **completed**

This file documents the completed Inspect phase for Lab 01.

The lab contract and full execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 3. Inspect

Status: **completed**

## Goal

Build a complete factual inventory of the Lab 01 workload and inspect the main resource relationships directly in Azure.

The purpose of this phase is to stop relying on assumptions from the VM creation wizard and instead verify the actual Azure resource model:

```text
VM → NIC → VNet/Subnet → NSG → Public IP → Managed Disk → Resource ID
```

The inspection was performed step by step.

The next object was not considered complete until the current object's role and relationships were understood.

---

## 3.1 Inspect the Resource Group inventory

Opened:

```text
Resource Group: rg-azsl-01
Region: Austria East
```

The Resource Group contained seven top-level resources:

```text
rg-azsl-01
├── nsg-azsl-01
├── vm-azsl-01
├── vm-azsl-01-ip
├── vm-azsl-01-key
├── vm-azsl-01284
├── vm-azsl-01_OsDisk_1_...
└── vnet-azsl-01
```

Observed resource types:

| Resource | Type | Direct workload relationship | Cost attention |
|---|---|---|---|
| `nsg-azsl-01` | Network Security Group | Controls traffic on the VM NIC path | Low / no direct standalone charge |
| `vm-azsl-01` | Virtual Machine | Main compute resource | Yes |
| `vm-azsl-01-ip` | Public IP Address | Public endpoint referenced by NIC IP configuration | Yes / depends on SKU and state |
| `vm-azsl-01-key` | SSH Key | Public SSH key resource created during VM deployment | No significant standalone cost |
| `vm-azsl-01284` | Network Interface | Connects VM to Azure networking | Low / no direct standalone charge |
| `vm-azsl-01_OsDisk_1_...` | Managed Disk | VM operating system disk | Yes |
| `vnet-azsl-01` | Virtual Network | Contains the VM subnet | Low / no direct standalone charge |

### Prediction versus actual inventory

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

The actual deployment matched this model substantially.

One additional top-level resource was discovered:

```text
vm-azsl-01-key
Type: SSH key
```

This resource was not included in the original inventory prediction.

### Subnet observation

`subnet-azsl-01` did not appear as a separate row in the Resource Group inventory.

This confirmed that the subnet is a configuration / child object inside the VNet rather than a separate top-level Azure resource in the same sense as the VM, NIC, NSG, Public IP, VNet, or Managed Disk.

### Cost attention

The three main Lab 01 resources requiring cost awareness are:

```text
Virtual Machine
Managed Disk
Public IP
```

---

## 3.2 Inspect the Virtual Machine

Inspected:

```text
VM: vm-azsl-01
```

Observed:

```text
VM name:        vm-azsl-01
Resource Group: rg-azsl-01
Location:       Austria East
Status:         Stopped (deallocated)
OS:             Linux
Image:          Ubuntu 24.04 LTS
Size:           Standard B2ats v2
vCPU:           2
RAM:            1 GiB
Architecture:   x64
Generation:     V2
Primary NIC:    vm-azsl-01284
Private IP:     172.16.0.4
Public IP:      68.210.102.95
VNet/Subnet:    vnet-azsl-01 / subnet-azsl-01
OS disk:        vm-azsl-01_OsDisk_1_...
Data disks:     0
Security type:  Trusted launch
Secure Boot:    Enabled
vTPM:           Enabled
```

### Resource existence versus runtime state

The VM existed as an Azure resource while its power state was:

```text
Stopped (deallocated)
```

This demonstrated:

```text
VM resource exists
≠
VM guest operating system is running
```

Deallocation releases VM compute capacity, but the VM resource, NIC, disk, network configuration, and other dependent resources remain visible and manageable.

### VM references

The VM references separate resources:

```text
vm-azsl-01
├── NIC reference → vm-azsl-01284
└── OS disk reference → vm-azsl-01_OsDisk_1_...
```

The NIC and OS disk are not hidden components inside the VM resource.

---

## 3.3 Inspect the Network Interface

Inspected:

```text
NIC: vm-azsl-01284
```

Observed:

```text
NIC:                    vm-azsl-01284
Resource Group:         rg-azsl-01
Location:               Austria East
Attached VM:            vm-azsl-01
Private IPv4:           172.16.0.4
Public IPv4:            68.210.102.95
Public IP resource:     vm-azsl-01-ip
VNet/Subnet:            vnet-azsl-01 / subnet-azsl-01
NSG:                    nsg-azsl-01
NIC type:               Regular
Accelerated networking: Disabled
Private IP allocation:  Dynamic
Public IP allocation:   Static
IP configuration count: 1
IP forwarding:          Disabled
```

The NIC is the central network attachment point for the VM.

Verified relationship:

```text
vm-azsl-01
  ↓ attached to
vm-azsl-01284
  ↓ IP configuration
ipconfig1
  ├── Private IP: 172.16.0.4
  ├── Subnet reference: subnet-azsl-01
  └── Public IP reference: vm-azsl-01-ip
```

### Private IP

The private IP:

```text
172.16.0.4
```

belongs to the NIC IP configuration rather than directly to the VM resource.

### NSG association

The NIC showed:

```text
Network Security Group:
nsg-azsl-01
```

This confirmed that the NSG is associated with the NIC in this lab.

---

## 3.4 Inspect the Virtual Network and Subnet

Inspected:

```text
VNet: vnet-azsl-01
Subnet: subnet-azsl-01
```

Observed VNet configuration:

```text
VNet:              vnet-azsl-01
Resource Group:    rg-azsl-01
Location:          Austria East
Address space:     172.16.0.0/24
Subnets:           1
Connected devices: 1
DNS:               Azure-provided DNS service
```

Observed subnet configuration:

```text
Subnet:         subnet-azsl-01
IPv4 range:     172.16.0.0/24
Available IPs:  250
Security group: none
Route table:    none
Delegation:     none
```

### Verified network hierarchy

Azure topology showed:

```text
vnet-azsl-01
└── subnet-azsl-01
    └── ipconfig1
        └── vm-azsl-01284
            └── vm-azsl-01
```

This confirmed that the NIC is connected to the subnet through its IP configuration.

### Subnet NSG association

The subnet showed no direct NSG association:

```text
Security group: none
```

Therefore:

```text
nsg-azsl-01
→ associated with NIC vm-azsl-01284

not

nsg-azsl-01
→ associated with subnet-azsl-01
```

---

## 3.5 Inspect the Network Security Group

Inspected:

```text
NSG: nsg-azsl-01
```

Observed:

```text
Resource Group: rg-azsl-01
Location: Austria East

Custom security rules:
- 1 inbound
- 0 outbound

Associations:
- 0 subnets
- 1 network interface
```

This confirmed again that the NSG is associated with the NIC.

### Custom inbound SSH rule

Observed:

```text
Name:        allow-ssh-myip
Priority:    1000
Protocol:    TCP
Source:      <current-public-ip>/32
Destination: Any
Port:        22
Action:      Allow
```

The `/32` source prefix represents one specific IPv4 address.

This means SSH is allowed only from the configured public client IP.

### Default inbound rules

Observed Azure default inbound rules:

```text
65000  AllowVnetInBound
65001  AllowAzureLoadBalancerInBound
65500  DenyAllInBound
```

Azure NSG priority processing uses the lower numeric value first.

Therefore:

```text
1000 allow-ssh-myip
```

is evaluated before:

```text
65500 DenyAllInBound
```

If traffic matches `allow-ssh-myip`, it is allowed before the default deny rule is reached.

### Default outbound rules

No custom outbound rules were configured.

Observed default outbound rules:

```text
65000  AllowVnetOutBound
65001  AllowInternetOutBound
65500  DenyAllOutBound
```

No NSG changes were made during Inspect.

### NSG role

The NSG controls the Azure network path.

It is not a firewall inside the Ubuntu guest operating system.

Verified path:

```text
Internet
   ↓
Public IP
   ↓
NIC vm-azsl-01284
   ↓
NSG nsg-azsl-01
   ↓
allow-ssh-myip
   ↓
VM vm-azsl-01
   ↓
Ubuntu SSH service
```

---

## 3.6 Inspect the Public IP

Inspected:

```text
Public IP: vm-azsl-01-ip
```

Observed:

```text
Public IP resource: vm-azsl-01-ip
Resource Group:     rg-azsl-01
Location:           Austria East
SKU:                Standard
Tier:               Regional
IP version:         IPv4
Allocation method:  Static
Provisioning state: Succeeded
DNS name:           not configured
Associated to:      vm-azsl-01284
Virtual machine:    vm-azsl-01
Routing preference: Microsoft network
```

The real public IP value is intentionally omitted from repository documentation.

### Public IP relationship

Verified:

```text
vm-azsl-01-ip
   ↓ associated to
vm-azsl-01284
   ↓ attached to
vm-azsl-01
```

The Public IP is a separate Azure resource.

It is not stored directly inside the VM.

### Static allocation

The allocation method is:

```text
Static
```

This means the assigned public IP remains associated with the Public IP resource during ordinary VM stop/start operations.

---

## 3.7 Inspect the managed OS disk

Inspected:

```text
Disk: vm-azsl-01_OsDisk_1_...
```

Observed:

```text
Resource Group: rg-azsl-01
Location:       Austria East
Disk state:     Reserved
Disk size:      30 GiB
Storage type:   Standard SSD LRS
Managed by:     vm-azsl-01
OS:             Linux
VM generation:  V2
Architecture:   x64
Provisioning:   Succeeded
Security type:  Trusted launch
Encryption:     Platform-managed key
IOPS:           500
Throughput:     100 MB/s
```

### Disk relationship

The OS disk is a separate Azure resource.

Verified:

```text
vm-azsl-01
   ↓ OS disk reference
vm-azsl-01_OsDisk_1_...
```

The field:

```text
Managed by: vm-azsl-01
```

shows the current relationship to the VM.

### Disk lifecycle observation

The VM was:

```text
Stopped (deallocated)
```

while the disk remained:

```text
Reserved
```

This demonstrated:

```text
VM runtime state
≠
Managed Disk resource lifecycle
```

Stopping or deallocating a VM does not remove its managed OS disk.

---

## 3.8 Inspect the VM Resource ID

The VM JSON view was inspected.

Sanitized VM Resource ID:

```text
/subscriptions/<subscription-id>
/resourceGroups/rg-azsl-01
/providers/Microsoft.Compute
/virtualMachines/vm-azsl-01
```

The logical segments are:

```text
/subscriptions/<subscription-id>
```

Identifies the Azure subscription containing the resource.

```text
/resourceGroups/rg-azsl-01
```

Identifies the Resource Group.

```text
/providers/Microsoft.Compute
```

Identifies the Azure resource provider namespace.

```text
/virtualMachines/vm-azsl-01
```

Identifies:

```text
Resource type: virtualMachines
Resource name: vm-azsl-01
```

The Resource ID can therefore be read as:

```text
Subscription
→ Resource Group
→ Resource Provider
→ Resource Type
→ Resource Name
```

### Resource name versus Resource ID

Resource name:

```text
vm-azsl-01
```

Full Resource ID:

```text
/subscriptions/<subscription-id>/resourceGroups/rg-azsl-01/providers/Microsoft.Compute/virtualMachines/vm-azsl-01
```

The VM JSON also contained a separate:

```text
vmId
```

This internal VM GUID is not the same as the Azure Resource ID.

### Resource provider namespaces

The VM and disk use:

```text
Microsoft.Compute
```

Examples:

```text
Microsoft.Compute/virtualMachines
Microsoft.Compute/disks
```

The NIC uses:

```text
Microsoft.Network
```

Example:

```text
Microsoft.Network/networkInterfaces
```

This demonstrates that one workload can depend on resources managed by different Azure resource providers.

### Resource references visible in VM JSON

The VM JSON contained a managed disk Resource ID:

```text
Microsoft.Compute/disks/...
```

and a NIC Resource ID:

```text
Microsoft.Network/networkInterfaces/vm-azsl-01284
```

This provided direct control-plane evidence that the VM references separate disk and network resources.

### Delete behavior observed in JSON

The VM JSON showed:

```text
OS disk deleteOption: Delete
NIC deleteOption:     Detach
```

This difference was recorded as a lifecycle observation.

It will be interpreted in more detail during the Lifecycle phase rather than changed during Inspect.

---

## 3.9 Sanitized evidence

Screenshots and JSON used as repository evidence were sanitized where appropriate.

Removed or obscured:

```text
Full subscription ID
Public administrative source IP
Public VM IP where unnecessary
Unneeded resource GUIDs
Full SSH public key material
```

Resource names, private IP ranges, regions, SKUs, network relationships, and other useful learning evidence were retained.

An annotated JSONC file was created to explain the VM JSON structure:

```text
vm-azsl-01_annotated.jsonc
```

It documents the meaning of:

- resource name;
- Resource ID;
- provider namespace;
- `vmId`;
- VM size;
- image reference;
- OS disk reference;
- NIC reference;
- SSH configuration;
- security configuration;
- diagnostics;
- delete options.

---

## 3.10 Final verified resource model

The actual inspected model is:

```text
Azure Subscription
└── rg-azsl-01
    ├── vnet-azsl-01
    │   └── subnet-azsl-01
    │       └── 172.16.0.0/24
    │
    ├── nsg-azsl-01
    │   └── associated with NIC vm-azsl-01284
    │       └── allow-ssh-myip
    │
    ├── vm-azsl-01-ip
    │   └── Static IPv4
    │
    ├── vm-azsl-01284
    │   └── ipconfig1
    │       ├── Private IP: 172.16.0.4
    │       ├── Subnet: subnet-azsl-01
    │       └── Public IP reference: vm-azsl-01-ip
    │
    ├── vm-azsl-01_OsDisk_1_...
    │   └── Standard SSD LRS
    │
    ├── vm-azsl-01-key
    │   └── SSH Key resource
    │
    └── vm-azsl-01
        ├── NIC reference: vm-azsl-01284
        └── OS disk reference: vm-azsl-01_OsDisk_1_...
```

---

## Phase checkpoint

Inspect is complete when the following questions can be answered.

### What is the VM?

```text
vm-azsl-01
```

It is the main compute resource for the Lab 01 workload.

### What connects the VM to the network?

```text
Network Interface: vm-azsl-01284
```

### Where does the private IP live?

```text
NIC IP configuration: ipconfig1
Private IP: 172.16.0.4
```

### Where does the subnet live?

```text
Inside vnet-azsl-01
```

### What controls allowed Azure network traffic?

```text
nsg-azsl-01
```

In this lab the NSG is associated with the NIC.

### Where is the OS disk?

It exists as a separate Managed Disk resource:

```text
vm-azsl-01_OsDisk_1_...
```

### Which objects are separate Azure resources?

```text
VM
NIC
VNet
NSG
Public IP
Managed Disk
SSH Key
```

The subnet, NIC IP configuration, and NSG rules are configuration / nested objects rather than separate top-level resources in the same sense.

### What does a Resource ID tell us?

It identifies:

```text
Subscription
→ Resource Group
→ Resource Provider
→ Resource Type
→ Resource Name
```

---

# Phase 3 Result

Inspect is complete.

The workload has been inspected directly through Azure resource properties rather than relying on the deployment wizard.

Verified learning outcomes:

```text
Resource inventory: understood
VM runtime state versus resource existence: understood
VM → NIC relationship: understood
NIC → IP configuration relationship: understood
NIC → subnet relationship: understood
VNet → subnet relationship: understood
NSG association: understood
Public IP relationship: understood
Managed Disk relationship: understood
Resource ID structure: understood
Resource provider namespaces: understood
```

Important findings:

```text
1. vm-azsl-01-key exists as an additional top-level SSH Key resource.
2. subnet-azsl-01 is a child/configuration object inside vnet-azsl-01.
3. Actual VNet address space is 172.16.0.0/24.
4. nsg-azsl-01 is associated with the NIC, not the subnet.
5. Private IP belongs to NIC IP configuration.
6. Public IP is a separate Azure resource referenced by the NIC.
7. Managed OS disk is a separate Azure resource.
8. Stopped (deallocated) does not mean deleted.
9. Microsoft.Compute and Microsoft.Network represent different resource provider namespaces.
10. VM JSON exposes direct Resource ID references to NIC and Managed Disk resources.
```

Next phase:

```text
Inspect
  ↓
Map
```

Proceed to **Phase 4 — Map**.
