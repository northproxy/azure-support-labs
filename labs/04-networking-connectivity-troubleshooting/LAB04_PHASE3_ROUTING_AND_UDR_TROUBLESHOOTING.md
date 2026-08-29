# Lab 04 — Phase 3: Routing and User-Defined Route Troubleshooting

## Purpose

Practice Azure routing troubleshooting using a controlled User-Defined Route failure.

The goal of this phase was to:

- inspect the current Azure system route baseline;
- associate a temporary route table with the existing subnet;
- verify that an empty route table does not break connectivity;
- create a narrowly scoped User-Defined Route;
- reproduce an SSH connectivity failure caused by routing;
- inspect effective routes on the VM NIC;
- understand longest prefix match behavior;
- identify the route responsible for the failure;
- remove the temporary route;
- verify connectivity recovery;
- restore the original subnet routing baseline.

This phase followed the project troubleshooting cycle:

```text
Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete
```

---

# Starting Baseline

Existing Azure resources:

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
NIC:            vm-azsl-01284
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
Public IP:      vm-azsl-01-ip
```

The subnet had no custom route table associated.

Subnet inspection:

```powershell
az network vnet subnet show `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name subnet-azsl-01 `
  --query "{Subnet:name,Prefixes:addressPrefixes,RouteTable:routeTable.id}" `
  -o json
```

Relevant result:

```text
RouteTable: null
```

This confirmed that the subnet used Azure system routing only.

---

# Observe — Effective Route Baseline

Effective routes were inspected on the VM network interface:

```powershell
az network nic show-effective-route-table `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  -o table
```

Important baseline routes included:

```text
<VNET-PREFIX>/24 → VnetLocal
0.0.0.0/0        → Internet
```

Additional Azure default routes with:

```text
NextHopType: None
```

were also present for reserved or non-routable address ranges.

No active user-defined routes were present.

The important baseline path for outbound Internet traffic was:

```text
VM
 ↓
NIC
 ↓
Subnet
 ↓
Azure system route
0.0.0.0/0 → Internet
```

---

# Build — Create Temporary Route Table

A temporary route table was created:

```powershell
az network route-table create `
  --resource-group rg-azsl-01 `
  --name rt-azsl-lab04 `
  --location austriaeast
```

The route table was then associated with the existing subnet:

```powershell
az network vnet subnet update `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name subnet-azsl-01 `
  --route-table rt-azsl-lab04
```

The association was verified:

```powershell
az network vnet subnet show `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name subnet-azsl-01 `
  --query "{Subnet:name,RouteTable:routeTable.id}" `
  -o json
```

At this point the route table contained no custom routes.

---

# Observe — Empty Route Table Does Not Break Connectivity

SSH connectivity was tested immediately after associating the empty route table.

Result:

```text
SSH connection successful.
```

This demonstrated an important routing behavior:

```text
Route table associated
        ↓
No user-defined routes
        ↓
Azure system routes still apply
        ↓
0.0.0.0/0 → Internet remains active
        ↓
Connectivity remains available
```

Therefore, associating a route table by itself did not cause a network failure.

---

# Controlled Failure

## Break — Create a More Specific User-Defined Route

A narrowly scoped route was created for the administrator's current public IPv4 address.

Route characteristics:

```text
Name:          drop-admin-public-ip
AddressPrefix: <ADMIN-PUBLIC-IP>/32
NextHopType:   None
```

Azure CLI:

```powershell
az network route-table route create `
  --resource-group rg-azsl-01 `
  --route-table-name rt-azsl-lab04 `
  --name drop-admin-public-ip `
  --address-prefix "$currentIp/32" `
  --next-hop-type None
```

The route was verified:

```powershell
az network route-table route list `
  --resource-group rg-azsl-01 `
  --route-table-name rt-azsl-lab04 `
  -o table
