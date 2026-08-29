# Lab 04 — Azure Networking & Connectivity Troubleshooting

## Status

**In progress**

Completed so far:

```text
Phase 1 — Networking Baseline Inspection
Phase 2 — NSG Connectivity Troubleshooting
Phase 3 — Routing and User-Defined Route Troubleshooting
```

Next:

```text
Phase 4 — VNet Peering & Private Connectivity Troubleshooting
```

---

## Purpose

Build practical Azure networking and connectivity troubleshooting skills using a retained VM environment and controlled failure scenarios.

The lab focuses on understanding not only how Azure networking objects are configured, but how effective runtime networking state determines connectivity.

The troubleshooting cycle used throughout this lab is:

```text
Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete
```

---

## Learning Objectives

By the end of this lab, the goal is to be able to:

- understand VM, NIC, IP configuration, VNet, subnet, NSG, Public IP, and route relationships;
- distinguish configured networking objects from effective runtime networking state;
- understand NSG rule priority and default NSG behavior;
- inspect effective security rules;
- use Network Watcher IP flow verify;
- understand Azure system routes and User-Defined Routes;
- inspect NIC effective routes;
- understand longest prefix match;
- diagnose connectivity failures caused by NSGs and routing;
- distinguish similar symptoms with different root causes;
- troubleshoot private connectivity and VNet peering;
- restore connectivity safely and remove temporary troubleshooting resources.

---

## Retained Azure Baseline

The lab reuses the existing Azure environment:

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
NIC:            vm-azsl-01284
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
Public IP:      vm-azsl-01-ip
```

Current networking baseline:

```text
NSG attachment:      NIC level
Subnet-level NSG:    none
Subnet route table:  none
Active UDRs:         none
Effective routing:   Azure system routes only
SSH rule:            allow-ssh-myip
SSH protocol:        TCP
SSH port:            22
SSH source:          current administrator public IPv4 /32
SSH connectivity:    working
```

Network Watcher is available in the region and is used where appropriate for runtime connectivity diagnostics.

---

## Phase 1 — Networking Baseline Inspection

File:

[`LAB04_PHASE1_NETWORKING_BASELINE_INSPECTION.md`](LAB04_PHASE1_NETWORKING_BASELINE_INSPECTION.md)

### Completed

- inspected the VM → NIC relationship;
- confirmed NIC `vm-azsl-01284`;
- inspected `ipconfig1`;
- confirmed dynamic private IP allocation;
- confirmed Public IP association;
- inspected `vnet-azsl-01` and `subnet-azsl-01`;
- confirmed the subnet has no NSG;
- confirmed the subnet has no custom route table;
- confirmed `nsg-azsl-01` is attached directly to the NIC;
- inspected the restrictive `allow-ssh-myip` rule;
- started the VM temporarily for runtime diagnostics;
- inspected effective security rules;
- observed Azure default inbound and outbound NSG rules;
- diagnosed the `NicMustBeAttachedToRunningVmToGetEffectiveSecurityGroups` diagnostic precondition;
- inspected the effective route table;
- confirmed Azure system routes only;
- confirmed no active User-Defined Routes.

### Key finding

The existing networking model is:

```text
vm-azsl-01
└── vm-azsl-01284
    ├── ipconfig1
    │   ├── Private IP allocation: Dynamic
    │   ├── Subnet → subnet-azsl-01
    │   └── Public IP → vm-azsl-01-ip
    │
    └── NSG → nsg-azsl-01
        └── allow-ssh-myip
            ├── TCP/22
            ├── Source: administrator public IPv4 /32
            └── Priority: 1000
```

The subnet itself has no NSG and no custom route table.

---

## Troubleshooting Note — SSH Failure After Client Public IP Change

File:

[`LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md`](LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md)

Before the planned NSG failure exercise, a real SSH incident occurred.

Observed symptom:

```text
ssh: connect to host <PUBLIC-IP> port 22: Connection timed out
```

### Root cause

The administrator's external public IPv4 address changed, while the restrictive NSG rule still allowed the previous `/32` source address.

The new client address no longer matched:

```text
allow-ssh-myip
```

and the traffic therefore reached the default inbound deny behavior.

### Fix

The current public IPv4 address was retrieved:

```powershell
$currentIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
```

The existing NSG rule was updated:

```powershell
az network nsg rule update `
  --resource-group rg-azsl-01 `
  --nsg-name nsg-azsl-01 `
  --name allow-ssh-myip `
  --source-address-prefixes "$currentIp/32"
```

SSH connectivity was restored.

### Support lesson

When SSH suddenly times out and TCP/22 is restricted to one `/32`, check whether the client public IP changed before modifying other Azure networking components.

Do not widen the rule to:

```text
0.0.0.0/0
```

unless there is a deliberate reason to do so.

---

## Phase 2 — NSG Connectivity Troubleshooting

File:

[`LAB04_PHASE2_NSG_CONNECTIVITY_TROUBLESHOOTING.md`](LAB04_PHASE2_NSG_CONNECTIVITY_TROUBLESHOOTING.md)

### Controlled failure

A temporary higher-priority deny rule was created:

```text
Name:      deny-ssh-lab
Priority:  900
Direction: Inbound
Access:    Deny
Protocol:  TCP
Source:    administrator public IPv4 /32
Port:      22
```

The retained allow rule remained:

```text
Name:      allow-ssh-myip
Priority:  1000
Access:    Allow
Protocol:  TCP
Port:      22
```

Because lower numeric priority is evaluated first:

```text
900  deny-ssh-lab
1000 allow-ssh-myip
```

the deny rule won.

### Observed symptom

```text
Connection timed out
```

### Diagnosis

Effective security rules confirmed that both rules applied to the NIC and that the deny rule had higher precedence.

Network Watcher IP flow verify then directly identified the blocking rule:

```text
Access    RuleName
--------  --------------------------
Deny      securityRules/deny-ssh-lab
```

### Fix

Only the temporary deny rule was removed.

### Verification

SSH connectivity opened successfully again.

### Key lesson

A timeout does not identify the root cause by itself.

For NSG troubleshooting:

```text
Inspect configured NSG rules
        ↓
