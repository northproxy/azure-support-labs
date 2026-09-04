# Lab 04 — Phase 4: VNet Peering & Private Connectivity Troubleshooting

## Status

**Completed**

## Purpose

Build and troubleshoot private connectivity between two Azure Virtual Networks using VNet peering.

This phase follows the project learning cycle:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

The main objective was to understand how VNet peering affects Azure routing, how private connectivity behaves before and after peering, and how a broken peering relationship appears in both connectivity tests and Azure control-plane state.

---

## Starting Baseline

Existing retained Azure resources:

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
NIC:            vm-azsl-01284
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
Public IP:      vm-azsl-01-ip
```

Existing networking state:

```text
NSG attachment:      NIC level
Subnet-level NSG:    none
Subnet route table:  none
Active UDRs:         none
Effective routing:   Azure system routes only
SSH connectivity:    working
```

The existing VNet used a `/24` address space.

A second non-overlapping `/24` address space was selected for the peering lab.

Sanitized topology:

```text
vnet-azsl-01    → xxx.xxx.0.0/24
vnet-azsl-peer  → xxx.xxx.10.0/24
```

---

## Phase 4 Topology

Temporary resources created for this phase:

```text
Resource Group: rg-azsl-01

vnet-azsl-01
└── subnet-azsl-01
    └── vm-azsl-01
        └── NIC: vm-azsl-01284

           VNet Peering

vnet-azsl-peer
└── subnet-azsl-peer
    └── vm-azsl-peer-01
        ├── NIC: vm-azsl-peer-01VMNic
        ├── NSG: vm-azsl-peer-01NSG
        ├── OS Disk: vm-azsl-peer-01_OsDisk_...
        └── SSH key: vm-azsl-peer-01-key
```

`vm-azsl-peer-01` was intentionally created without a Public IP.

This ensured that communication with the second VM depended on private Azure networking rather than Internet connectivity.

---

# 1. Build — Create the Second VNet

The existing VNet address space was inspected first.

Example inspection:

```powershell
az network vnet show `
  --resource-group rg-azsl-01 `
  --name vnet-azsl-01 `
  --query "{Name:name,AddressSpace:addressSpace.addressPrefixes,Subnets:subnets[].{Name:name,Prefix:addressPrefix}}" `
  -o json
```

The subnet was inspected separately because the prefix was returned through `addressPrefixes`:

```powershell
az network vnet subnet show `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name subnet-azsl-01 `
  --query "{Name:name,AddressPrefix:addressPrefix,AddressPrefixes:addressPrefixes}" `
  -o json
```

A non-overlapping CIDR was chosen for the second VNet.

The second VNet and subnet were created:

```powershell
az network vnet create `
  --resource-group rg-azsl-01 `
  --name vnet-azsl-peer `
  --location austriaeast `
  --address-prefixes xxx.xxx.10.0/24 `
  --subnet-name subnet-azsl-peer `
  --subnet-prefixes xxx.xxx.10.0/24
```

The subnet configuration was then verified.

---

# 2. Build — Create the Private-Only Peer VM

A temporary SSH key resource was created:

```powershell
az sshkey create `
  --resource-group rg-azsl-01 `
  --name vm-azsl-peer-01-key
```

A second Linux VM was created in `vnet-azsl-peer`.

Selected VM size:

```text
Standard_B2ats_v2
```

The VM was intentionally created without a Public IP.

PowerShell quoting required special handling for the empty Public IP argument:

```powershell
--public-ip-address '""'
```

VM creation:

```powershell
az vm create `
  --resource-group rg-azsl-01 `
  --name vm-azsl-peer-01 `
  --location austriaeast `
  --image Ubuntu2404 `
  --size Standard_B2ats_v2 `
  --vnet-name vnet-azsl-peer `
  --subnet subnet-azsl-peer `
  --public-ip-address '""' `
  --admin-username azureuser `
  --ssh-key-name vm-azsl-peer-01-key
```

Result:

```text
Power state:       VM running
Private IP:        present
Public IP:         none
FQDN:              none
```

Azure also created the VM-associated NIC, NSG, and OS disk.

---

# 3. Observe — Private Connectivity Before Peering

Before creating VNet peering, the two VNets were isolated.

From `vm-azsl-01`, connectivity to the private IP of `vm-azsl-peer-01` was tested.

ICMP:

```bash
ping -c 4 <PRIVATE-IP>
```

Result:

```text
4 packets transmitted
0 received
100% packet loss
```

TCP/22:

```bash
nc -vz -w 5 <PRIVATE-IP> 22
```

Result:

```text
connection timed out
```

Peering configuration was inspected on both VNets:

```powershell
az network vnet peering list `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  -o table
```

```powershell
az network vnet peering list `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-peer `
  -o table
