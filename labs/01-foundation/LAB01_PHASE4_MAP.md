# Lab 01 — Azure Foundation & Resource Lifecycle — Phase 4 Map

Status: **completed**

This file documents the completed Map phase for Lab 01.

The lab contract and execution flow are defined in `README.md` and `EXECUTION.md`.

---

# 4. Map

Status: **completed**

## Goal

Reconstruct the Lab 01 dependency map from understanding rather than by relying on the Azure Portal resource list.

The map was rebuilt from the relationships verified during Phase 3 — Inspect.

---

## 4.1 Reconstructed dependency map

Main resource graph:

```text
Azure Subscription
└── Resource Group: rg-azsl-01
    ├── Virtual Machine: vm-azsl-01
    │   ├── NIC reference → vm-azsl-01284
    │   └── OS Disk reference → vm-azsl-01_OsDisk_1_...
    │
    ├── Network Interface: vm-azsl-01284
    │   ├── IP configuration: ipconfig1
    │   │   ├── Private IP: 172.16.0.4
    │   │   ├── Subnet reference → subnet-azsl-01
    │   │   └── Public IP reference → vm-azsl-01-ip
    │   └── NSG association → nsg-azsl-01
    │
    ├── Virtual Network: vnet-azsl-01
    │   └── Subnet: subnet-azsl-01
    │
    ├── Network Security Group: nsg-azsl-01
    │   └── associated with NIC vm-azsl-01284
    │
    ├── Public IP: vm-azsl-01-ip
    │
    ├── Managed OS Disk: vm-azsl-01_OsDisk_1_...
    │
    └── SSH Key: vm-azsl-01-key
        └── deployment/authentication-related resource
```

The SSH Key resource exists in the Resource Group, but it is not part of the main runtime dependency chain in the same way as the NIC or managed OS disk.

---

## 4.2 Main VM network dependency chain

The main network path can be reconstructed as:

```text
vm-azsl-01
→ vm-azsl-01284
→ ipconfig1
→ subnet-azsl-01
→ vnet-azsl-01
```

By object type:

```text
Virtual Machine resource
→ Network Interface resource
→ IP configuration
→ Subnet configuration
→ Virtual Network resource
```

This is the core dependency chain that must be understood without relying on the Portal resource list.

---

## 4.3 Why the VM does not directly contain the VNet

A VM does not directly contain or attach to a VNet.

The VM attaches to a NIC, and the NIC IP configuration references a subnet. The subnet exists inside the VNet.

```text
VM
└── NIC
    └── IP configuration
        └── Subnet
            └── VNet
```

Therefore, the VM reaches the VNet indirectly through its network interface and subnet reference.

---

## 4.4 Why the NIC is central to VM networking

The NIC is the central network attachment point because:

```text
VM
└── NIC
    ├── IP configuration
    │   ├── Private IP
    │   ├── Subnet reference
    │   └── Public IP reference
    └── NSG association
```

In this lab, the VM attaches to `vm-azsl-01284`, and that NIC carries the configuration and associations that connect the VM to Azure networking.

---

## 4.5 Why the subnet is part of the VNet

The subnet defines an address range inside a Virtual Network.

For Lab 01:

```text
vnet-azsl-01
└── subnet-azsl-01
```

The subnet is therefore a nested/configuration object within the VNet rather than a separate top-level Azure resource in the same sense as a VM, NIC, NSG, Public IP, or Managed Disk.

---

## 4.6 Where the private IP belongs

The private IP belongs to the NIC IP configuration, not directly to the VM resource.

```text
NIC: vm-azsl-01284
└── IP configuration: ipconfig1
    └── Private IP: 172.16.0.4
```

This distinction is important because the VM receives network connectivity through the NIC rather than owning the private IP directly.

---

## 4.7 Public IP versus private IP

The private and public IPs are represented differently.

