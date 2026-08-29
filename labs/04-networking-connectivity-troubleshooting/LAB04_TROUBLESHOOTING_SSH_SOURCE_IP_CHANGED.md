# Lab 04 — Troubleshooting Note: SSH Failure After Client Public IP Change

## Scenario

SSH connectivity to the Azure VM unexpectedly stopped working.

The VM had previously been accessible through:

```text
TCP/22
```

The Network Security Group contained a restrictive inbound rule:

```text
Rule:      allow-ssh-myip
Direction: Inbound
Protocol:  TCP
Port:      22
Source:    one public IPv4 address /32
Action:    Allow
Priority:  1000
```

The rule intentionally allowed SSH only from the administrator's current public IPv4 address.

---

## Symptom

SSH connection attempt:

```text
ssh: connect to host <PUBLIC-IP> port 22: Connection timed out
```

The timeout indicated that the TCP connection was not reaching the SSH service successfully.

No NSG changes had intentionally been made before the failure occurred.

---

## Investigation

The following areas were checked before modifying the network configuration:

1. VM power state
2. Azure Public IP assignment
3. Existing NSG SSH rule
4. Current public IPv4 address of the client machine

The client's current public IPv4 address was obtained with PowerShell:

```powershell
$currentIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()

$currentIp
```

The result was compared with the source prefix configured in:

```text
allow-ssh-myip
```

The addresses did not match.

---

## Root Cause

The administrator's public IPv4 address had changed.

The NSG rule still contained the previous address:

```text
Old client public IP
        ↓
allow-ssh-myip
Source: <OLD-IP>/32
```

The actual connection originated from:

```text
<NEW-IP>
```

Because `<NEW-IP>/32` did not match the explicit SSH Allow rule, the packet eventually matched the default inbound deny behavior.

Conceptually:

```text
Administrator workstation
        ↓
New public IPv4 address
        ↓
Azure Public IP
        ↓
NIC
        ↓
NSG
        ↓
allow-ssh-myip
Source does not match
        ↓
Default DenyAllInbound
        ↓
Packet dropped
        ↓
SSH timeout
```

---

## Fix

The existing NSG rule was updated instead of creating a broader SSH rule.

First, retrieve the current public IPv4 address:

```powershell
$currentIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
```

Then update the existing NSG rule:

```powershell
az network nsg rule update `
  --resource-group rg-azsl-01 `
  --nsg-name nsg-azsl-01 `
  --name allow-ssh-myip `
  --source-address-prefixes "$currentIp/32"
```

---

## Verification

Inspect the resulting rule:

```powershell
az network nsg rule show `
  --resource-group rg-azsl-01 `
  --nsg-name nsg-azsl-01 `
  --name allow-ssh-myip `
  --query "{Priority:priority,Access:access,Source:sourceAddressPrefix,Port:destinationPortRange}" `
  -o table
```

Expected characteristics:

```text
Priority: 1000
Access:   Allow
Source:   <CURRENT-PUBLIC-IP>/32
Port:     22
```

SSH connectivity was then tested again:

```powershell
ssh -i <path-to-private-key> azureuser@<vm-public-ip>
```

Result:

```text
SSH connectivity restored successfully.
```

---

## Support Lesson

When SSH to an Azure VM suddenly times out and the NSG permits TCP/22 only from a specific `/32` address, check whether the administrator's public IP has changed before modifying other networking components.

Useful diagnostic sequence:

```text
SSH timeout
    ↓
Check VM state
    ↓
Check VM Public IP
    ↓
Inspect NSG SSH rule
    ↓
Determine current client public IP
    ↓
Compare with NSG source /32
    ↓
Update the existing rule if required
    ↓
Verify SSH
```

Do not immediately change the SSH source to:

```text
0.0.0.0/0
```

A narrow `/32` source remains preferable for this lab because it limits SSH exposure to the current administrative public IP.

---

## Quick Recovery Procedure

If this problem occurs again:

```powershell
$currentIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()

az network nsg rule update `
  --resource-group rg-azsl-01 `
  --nsg-name nsg-azsl-01 `
  --name allow-ssh-myip `
  --source-address-prefixes "$currentIp/32"
```

Then retry SSH.

---

## Troubleshooting Classification

```text
Layer:        Network access control
Azure object: Network Security Group
Direction:    Inbound
Protocol:     TCP
Port:         22
Root cause:   Client public IP changed
Fix:          Update NSG source /32
Result:       Connectivity restored
```

## Lifecycle

Permanent troubleshooting documentation.

The Azure configuration change itself is part of the retained secure networking baseline.