```

Both tables were empty.

This established the baseline:

```text
VM-01 running
VM-02 running
Private IPs present
No VNet peering
Private connectivity unavailable
```

---

# 4. Build — Create Bidirectional VNet Peering

Peering from the original VNet to the second VNet:

```powershell
az network vnet peering create `
  --resource-group rg-azsl-01 `
  --name peer-azsl-to-peer `
  --vnet-name vnet-azsl-01 `
  --remote-vnet vnet-azsl-peer `
  --allow-vnet-access
```

Reverse peering:

```powershell
az network vnet peering create `
  --resource-group rg-azsl-01 `
  --name peer-peer-to-azsl `
  --vnet-name vnet-azsl-peer `
  --remote-vnet vnet-azsl-01 `
  --allow-vnet-access
```

Both sides were verified:

```text
peer-azsl-to-peer  → Connected
peer-peer-to-azsl  → Connected
```

---

# 5. Observe — Connectivity After Peering

The same private connectivity tests were repeated.

ICMP:

```text
4 packets transmitted
4 received
0% packet loss
```

TCP/22:

```text
Connection to <PRIVATE-IP> 22 port [tcp/ssh] succeeded
```

This demonstrated that private connectivity was now available through VNet peering.

---

# 6. Observe — Effective Routes After Peering

The effective route table of the original VM NIC was inspected:

```powershell
az network nic show-effective-route-table `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  -o table
```

A new active route appeared for the remote VNet address space:

```text
Source    State    Address Prefix       Next Hop Type
--------  -------  -------------------  -------------
Default   Active   <REMOTE-VNET>/24     VNetPeering
```

This was the key routing observation of the phase.

Before peering:

```text
No route to remote VNet through VNetPeering
Private connectivity failed
```

After peering:

```text
Remote VNet /24 → VNetPeering
Private connectivity succeeded
```

---

# 7. Break — Delete One Side of the Peering

To create a controlled failure, only one side of the peering was deleted:

```powershell
az network vnet peering delete `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name peer-azsl-to-peer
```

The reverse peering object was intentionally left in place.

---

# 8. Diagnose — Peering State

The remaining peering was inspected:

```text
Name:               peer-peer-to-azsl
PeeringState:       Disconnected
ProvisioningState:  Succeeded
```

This distinction was important:

```text
ProvisioningState = Succeeded
```

meant that the peering resource object itself still existed successfully.

However:

```text
PeeringState = Disconnected
```

meant that the paired relationship was no longer valid because the remote peering had been removed.

---

# 9. Diagnose — Connectivity Failure

The same connectivity tests were repeated.

ICMP:

```text
4 packets transmitted
0 received
100% packet loss
```

TCP/22:

```text
connection timed out
```

The effective route table was inspected again.

The route:

```text
<REMOTE-VNET>/24 → VNetPeering
```

was no longer present.

This produced a clear troubleshooting chain:

```text
One side of peering deleted
        ↓
Remote peering becomes Disconnected
        ↓
VNetPeering effective route disappears
        ↓
Private connectivity fails
        ↓
ICMP fails
TCP/22 times out
```

No NSG, UDR, or guest firewall changes were introduced during this failure.

This isolated VNet peering as the cause.

---

# 10. Troubleshooting Finding — RemotePeeringIsDisconnected

An attempt was made to recreate only the deleted peering side:

```powershell
az network vnet peering create `
  --resource-group rg-azsl-01 `
  --name peer-azsl-to-peer `
  --vnet-name vnet-azsl-01 `
  --remote-vnet vnet-azsl-peer `
  --allow-vnet-access
```

Azure returned:

```text
RemotePeeringIsDisconnected
```

The message explained that the remote peering was still in `Disconnected` state and needed to be updated or recreated.

This demonstrated an important operational behavior:

> Deleting one side of an established VNet peering can leave the remaining remote peering object in `Disconnected` state. Recreating only the deleted side may fail until the disconnected remote peering is also removed or recreated.

---

# 11. Fix — Recreate Both Peering Objects

The disconnected remote peering was deleted:

```powershell
az network vnet peering delete `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-peer `
  --name peer-peer-to-azsl
```

Both sides were then recreated.

Original to peer:

```powershell
az network vnet peering create `
  --resource-group rg-azsl-01 `
  --name peer-azsl-to-peer `
  --vnet-name vnet-azsl-01 `
  --remote-vnet vnet-azsl-peer `
  --allow-vnet-access
```

Peer to original:

```powershell
az network vnet peering create `
  --resource-group rg-azsl-01 `
  --name peer-peer-to-azsl `
  --vnet-name vnet-azsl-peer `
  --remote-vnet vnet-azsl-01 `
  --allow-vnet-access
```

---

# 12. Verify — Peering State

Both peering objects were inspected.

Result:

```text
peer-azsl-to-peer  → Connected / Succeeded
peer-peer-to-azsl  → Connected / Succeeded
```

---

# 13. Verify — Private Connectivity

ICMP:

```text
4 packets transmitted
4 received
0% packet loss
```

TCP/22:

