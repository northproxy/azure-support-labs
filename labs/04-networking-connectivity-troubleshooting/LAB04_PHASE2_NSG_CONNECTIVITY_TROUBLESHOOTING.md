# Lab 04 — Phase 2: NSG Connectivity Troubleshooting

## Purpose

Practice a controlled Azure Network Security Group connectivity failure and diagnose it using effective security rules and Network Watcher before applying a fix.

This phase follows the project troubleshooting cycle:

```text
Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete
```

The exercise intentionally changes only one networking component at a time.

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

Networking baseline:

```text
NSG attachment:        NIC level
Subnet NSG:            none
Subnet route table:    none
Effective routes:      Azure system routes
SSH rule:              allow-ssh-myip
SSH protocol:          TCP
SSH destination port:  22
SSH source:            administrator public IPv4 /32
SSH rule priority:     1000
```

The VM was started temporarily for runtime connectivity testing.

---

## Pre-Lab Real Troubleshooting Incident

Before creating the planned controlled failure, SSH connectivity unexpectedly failed.

Observed symptom:

```text
ssh: connect to host <PUBLIC-IP> port 22: Connection timed out
```

Investigation showed that the administrator's external public IPv4 address had changed while the NSG rule still allowed the previous `/32` address.

The existing rule was updated with the current public IPv4 address and SSH connectivity was restored.

This incident is documented separately:

```text
LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md
```

This real incident was resolved before beginning the controlled NSG failure exercise.

---

## Build / Observe — Confirm Working SSH Baseline

The VM was confirmed running and SSH connectivity was tested successfully.

Existing NSG SSH rule:

```text
Name:      allow-ssh-myip
Priority:  1000
Direction: Inbound
Access:    Allow
Protocol:  TCP
Source:    <PUBLIC-IP>/32
Port:      22
```

The working path was therefore:

```text
Administrator
    ↓
Public IPv4
    ↓
Azure Public IP
    ↓
NIC
    ↓
NSG
    ↓
allow-ssh-myip
    ↓
TCP/22 allowed
    ↓
VM SSH service
```

This established a known-good baseline before introducing any failure.

---

# Controlled Failure

## Break — Create Higher-Priority SSH Deny Rule

A temporary NSG rule was created:

```text
Name:      deny-ssh-lab
Priority:  900
Direction: Inbound
Access:    Deny
Protocol:  TCP
Source:    administrator public IPv4 /32
Port:      22
```

Azure CLI:

```powershell
az network nsg rule create `
  --resource-group rg-azsl-01 `
  --nsg-name nsg-azsl-01 `
  --name deny-ssh-lab `
  --priority 900 `
  --direction Inbound `
  --access Deny `
  --protocol Tcp `
  --source-address-prefixes "$currentIp/32" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 22
```

The relevant NSG rule order became:

```text
Priority 900
deny-ssh-lab
Deny TCP/22
        ↓
Priority 1000
allow-ssh-myip
Allow TCP/22
```

Because Azure evaluates NSG rules by priority and lower numbers are evaluated first, the deny rule took precedence over the existing allow rule.

---

## Observe — Reproduce the Failure

SSH was tested again.

Result:

```text
Connection timed out
```

The controlled connectivity failure was successfully reproduced.

At this point no further configuration changes were made.

The failure was diagnosed before applying a fix.

---

# Diagnose

## Step 1 — Inspect Effective Security Rules

Effective NSG configuration was inspected on the VM NIC:

```powershell
az network nic list-effective-nsg `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  -o json
```

Relevant effective rules:

```json
{
  "access": "Deny",
  "destinationAddressPrefix": "0.0.0.0/0",
  "destinationPortRange": "22-22",
  "direction": "Inbound",
  "name": "securityRules/deny-ssh-lab",
  "priority": 900,
  "protocol": "Tcp",
  "sourceAddressPrefix": "<PUBLIC-IP>/32",
  "sourcePortRange": "0-65535"
}
```

and:

```json
{
  "access": "Allow",
  "destinationAddressPrefix": "0.0.0.0/0",
  "destinationPortRange": "22-22",
  "direction": "Inbound",
  "name": "securityRules/allow-ssh-myip",
  "priority": 1000,
  "protocol": "Tcp",
  "sourceAddressPrefix": "<PUBLIC-IP>/32",
  "sourcePortRange": "0-65535"
}
```

This confirmed that both rules were active on the NIC and that the deny rule had the higher evaluation priority.

Effective rule evaluation:

```text
Inbound TCP/22
    ↓
deny-ssh-lab
priority 900
    ↓
MATCH
    ↓
Deny
    ↓
allow-ssh-myip
priority 1000
not reached
```

---

## Step 2 — Verify the Packet Decision with Network Watcher

The VM private IP was retrieved:

```powershell
$privateIp = az network nic show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01284 `
  --query "ipConfigurations[0].privateIPAddress" `
  -o tsv