```text
VM: vm-azsl-01
└── NIC: vm-azsl-01284
    └── IP configuration: ipconfig1
        ├── Private IP: 172.16.0.4
        └── Public IP reference → vm-azsl-01-ip
```

### Private IP

The private IP is a value inside the NIC IP configuration.

### Public IP

`vm-azsl-01-ip` is a separate Azure resource referenced by the NIC IP configuration.

Therefore:

```text
Private IP = configuration value on the NIC
Public IP  = separate Azure resource referenced by the NIC
```

---

## 4.8 NSG relationship and connectivity

`nsg-azsl-01` is a separate Azure resource associated with the NIC.

It is not part of the Ubuntu guest operating system.

For direct SSH connectivity, the logical path is:

```text
Internet
   ↓
Public IP
   ↓
NIC
   ↓
NSG
   ↓
allow-ssh-myip
   ↓
VM
   ↓
Ubuntu SSH service
```

The NSG controls traffic at the Azure network layer.

The guest SSH service is a separate layer inside the operating system.

This means:

```text
NSG allows TCP/22
≠
SSH service inside Ubuntu is necessarily working
```

and:

```text
SSH service is running
≠
Azure networking necessarily allows the connection
```

---

## 4.9 Managed OS disk relationship

The managed OS disk is a separate Azure resource referenced by the VM.

```text
vm-azsl-01
└── OS disk reference
    └── vm-azsl-01_OsDisk_1_...
```

The disk stores the VM operating system data but has its own Azure resource lifecycle.

This was demonstrated during Inspect when the VM was deallocated while the managed disk still existed.

```text
VM runtime state
≠
Managed Disk resource lifecycle
```

---

## 4.10 Resource versus configuration

### Top-level Azure resources

```text
Virtual Machine
Network Interface
Virtual Network
Network Security Group
Public IP
Managed Disk
SSH Key
```

### Configuration / nested objects

```text
Subnet
NIC IP configuration
NSG rule
```

Examples from Lab 01:

```text
vm-azsl-01        → resource
ipconfig1         → configuration
subnet-azsl-01    → configuration / nested object
nsg-azsl-01       → resource
allow-ssh-myip    → configuration
vm-azsl-01-ip     → resource
```

Important distinction:

```text
Portal-visible object
≠
necessarily top-level Azure resource
```

---

## 4.11 Reconstructed relationships from memory

The main relationships can now be reconstructed without using the Portal resource list:

```text
VM
├── NIC reference
│   ├── IP configuration
│   │   ├── Private IP
│   │   ├── Subnet reference
│   │   │   └── VNet
│   │   └── Public IP reference
│   └── NSG association
└── Managed OS Disk reference
```

Additional deployment resource:

```text
SSH Key resource
└── used during VM provisioning/authentication setup
```

---

## Phase checkpoint

Phase 4 is complete because the following can now be explained without relying on the Portal resource list:

```text
VM → NIC → IP configuration → Subnet → VNet
```

and the learner can explain:

```text
1. Why the VM does not directly contain the VNet.
2. Why the NIC is central to VM networking.
3. Why the subnet is part of the VNet.
4. Where the private IP configuration belongs.
5. How the Public IP relates to the NIC.
6. How the managed OS disk relates to the VM.
7. How the NSG affects connectivity without becoming part of the guest OS.
8. Which objects are top-level Azure resources and which are nested/configuration objects.
```

---

# Phase 4 Result

Map is complete.

Verified learning outcomes:

```text
Dependency map reconstructed without Portal resource list: understood
VM → NIC relationship: understood
NIC → IP configuration relationship: understood
IP configuration → subnet relationship: understood
Subnet → VNet relationship: understood
Public IP reference: understood
Private IP ownership: understood
NIC → NSG association: understood
VM → Managed OS Disk relationship: understood
Top-level resource versus nested configuration: understood
SSH Key role in the map: understood
```

Next phase:

```text
Map
  ↓
Observe
```

Proceed to **Phase 5 — Observe**.
