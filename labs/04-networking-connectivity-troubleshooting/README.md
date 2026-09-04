# Lab 04 — Azure Networking & Connectivity Troubleshooting

## Status

**In progress**

Completed so far:

```text
Phase 1 — Networking Baseline Inspection
Phase 2 — NSG Connectivity Troubleshooting
Phase 3 — Routing and User-Defined Route Troubleshooting
Phase 4 — VNet Peering & Private Connectivity Troubleshooting
```

Current:

```text
Phase 5 — Azure Load Balancer & Backend Connectivity Troubleshooting
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
- understand Azure Load Balancer frontend IP configuration, backend pools, health probes, and load-balancing rules;
- diagnose backend availability and quota-related deployment failures;
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


## Phase 4 — VNet Peering & Private Connectivity Troubleshooting

File:

[`LAB04_PHASE4_VNET_PEERING_PRIVATE_CONNECTIVITY_TROUBLESHOOTING.md`](LAB04_PHASE4_VNET_PEERING_PRIVATE_CONNECTIVITY_TROUBLESHOOTING.md)

### Build and baseline validation

- inspected the existing VNet address space;
- selected a non-overlapping CIDR for a temporary second VNet;
- created `vnet-azsl-peer` and `subnet-azsl-peer`;
- created a temporary private-only VM without a Public IP;
- confirmed there was no private connectivity before peering.

### Peering configuration

Bidirectional VNet peering was created.

Both peering objects reached:

```text
PeeringState: Connected
ProvisioningState: Succeeded
```

Private ICMP and TCP/22 connectivity were verified across the peering.

The effective route table showed the remote VNet prefix with:

```text
NextHopType: VNetPeering
```

### Controlled failure

One side of the VNet peering was deleted.

The remaining side moved to:

```text
Disconnected
```

Private ICMP and TCP/22 connectivity failed, and the `VNetPeering` effective route disappeared.

### Diagnosis

An attempt to recreate only one side produced:

```text
RemotePeeringIsDisconnected
```

The disconnected peering object had to be removed before the relationship could be recreated cleanly.

### Fix and verification

Both peering objects were recreated.

Verification confirmed:

```text
Connected / Succeeded
private ICMP connectivity restored
private TCP/22 connectivity restored
VNetPeering effective route restored
```

### Cleanup

All temporary Phase 4 resources were deleted.

The retained baseline was verified through Azure CLI.

---

## Phase 5 — Azure Load Balancer & Backend Connectivity Troubleshooting

Phase 5 is split into four logical blocks so that deployment constraints, guest preparation, Load Balancer construction, and connectivity troubleshooting remain separate support stories.

### Phase 5A — Load Balancer Preparation & Quota Troubleshooting

File:

[`LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md`](LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md)

Completed:

- selected an isolated two-backend topology while retaining `vm-azsl-01` outside the Load Balancer pool;
- diagnosed regional vCPU quota exhaustion;
- confirmed the subscription was not eligible for a quota increase;
- investigated subscription/region/zone SKU restrictions;
- selected `Standard_D1_v2` as a usable 1-vCPU backend size;
- diagnosed Hyper-V generation incompatibility with the first Ubuntu image choice;
- switched to `Canonical:ubuntu-24_04-lts:server-gen1:latest`;
- created `vm-azsl-lb-01` and `vm-azsl-lb-02` as private-only backend VMs.

### Phase 5B — Backend Service Preparation

File:

[`LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md`](LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md)

Completed:

- installed nginx on both backend VMs;
- differentiated each backend response;
- verified nginx service state and local HTTP responses;
- diagnosed a Run Command case where provisioning succeeded but the intended multi-line guest script did not fully produce the expected state;
- established a known-good application baseline before introducing the Load Balancer.

### Phase 5C — Standard Public Load Balancer Build & Verification

File:

[`LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md`](LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md)

Completed:

```text
pip-azsl-lb-01
        |
        v
fe-azsl-lb-01
        |
        v
lbr-azsl-http-80
        |
        +--> hp-azsl-lb-http
        |
        v
bp-azsl-lb-01
   ├── vm-azsl-lb-01
   └── vm-azsl-lb-02
```

- created a Standard regional Public IP;
- created `lb-azsl-01`;
- configured the frontend, backend pool, HTTP health probe, and TCP/80 rule;
- verified all Load Balancer references and provisioning state with Azure CLI.

### Phase 5D — Load Balancer Backend Connectivity Troubleshooting

File:

[`LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md`](LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md)

Current block: **in progress**.

Completed so far:

- reproduced an external TCP/80 timeout through the newly created Standard Public Load Balancer;
- verified the Public IP/frontend association;
- verified backend pool membership;
- verified the health probe and load-balancing rule references;
- verified nginx was active and listening on `0.0.0.0:80` on both VMs;
- localized the failure to the backend security path;
- created `nsg-azsl-lb-backend` rather than changing the retained NSG or shared subnet;
- created `allow-http-internet` for TCP/80;
- associated the NSG with both temporary backend NICs;
- verified external HTTP recovery;
- verified traffic distribution across both backends;
- tagged Phase 5 resources for safer Portal filtering and later cleanup.

Current next step:

```text
Stop nginx on vm-azsl-lb-02
        ↓
Observe health-probe convergence
        ↓
Verify frontend traffic is served only by vm-azsl-lb-01
        ↓
Diagnose the degraded backend
        ↓
Restore nginx
        ↓
Verify both backends return to service
        ↓
Delete temporary Phase 5 resources
```

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
├── VNet Peering
│   ├── Non-overlapping address spaces
│   ├── Connected / Disconnected state
│   ├── Private cross-VNet connectivity
│   └── RemotePeeringIsDisconnected troubleshooting
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
    ├── VNetPeering
    └── None

Azure Load Balancer
├── Standard SKU
├── Public frontend
├── Backend pool
├── Health probe
├── Load-balancing rule
└── Backend connectivity troubleshooting
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

Temporary Phase 4 resources:

```text
vnet-azsl-peer       → deleted
subnet-azsl-peer     → deleted with VNet
temporary peer VM    → deleted
VNet peerings        → deleted
```

Temporary Phase 5 preparation resources:

```text
initial vm-azsl-lb-01 (Standard_B2ats_v2) → deleted
temporary NIC                              → deleted
temporary OS disk                          → deleted
temporary SSH key                          → deleted
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

VNet peerings: none
Temporary peer VNet: none
Temporary peer VM: none
```

Current Phase 5 quota checkpoint:

```text
Total Regional vCPUs       2 / 4
Standard Dv2 Family vCPUs  0 / 4
```

SSH connectivity to the retained VM is working.

---

## Documentation

```text
labs/04-networking-connectivity-troubleshooting/
├── README.md
├── LAB04_PHASE1_NETWORKING_BASELINE_INSPECTION.md
├── LAB04_PHASE2_NSG_CONNECTIVITY_TROUBLESHOOTING.md
├── LAB04_PHASE3_ROUTING_AND_UDR_TROUBLESHOOTING.md
├── LAB04_PHASE4_VNET_PEERING_PRIVATE_CONNECTIVITY_TROUBLESHOOTING.md
├── LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md
├── LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md
├── LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md
├── LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md
└── LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md
```

---

## Current Next Step

Phase 5D is the active block.

```text
Controlled backend failure
        ↓
Health-probe observation
        ↓
Traffic failover verification
        ↓
Backend recovery
        ↓
Final Phase 5 cleanup
```