```

Network Watcher IP flow verification was then used to test a simulated inbound SSH flow:

```powershell
az network watcher test-ip-flow `
  --resource-group rg-azsl-01 `
  --vm vm-azsl-01 `
  --nic vm-azsl-01284 `
  --direction Inbound `
  --protocol TCP `
  --local "$privateIp`:22" `
  --remote "$currentIp`:50000" `
  -o table
```

Observed result:

```text
Access    RuleName
--------  --------------------------
Deny      securityRules/deny-ssh-lab
```

This directly identified the NSG rule responsible for blocking the connection.

---

# Root Cause

The temporary `deny-ssh-lab` rule matched the same inbound SSH flow as the existing allow rule but had a higher precedence because of its lower numeric priority.

```text
deny-ssh-lab
priority 900
Deny
```

was evaluated before:

```text
allow-ssh-myip
priority 1000
Allow
```

Therefore the inbound SSH packet was denied before Azure reached the allow rule.

The failure was not caused by:

```text
VM power state
Public IP configuration
VNet routing
Subnet routing
SSH service authentication
```

The Network Watcher result directly confirmed the NSG rule as the cause.

---

# Fix

Only the temporary failure rule was removed:

```powershell
az network nsg rule delete `
  --resource-group rg-azsl-01 `
  --nsg-name nsg-azsl-01 `
  --name deny-ssh-lab
```

The original secure SSH rule was left unchanged:

```text
allow-ssh-myip
TCP/22
Source: administrator public IPv4 /32
Priority: 1000
```

---

# Verify

After removing `deny-ssh-lab`, the expected NSG decision returned to:

```text
Inbound TCP/22
    ↓
allow-ssh-myip
priority 1000
    ↓
Allow
```

SSH was tested again.

Result:

```text
SSH connection opened successfully.
```

Connectivity was therefore fully restored.

---

# Troubleshooting Model Learned

A useful diagnostic sequence for an Azure VM SSH timeout is:

```text
SSH timeout
    ↓
Confirm VM is running
    ↓
Confirm Public IP
    ↓
Inspect NSG attachment
    ↓
Inspect configured NSG rules
    ↓
Inspect effective security rules
    ↓
Check priority and rule overlap
    ↓
Use Network Watcher IP flow verify
    ↓
Identify exact Allow/Deny rule
    ↓
Fix only the responsible configuration
    ↓
Retest connectivity
```

---

# Key Lessons

## NSG Priority Matters

Azure evaluates NSG rules using their numeric priority.

```text
Lower number = evaluated first
```

For example:

```text
900  Deny
1000 Allow
```

results in the deny rule winning when both match the same traffic.

---

## Configured Rules and Effective Rules Are Different Views

The NSG resource shows what has been configured.

Effective security rules show what actually applies to a particular NIC after Azure combines applicable NSG configuration.

Effective configuration is therefore especially useful during troubleshooting.

---

## Diagnose Before Fixing

Deleting the deny rule immediately after the SSH timeout would have restored connectivity but would not have demonstrated why the connection failed.

Using:

```text
effective NSG rules
```

and:

```text
Network Watcher IP flow verify
```

provided evidence before remediation.

---

## IP Flow Verify Gives a Direct Packet Decision

Network Watcher IP flow verify can evaluate a specific combination of:

```text
direction
protocol
local IP
local port
remote IP
remote port
```

and identify the NSG rule responsible for the resulting:

```text
Allow
```

or:

```text
Deny
```

decision.

This makes it useful for support scenarios where multiple NSG rules may overlap.

---

## Restrictive SSH Rules Require Source IP Awareness

The retained SSH rule uses a single administrator public IPv4 `/32`.

This reduces exposure compared with allowing:

```text
0.0.0.0/0
```

but connectivity can fail if the administrator's public IP changes.

That scenario is documented separately in:

```text
LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md
```

---

# Cleanup

Temporary controlled-failure resource:

```text
deny-ssh-lab → deleted
```

Retained configuration:

```text
nsg-azsl-01
└── allow-ssh-myip
    ├── Inbound
    ├── TCP
    ├── Port 22
    ├── Source: current administrator public IPv4 /32
    └── Priority 1000
```

No route tables, subnet NSGs, additional NICs, or other networking configuration were modified during this phase.

---

# Phase Result

Phase 2 successfully demonstrated:

```text
Working SSH baseline
        ↓
Controlled NSG failure
        ↓
SSH timeout
        ↓
Effective security rule inspection
        ↓
Priority conflict identified
        ↓
Network Watcher IP flow verification
        ↓
Exact blocking rule identified
        ↓
Temporary rule removed
        ↓
SSH connectivity restored
```

## Status

```text
Lab 04 — Phase 2: completed
```

## Next

```text
Lab 04 — Phase 3
Routing and User-Defined Route Troubleshooting
```