```text
Connection to <PRIVATE-IP> 22 port [tcp/ssh] succeeded
```

Private connectivity was fully restored.

---

# 14. Verify — Effective Routing

The NIC effective route table was checked again:

```powershell
az network nic show-effective-route-table `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  -o table
```

The remote VNet route had returned:

```text
Default   Active   <REMOTE-VNET>/24   VNetPeering
```

This completed the recovery verification.

---

# Key Findings

## VNet Address Spaces Must Not Overlap

The two peered VNets used non-overlapping address spaces.

Sanitized example:

```text
vnet-azsl-01    → xxx.xxx.0.0/24
vnet-azsl-peer  → xxx.xxx.10.0/24
```

Overlapping address spaces are unsuitable for this peering scenario.

---

## VNet Peering Changes Effective Routing

A successful peering relationship resulted in an automatically managed route:

```text
remote VNet prefix → VNetPeering
```

The route appeared in the NIC effective route table without creating a User-Defined Route.

---

## Connectivity Tests Should Be Repeated Consistently

The same tests were used before and after every change:

```text
ICMP ping
TCP/22
effective routes
peering state
```

This made the effect of each networking change easy to compare.

---

## ProvisioningState and PeeringState Mean Different Things

A peering resource can show:

```text
ProvisioningState: Succeeded
PeeringState:      Disconnected
```

This means the Azure resource object exists successfully, but the logical peering relationship is not operational.

---

## A Disconnected Remote Peering Can Block Recovery

Recreating only one side of a broken peering produced:

```text
RemotePeeringIsDisconnected
```

Recovery required removing or recreating the disconnected remote peering as well.

---

## Private-Only VM Design Improved the Lab

The second VM had no Public IP.

This ensured that successful access depended on Azure private connectivity and made VNet peering behavior easier to observe.

---

# Troubleshooting Summary

| Stage | Peering State | Effective Remote Route | Ping | TCP/22 |
|---|---|---|---|---|
| Before peering | none | none | fail | timeout |
| Peering healthy | Connected | `VNetPeering` | success | success |
| One side deleted | Disconnected on remaining side | disappeared | fail | timeout |
| After recovery | Connected | `VNetPeering` restored | success | success |

---

# Cleanup

After recovery verification, all temporary Phase 4 resources were deleted:

```text
vm-azsl-peer-01
vm-azsl-peer-01VMNic
vm-azsl-peer-01NSG
vm-azsl-peer-01_OsDisk_...
vm-azsl-peer-01-key
peer-azsl-to-peer
peer-peer-to-azsl
vnet-azsl-peer
subnet-azsl-peer
```

Cleanup was verified through Azure Portal and Azure CLI.

Final Resource Group inventory:

```text
vm-azsl-01-key
nsg-azsl-01
vm-azsl-01-ip
vnet-azsl-01
vm-azsl-01284
vm-azsl-01
vm-azsl-01_OsDisk_...
```

The retained baseline resources were left unchanged:

```text
vm-azsl-01
vm-azsl-01284
vnet-azsl-01
subnet-azsl-01
nsg-azsl-01
vm-azsl-01-ip
vm-azsl-01-key
vm-azsl-01_OsDisk_...
```

No temporary Phase 4 VNet, VM, NIC, NSG, disk, SSH key, or peering objects remain.

---

# Phase 4 Completion Checkpoint

Completed:

```text
[x] inspected existing VNet address space
[x] selected non-overlapping second VNet CIDR
[x] created second VNet and subnet
[x] created private-only second VM
[x] confirmed no connectivity before peering
[x] created bidirectional VNet peering
[x] verified private ICMP connectivity
[x] verified private TCP/22 connectivity
[x] observed remote VNet route through VNetPeering
[x] deleted one side of peering as controlled failure
[x] observed remaining peer in Disconnected state
[x] reproduced private connectivity failure
[x] confirmed VNetPeering route disappeared
[x] encountered and diagnosed RemotePeeringIsDisconnected
[x] recreated both peering objects
[x] verified Connected / Succeeded state
[x] verified private connectivity recovery
[x] verified VNetPeering route recovery
[x] deleted all temporary Phase 4 resources
[x] verified retained Resource Group baseline through Azure CLI
```

Phase 4 is complete, including cleanup.

---

# Final Retained Networking Baseline

```text
Resource Group:      rg-azsl-01
VM:                  vm-azsl-01
NIC:                 vm-azsl-01284
VNet:                vnet-azsl-01
Subnet:              subnet-azsl-01
NSG:                 nsg-azsl-01
Public IP:           vm-azsl-01-ip
Subnet route table:  none
Active UDRs:         none
Temporary peer VNet: none
Temporary peer VM:   none
VNet peerings:       none
```

---

# Next

**Lab 04 — Phase 5: Azure Load Balancer & Backend Connectivity Troubleshooting**

Continue using one controlled networking change at a time and diagnose before fixing.
