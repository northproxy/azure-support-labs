# Lab 04 — Phase 1: Networking Baseline Inspection

## Status

**Completed**

## Purpose

Inspect and document the existing Azure networking configuration before introducing any changes or controlled failures.

This phase establishes a verified networking baseline for later connectivity troubleshooting exercises.

## Learning focus

- Virtual Machine to NIC relationship
- NIC IP configuration
- Private and public IP addressing
- VNet and subnet relationships
- NSG placement
- Effective security rules
- System routes
- Effective route table
- Difference between configured networking objects and effective runtime networking state

## Existing Azure baseline

The lab reused the existing Azure environment:

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
NIC:            vm-azsl-01284
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
Public IP:      vm-azsl-01-ip
Network Watcher:
  NetworkWatcher_austriaeast
  Resource Group: NetworkWatcherRG
```

The VM was initially in the `VM deallocated` state.

## Phase flow

```text
Inspect
→ Map dependencies
→ Inspect IP configuration
→ Inspect subnet configuration
→ Inspect NSG rules
→ Start VM
→ Inspect effective NSG
→ Inspect effective routes
→ Document baseline
```

## 1. VM to NIC relationship

The VM network profile was inspected with Azure CLI.

Confirmed relationship:

```text
vm-azsl-01
└── NIC → vm-azsl-01284
```

This verified which network interface is actually attached to the VM.

## 2. NIC IP configuration

The NIC IP configuration was inspected.

Confirmed configuration:

```text
vm-azsl-01284
└── ipconfig1
    ├── Private IP allocation: Dynamic
    ├── Primary: True
    ├── Subnet → vnet-azsl-01/subnet-azsl-01
    └── Public IP → vm-azsl-01-ip
```

### Observation

The private IP is allocated dynamically by Azure from the subnet address range.

The public IP resource still exists and is actively associated with the NIC IP configuration.

## 3. VNet and subnet configuration

The VNet and subnet were inspected separately.

Confirmed subnet configuration:

```text
vnet-azsl-01
└── subnet-azsl-01
    ├── Address prefix: <sanitized>/24
    ├── NSG: none
    └── Route table: none
```

### Observation

The subnet currently has:

- no subnet-level NSG;
- no custom route table.

This means the existing NSG is not applied at subnet scope.

## 4. NSG placement

The NIC configuration confirmed:

```text
vm-azsl-01284
└── NSG → nsg-azsl-01
```

Therefore, `nsg-azsl-01` is attached directly to the NIC.

The subnet itself has no NSG association.

## 5. Custom NSG rule

The configured NSG rules were inspected.

One custom rule was found:

```text
Name:        allow-ssh-myip
Priority:    1000
Direction:   Inbound
Protocol:    TCP
Source:      <sanitized-public-ip>/32
Destination: *
Port:        22
Access:      Allow
```

### Observation

The `/32` source prefix restricts SSH access to one specific public IPv4 address.

This is a least-privilege inbound access pattern.

## 6. Effective NSG inspection

The first attempt to retrieve effective security rules failed because the VM was deallocated.

Azure returned:

```text
NicMustBeAttachedToRunningVmToGetEffectiveSecurityGroups
```

### Diagnosis

The NIC existed and was attached to the VM, but effective security groups could not be retrieved while the VM was not running.

### Resolution

The VM was started temporarily and the effective security rules were queried again.

Confirmed effective rules:

```text
Inbound
1000   allow-ssh-myip                 Allow
65000  AllowVnetInBound               Allow
65001  AllowAzureLoadBalancerInBound  Allow
65500  DenyAllInBound                 Deny

Outbound
65000  AllowVnetOutBound              Allow
65001  AllowInternetOutBound          Allow
65500  DenyAllOutBound                Deny
```

### Key learning

NSG rules are processed by priority.

A lower priority number is evaluated before a higher priority number.

Therefore:

```text
allow-ssh-myip (1000)
```

is evaluated before:

```text
DenyAllInBound (65500)
```

The custom SSH allow rule can therefore permit matching traffic before the default inbound deny rule is reached.

## 7. Effective route table

The effective route table was inspected while the VM was running.

All observed routes had:

```text
Source: Default
State:  Active
```

Important routes included:

```text
<VNet prefix>/24 → VnetLocal
0.0.0.0/0        → Internet
special ranges   → None
```

### Observation

Because the subnet has no custom route table and the effective routes all have `Source: Default`, the NIC is currently using Azure system routes only.

Current routing model:

```text
vm-azsl-01
└── vm-azsl-01284
    └── subnet-azsl-01
        ├── No custom route table
        └── Azure system routes
            ├── VNet prefix → VnetLocal
            ├── 0.0.0.0/0 → Internet
            └── Reserved/special ranges → None
```

## 8. Confirmed networking baseline

The final verified networking baseline is:

```text
vm-azsl-01
└── NIC: vm-azsl-01284
    ├── IP configuration: ipconfig1
    │   ├── Private IP allocation: Dynamic
    │   ├── Primary: True
    │   ├── Subnet → subnet-azsl-01
    │   └── Public IP → vm-azsl-01-ip
    │
    └── NSG → nsg-azsl-01
        └── allow-ssh-myip
            ├── TCP/22
            ├── Source: one public IPv4 address (/32)
            └── Priority: 1000

vnet-azsl-01
└── subnet-azsl-01
    ├── Address prefix: <sanitized>/24
    ├── NSG: none
    └── Route table: none

Effective routing
├── VNet prefix → VnetLocal
├── 0.0.0.0/0 → Internet
└── Reserved/special ranges → None
```

## Key findings

- The VM is connected through `vm-azsl-01284`.
- The NIC has one primary IP configuration: `ipconfig1`.
- The private IP uses dynamic allocation.
- `vm-azsl-01-ip` is associated with the NIC.
- `nsg-azsl-01` is attached to the NIC, not the subnet.
- The subnet has no NSG and no custom route table.
- SSH is allowed only from one specific public IPv4 address.
- Effective NSG inspection requires the attached VM to be running.
- Effective NSG includes both custom and Azure default security rules.
- The subnet currently relies entirely on Azure system routes.
- No user-defined routes are currently active.

## Troubleshooting lesson

This phase demonstrated an important difference between static configuration and runtime-effective networking state.

Static objects such as:

```text
NSG rules
NIC configuration
Subnet configuration
Route table association
```

can be inspected while a VM is deallocated.

However, some effective runtime diagnostics require the VM network endpoint to be active.

The failure:

```text
NicMustBeAttachedToRunningVmToGetEffectiveSecurityGroups
```

was therefore not an NSG configuration problem. It was a diagnostic precondition problem.

## Cleanup / checkpoint

No permanent networking changes were introduced during this phase.

The VM was started only to retrieve runtime-effective networking information.

If no further work is being performed immediately, return the VM to:

```text
VM deallocated
```

## Next phase

**Lab 04 — Phase 2: NSG Connectivity Troubleshooting**

Planned direction:

```text
Baseline
→ Introduce a controlled NSG failure
→ Observe connectivity impact
→ Inspect effective security rules
→ Diagnose rule priority / matching
→ Fix
→ Verify
→ Cleanup
```