```

Relevant result:

```text
AddressPrefix        Name                  NextHopType    ProvisioningState
-------------------  --------------------  -------------  -----------------
<PUBLIC-IP>/32       drop-admin-public-ip  None           Succeeded
```

The route table was associated with:

```text
subnet-azsl-01
```

---

# Observe — SSH Failure

A new SSH connection was attempted.

Result:

```text
Connection timed out
```

The failure was successfully reproduced.

No NSG configuration was changed during this scenario.

The existing SSH allow rule remained in place:

```text
allow-ssh-myip
TCP/22
Source: administrator public IPv4 /32
```

This made routing the primary suspect.

---

# Diagnose

## Inspect Effective Routes

The NIC effective route table was inspected again:

```powershell
az network nic show-effective-route-table `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  -o table
```

The following routes were active simultaneously:

```text
Source    State    Address Prefix       Next Hop Type
--------  -------  -------------------  -------------
Default   Active   0.0.0.0/0            Internet
User      Active   <PUBLIC-IP>/32       None
```

This proved that the custom route was part of the VM's effective routing configuration.

---

# Longest Prefix Match

Both of the following routes technically matched traffic addressed to the administrator's public IP:

```text
0.0.0.0/0
<PUBLIC-IP>/32
```

However, Azure routing prefers the most specific matching route.

The `/32` route represents one exact IPv4 address:

```text
<PUBLIC-IP>/32
```

while:

```text
0.0.0.0/0
```

matches every IPv4 destination.

Therefore:

```text
/32 is more specific than /0
```

and the effective routing decision became:

```text
Destination: <PUBLIC-IP>
        ↓
Matches 0.0.0.0/0
        ↓
Matches <PUBLIC-IP>/32
        ↓
Longest prefix match
        ↓
<PUBLIC-IP>/32 selected
        ↓
NextHopType: None
        ↓
Packet dropped
```

---

# Root Cause

The controlled UDR:

```text
<PUBLIC-IP>/32 → None
```

overrode the broader Azure system route:

```text
0.0.0.0/0 → Internet
```

for traffic specifically destined for the administrator's public IPv4 address.

The SSH request could reach the Azure VM, but return traffic destined for the administrator matched the more specific `/32` route and was discarded.

Conceptually:

```text
Administrator
     ↓
SSH request
     ↓
Azure Public IP
     ↓
NIC
     ↓
VM
     ↓
SSH response
destination = administrator public IP
     ↓
Effective routing
     ↓
<PUBLIC-IP>/32 → None
     ↓
Response packet dropped
     ↓
TCP connection cannot complete
     ↓
SSH timeout
```

The failure was therefore caused by routing, not by the NSG.

---

# NSG Failure vs Routing Failure

This phase demonstrated a different failure mode from Phase 2.

## Phase 2

```text
Packet reaches NSG
    ↓
NSG deny rule matches
    ↓
Packet blocked
```

## Phase 3

```text
NSG configuration remains valid
    ↓
Route lookup selects /32 UDR
    ↓
NextHopType None
    ↓
Packet discarded
```

Both scenarios produced:

```text
SSH connection timed out
```

but the root causes were different.

This demonstrates why troubleshooting should use configuration evidence rather than relying only on the visible symptom.

---

# Fix

Only the temporary route responsible for the failure was removed:

```powershell
az network route-table route delete `
  --resource-group rg-azsl-01 `
  --route-table-name rt-azsl-lab04 `
  --name drop-admin-public-ip
```

The route table itself remained associated temporarily so that the effect of removing only the problematic route could be observed.

---

# Verify — Connectivity Recovery

SSH was tested again after removing the custom route.

Result:

```text
SSH connection successful.
```

The recovery confirmed the relationship:

```text
<PUBLIC-IP>/32 → None present
        ↓
SSH timeout

<PUBLIC-IP>/32 → None removed
        ↓
system 0.0.0.0/0 → Internet used
        ↓
SSH restored
```

This completed the:

```text
Diagnose → Fix → Verify
```

portion of the troubleshooting cycle.

---

# Cleanup

After verifying connectivity recovery, the temporary route table was detached from the subnet.

```powershell
az network vnet subnet update `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name subnet-azsl-01 `
  --remove routeTable