Inspect effective security rules
        ↓
Check priority and overlap
        ↓
Use IP flow verify
        ↓
Identify exact Allow/Deny rule
        ↓
Fix only the responsible configuration
```

---

## Phase 3 — Routing and User-Defined Route Troubleshooting

File:

[`LAB04_PHASE3_ROUTING_AND_UDR_TROUBLESHOOTING.md`](LAB04_PHASE3_ROUTING_AND_UDR_TROUBLESHOOTING.md)

### Baseline

The subnet initially had no custom route table.

Important effective system routes included:

```text
<VNET-PREFIX>/24 → VnetLocal
0.0.0.0/0        → Internet
```

No active User-Defined Routes were present.

### Build

A temporary route table was created and associated with `subnet-azsl-01`.

SSH remained functional while the route table was empty.

This demonstrated that associating an empty route table does not remove Azure system routes.

### Controlled failure

A specific route was created:

```text
<ADMIN-PUBLIC-IP>/32 → None
```

The route name was:

```text
drop-admin-public-ip
```

### Observed symptom

```text
Connection timed out
```

### Diagnosis

The NIC effective route table showed both:

```text
Default   Active   0.0.0.0/0          Internet
User      Active   <PUBLIC-IP>/32      None
```

For traffic destined to the administrator's public IP, both routes matched.

The `/32` route was more specific than `/0`, so Azure selected it.

This demonstrated longest prefix match:

```text
0.0.0.0/0
    vs
<PUBLIC-IP>/32
        ↓
/32 wins
        ↓
NextHopType: None
        ↓
Packet dropped
```

### Root cause

The SSH request could reach the VM, but return traffic destined for the administrator matched the more specific `/32 → None` UDR and was discarded.

### Fix

The temporary `/32 → None` route was deleted.

### Verification

SSH connectivity returned immediately after removing the problematic UDR.

### Cleanup

The temporary route table was then:

```text
detached from subnet-azsl-01
        ↓
deleted
```

The original Azure system route baseline was restored.

---

## NSG Failure vs Routing Failure

Phase 2 and Phase 3 intentionally produced the same visible symptom:

```text
SSH connection timed out
```

but the root causes were different.

### NSG failure

```text
Inbound packet
    ↓
NSG rule evaluation
    ↓
Higher-priority Deny
    ↓
Packet blocked
```

Useful evidence:

```text
Effective security rules
Network Watcher IP flow verify
```

### Routing failure

```text
Return packet
    ↓
Route lookup
    ↓
More-specific /32 UDR
    ↓
NextHopType None
    ↓
Packet dropped
```

Useful evidence:

```text
Subnet route table association
Configured routes
NIC effective routes
Prefix specificity
Next hop
```

The support lesson is:

```text
Same symptom ≠ same root cause
```

---

## Azure Networking Concepts Practiced So Far

```text
Virtual Network
Subnet
Network Interface
Public IP
IP configuration
Dynamic private IP allocation

Network Security Group
├── Inbound rules
├── Outbound rules
├── Rule priority
├── Default rules
└── Effective security rules

Network Watcher
└── IP flow verify

Routing
├── Azure system routes
├── Route tables
├── User-Defined Routes
├── Effective routes
├── Longest prefix match
└── Next hop
    ├── VnetLocal
    ├── Internet
    └── None
```

---

## Current Cleanup State

Temporary Phase 2 resource:

```text
deny-ssh-lab → deleted
```

Temporary Phase 3 resources:

```text
drop-admin-public-ip → deleted
rt-azsl-lab04        → detached
rt-azsl-lab04        → deleted
```

Retained networking state:

```text
nsg-azsl-01
└── allow-ssh-myip
    ├── Inbound
    ├── TCP/22
    ├── Source: current administrator public IPv4 /32
    └── Priority: 1000

subnet-azsl-01
├── Subnet-level NSG: none
├── Custom route table: none
└── Active UDRs: none

Effective routing
├── VNet prefix → VnetLocal
├── 0.0.0.0/0 → Internet
└── Azure default reserved/special routes
```

SSH connectivity is currently working.

---

## Documentation

```text
labs/04-networking-connectivity-troubleshooting/
├── README.md
├── LAB04_PHASE1_NETWORKING_BASELINE_INSPECTION.md
├── LAB04_PHASE2_NSG_CONNECTIVITY_TROUBLESHOOTING.md
├── LAB04_PHASE3_ROUTING_AND_UDR_TROUBLESHOOTING.md
└── LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md
```

---

## Next Phase

**Phase 4 — VNet Peering & Private Connectivity Troubleshooting**

Planned direction:

```text
Inspect current VNet address space
        ↓
Create non-overlapping second VNet
        ↓
Create temporary second VM
        ↓
Establish VNet peering
        ↓
Test private connectivity
        ↓
Inspect effective routes
        ↓
Introduce one controlled peering/connectivity failure
        ↓
Diagnose before fixing
        ↓
Restore connectivity
        ↓
Delete temporary resources
```

The second VM and second VNet are temporary Lab 04 resources and should be removed after the peering exercise unless they are immediately reused by another networking scenario.