```

The subnet configuration was verified:

```powershell
az network vnet subnet show `
  --resource-group rg-azsl-01 `
  --vnet-name vnet-azsl-01 `
  --name subnet-azsl-01 `
  --query "{Subnet:name,RouteTable:routeTable.id}" `
  -o json
```

Expected result:

```text
RouteTable: null
```

The temporary route table was then deleted:

```powershell
az network route-table delete `
  --resource-group rg-azsl-01 `
  --name rt-azsl-lab04
```

---

# Final Effective Route Verification

The NIC effective route table was inspected one final time:

```powershell
az network nic show-effective-route-table `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  -o table
```

The temporary user-defined `/32` route was no longer present.

Only Azure system routes remained.

Important retained baseline:

```text
<VNET-PREFIX>/24 → VnetLocal
0.0.0.0/0        → Internet
```

No active user-defined routes remained.

---

# Troubleshooting Model Learned

A useful routing troubleshooting sequence is:

```text
Connectivity failure
    ↓
Check subnet route table association
    ↓
Inspect configured routes
    ↓
Inspect NIC effective routes
    ↓
Identify routes matching destination
    ↓
Compare route prefix lengths
    ↓
Determine selected route
    ↓
Inspect next hop
    ↓
Change only the responsible route
    ↓
Retest connectivity
```

---

# Key Lessons

## Route Tables Do Not Automatically Replace System Routes

Associating an empty route table with a subnet does not remove Azure system routes.

In this exercise:

```text
0.0.0.0/0 → Internet
```

continued to work until a custom route affected the destination being tested.

---

## Effective Routes Matter More Than Route Table Contents Alone

A route table shows configured User-Defined Routes.

The NIC effective route table shows what the VM actually sees after Azure combines applicable routes.

For troubleshooting, effective routes provide a more useful operational view.

---

## Longest Prefix Match Is Critical

When multiple routes match a destination, Azure chooses the most specific prefix.

Example:

```text
0.0.0.0/0       → Internet
203.0.113.10/32 → None
```

For destination:

```text
203.0.113.10
```

Azure uses:

```text
203.0.113.10/32 → None
```

because `/32` is more specific than `/0`.

---

## Next Hop `None` Drops Traffic

A route using:

```text
NextHopType: None
```

causes matching traffic to be dropped.

This can be useful deliberately, but an incorrect route can also create difficult connectivity failures.

---

## Identical Symptoms Can Have Different Root Causes

Both NSG and routing problems may appear to the user as:

```text
Connection timed out
```

The symptom alone is not enough to determine the cause.

Compare:

```text
NSG problem
→ effective security rules
→ IP flow verification

Routing problem
→ effective routes
→ route selection / next hop
```

This is an important support troubleshooting principle.

---

# Cleanup Result

Temporary resources created during this phase:

```text
rt-azsl-lab04
└── drop-admin-public-ip
```

Final state:

```text
drop-admin-public-ip → deleted
rt-azsl-lab04        → detached
rt-azsl-lab04        → deleted
```

Retained subnet state:

```text
subnet-azsl-01
├── Custom route table: none
└── Azure system routes only
```

Retained VM networking state:

```text
NSG:              nsg-azsl-01
SSH rule:         allow-ssh-myip
Custom UDRs:      none
Default Internet: active
SSH connectivity: working
```

---

# Phase Result

Phase 3 successfully demonstrated:

```text
System route baseline
        ↓
Temporary empty route table
        ↓
SSH still functional
        ↓
Specific /32 UDR created
        ↓
NextHopType None
        ↓
SSH timeout reproduced
        ↓
Effective routes inspected
        ↓
Longest prefix match identified
        ↓
Problematic UDR removed
        ↓
SSH restored
        ↓
Temporary route table detached
        ↓
Temporary route table deleted
        ↓
Original routing baseline restored
```

## Status

```text
Lab 04 — Phase 3: completed
```

## Next

```text
Lab 04 — next networking troubleshooting phase
```