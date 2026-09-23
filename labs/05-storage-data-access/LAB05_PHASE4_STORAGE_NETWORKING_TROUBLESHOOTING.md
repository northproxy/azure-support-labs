# Lab 05 — Phase 4: Storage Networking Troubleshooting

## Status

**Completed**

## Purpose

Practice Azure Storage network-access troubleshooting and clearly distinguish a Storage firewall or network-path failure from authentication and Blob data-plane authorization failures.

This phase follows the project troubleshooting method:

**Observe symptom → Collect evidence → Form hypothesis → Verify hypothesis → Change one thing → Retest**

## Starting Baseline

Reused Azure resources:

```text
Resource Group:     rg-azsl-01
Storage Account:    stazsl05npx01
Blob Container:     azsl05-data
Test Blob:          hello-storage.txt

VM:                 vm-azsl-01
VNet:               vnet-azsl-01
Subnet:             subnet-azsl-01
```

Storage access baseline:

```text
Public network access:  Enabled
Default network action: Allow
IP rules:               none
VNet rules:             none
Service endpoints:      none

Current Blob role:      Storage Blob Data Reader
Role scope:             container azsl05-data
```

The Blob was readable through Microsoft Entra authentication before any networking changes were introduced.

---

## 1. Inspect Storage Network Baseline

The Storage Account network rule set was inspected:

```powershell
az storage account show `
  --resource-group $rg `
  --name $storage `
  --query networkRuleSet
```

Observed baseline:

```json
{
  "bypass": "AzureServices",
  "defaultAction": "Allow",
  "ipRules": [],
  "ipv6Rules": [],
  "resourceAccessRules": null,
  "virtualNetworkRules": []
}
```

Public network access was also confirmed:

```powershell
az storage account show `
  --resource-group $rg `
  --name $storage `
  --query publicNetworkAccess
```

Result:

```text
"Enabled"
```

### Finding

At this point:

- the Storage public endpoint was enabled;
- the Storage firewall default action was `Allow`;
- no IP rule was required;
- no virtual network rule was required;
- Blob access was not restricted by source network.

---

## 2. Verify Known-Good Blob Read

Before changing the network policy, the test Blob was downloaded with Microsoft Entra authentication:

```powershell
az storage blob download `
  --account-name $storage `
  --container-name "azsl05-data" `
  --name "hello-storage.txt" `
  --file ".\hello-storage-phase4.txt" `
  --auth-mode login
```

The test content remained:

```text
Hello from Azure Support Labs - Lab 05 Phase 2
```

### Known-good state

```text
Authentication:      working
Blob RBAC:           working
Blob data:           present
Network path:        working
```

This was important because it established a valid data-plane baseline before the controlled failure.

---

## 3. Create a Controlled Storage Firewall Failure

Only one configuration item was changed:

```powershell
az storage account update `
  --resource-group $rg `
  --name $storage `
  --default-action Deny
```

The resulting network rule set showed:

```json
{
  "bypass": "AzureServices",
  "defaultAction": "Deny",
  "ipRules": [],
  "ipv6Rules": [],
  "resourceAccessRules": null,
  "virtualNetworkRules": []
}
```

The same Blob read was then attempted again.

Azure CLI reported:

```text
The request may be blocked by network rules of storage account.
Please check network rule set using 'az storage account show -n accountname --query networkRuleSet'.
If you want to change the default action to apply when no rule matches,
please use 'az storage account update'.
```

### Diagnosis

The failure was attributed to the Storage network layer because:

```text
Authentication:      unchanged
Blob RBAC:           unchanged
Blob/container:      unchanged
Blob command:        unchanged
Network policy:      changed from Allow to Deny
```

Therefore the working diagnosis was:

> Blob read was blocked by Storage Account network rules, not by Microsoft Entra authentication or Blob RBAC.

This contrasted directly with Phase 3, where the controlled failure was caused by Blob data-plane authorization.

---

## 4. Restore Access with an IP Rule

The administrator's current public IPv4 address was identified and added as an explicit Storage firewall rule.

Example:

```powershell
$myIp = (Invoke-WebRequest -Uri "https://api.ipify.org").Content.Trim()
```

The IP rule was added:

```powershell
az storage account network-rule add `
  --resource-group $rg `
  --account-name $storage `
  --ip-address $myIp
```

The Storage Account remained:

```text
Default action: Deny
```

but now contained a matching IP rule.

The same Blob read succeeded again.

### Verified behavior

```text
DefaultAction = Deny
No matching rule
→ Blob read blocked

DefaultAction = Deny
Matching public IP rule
→ Blob read allowed
```

This demonstrated that a correct identity and valid Blob role are still subject to Storage network restrictions.

---

## 5. Configure a Microsoft.Storage Service Endpoint

A second networking scenario was created using the retained Azure VM and subnet.

The existing subnet was inspected:

```powershell
az network vnet subnet show `
  --resource-group $rg `
  --vnet-name $vnet `
  --name $subnet `
  --query serviceEndpoints
```

The `Microsoft.Storage` service endpoint was enabled on:

```text
vnet-azsl-01
└── subnet-azsl-01
```

Verification result:

```json
[
  {
    "locations": [
      "austriaeast"
    ],
    "provisioningState": "Succeeded",
    "service": "Microsoft.Storage"
  }
]
```

The subnet resource ID was collected:

```powershell
$subnetId = az network vnet subnet show `
  --resource-group $rg `
  --vnet-name $vnet `
  --name $subnet `
  --query id `
  -o tsv
```

The subnet was then added as a Storage virtual network rule:

```powershell
az storage account network-rule add `
  --resource-group $rg `
  --account-name $storage `
  --subnet $subnetId
```

At this stage the Storage firewall still used:

```text
DefaultAction = Deny
```

and the allowed Azure source was:

```text
subnet-azsl-01
```

---

## 6. Test Blob Access from the Azure VM

The retained VM was started:

```powershell
az vm start `
  --resource-group $rg `
  --name "vm-azsl-01"
```

The intended test path was:

```text
vm-azsl-01
    ↓
subnet-azsl-01
    ↓
Microsoft.Storage service endpoint
    ↓
Storage public endpoint
    ↓
Storage VNet rule
    ↓
Blob
```

A direct SSH attempt failed with:

```text
Permission denied (publickey).
```

This was correctly treated as an independent SSH authentication issue rather than a Storage networking issue.

Azure VM Run Command was used instead.

Run Command itself was verified first:

```powershell
az vm run-command invoke `
  --resource-group $rg `
  --name "vm-azsl-01" `
  --command-id RunShellScript `
  --scripts "echo PHASE4-RUN-COMMAND-OK"
```

Result:

```text
PHASE4-RUN-COMMAND-OK
```

---

## 7. Use the Same SAS Credential for a Network-Only Comparison

A temporary read-only Blob SAS was generated for the test Blob.

The same Blob URL and same SAS credential were intended to be used from both the administrator workstation and the Azure VM so that the principal test variable was the source network.

Because SAS URLs contain shell-sensitive characters such as:

```text
?
&
%
```

passing the URL through:

```text
PowerShell → Azure CLI → Run Command → bash
```

initially caused:

```text
curl: (3) URL rejected: Malformed input to a URL function
```

This was diagnosed as a command-line quoting and transport problem rather than an Azure Storage failure.

The SAS URL was then encoded locally with Base64 and decoded inside the VM.

A verification command confirmed that the URL reached the VM successfully:

```text
183
```

decoded bytes.

This separated URL transport problems from Storage networking behavior.

---

## 8. Verify VM-to-Blob Access Through the Allowed Subnet

The Blob was requested from inside `vm-azsl-01` through Azure Run Command.

The VM successfully retrieved:

```text
Hello from Azure Support Labs - Lab 05 Phase 2
```

### Verified data path

```text
vm-azsl-01
    ↓
subnet-azsl-01
    ↓
Microsoft.Storage service endpoint
    ↓
matching Storage VNet rule
    ↓
Blob access allowed
```

This proved that the VM could access the Storage Account from the allowed subnet while the Storage firewall used `DefaultAction = Deny`.

### Important distinction

A service endpoint did **not** create a Private Endpoint.

The test still used the normal Storage service endpoint, but Azure recognized the request as originating from the authorized virtual network subnet.

---

## 9. Troubleshooting Side Incidents

Several unrelated failures occurred during the exercise.

They were intentionally kept separate from the Storage network diagnosis.

### SSH authentication failure

Observed:

```text
Permission denied (publickey).
```

Classification:

```text
Laptop → VM
SSH authentication problem
```

Not:

```text
VM → Storage
Storage networking problem
```

### SAS URL quoting failure

Observed:

```text
curl: (3) URL rejected: Malformed input to a URL function
```

Cause:

- SAS URL contained shell-sensitive characters;
- URL passed through multiple command interpreters;
- quoting was not preserved.

Resolution:

- encode URL locally with Base64;
- decode inside the VM;
- avoid exposing the SAS token in troubleshooting output.

### Empty Run Command output

Some multi-line Run Command attempts completed successfully but produced no expected stdout.

A minimal test:

```text
echo PHASE4-RUN-COMMAND-OK
```

confirmed that Run Command itself worked.

The problem was narrowed to shell escaping in the supplied script rather than Azure VM Agent or Storage.

### Support lesson

A troubleshooting investigation can contain multiple simultaneous problems.

Each symptom should be classified according to its layer before changing infrastructure.

---

## 10. Cleanup

All temporary Storage network restrictions were removed.

The Storage virtual network rule was removed.

The `Microsoft.Storage` service endpoint was removed from `subnet-azsl-01`.

The Storage firewall default action was restored:

```text
Allow
```

The temporary public IP rule was removed.

Final Storage network rule set:

```json
{
  "bypass": "AzureServices",
  "defaultAction": "Allow",
  "ipRules": [],
  "ipv6Rules": [],
  "resourceAccessRules": null,
  "virtualNetworkRules": []
}
```

Final subnet service endpoint configuration:

```json
[]
```

The retained VM was deallocated:

```text
Provisioning succeeded
VM deallocated
```

---

## Final Baseline

```text
Storage Account:        stazsl05npx01
Resource Group:         rg-azsl-01
Public network access:  Enabled
Default action:         Allow
IP rules:               none
VNet rules:             none
Service endpoints:      none

Blob Container:         azsl05-data
Test Blob:              hello-storage.txt

VM:                     vm-azsl-01
VM state:               deallocated
```

The retained Azure baseline was restored after the exercise.

---

## Key Findings

### Storage authorization and Storage networking are independent gates

A request may have:

```text
valid authentication
+
valid Blob data-plane RBAC
+
existing Blob
```

and still fail because the Storage network layer blocks the source.

### `DefaultAction = Deny` changes the troubleshooting model

With no matching rule:

```text
Storage public endpoint exists
+
identity is valid
+
Blob permission is valid
+
source network is not allowed
→ request denied
```

### IP rules and VNet rules solve different source-access scenarios

Public IP rule:

```text
administrator workstation
→ public IPv4
→ Storage firewall
```

Virtual network rule:

```text
Azure VM
→ allowed subnet
→ Microsoft.Storage service endpoint
→ Storage firewall
```

### A service endpoint is not a Private Endpoint

The Phase 4 exercise used a Storage service endpoint and VNet rule.

No Private Endpoint or private IP address was created.

### Troubleshoot by layer

The practical support model reinforced during this phase is:

```text
1. Confirm object exists.
2. Confirm authentication.
3. Confirm data-plane authorization.
4. Inspect Storage public network access.
5. Inspect default network action.
6. Inspect matching IP or VNet rules.
7. Inspect service endpoint configuration where applicable.
8. Retest after changing one thing.
```

---

## Phase Completion

Phase 4 completed:

```text
[x] Storage network baseline inspected
[x] Controlled Storage firewall denial created
[x] Network denial distinguished from RBAC failure
[x] Public IP allow rule tested
[x] Microsoft.Storage service endpoint configured
[x] Storage VNet rule configured
[x] VM-to-Blob access verified from allowed subnet
[x] SSH and shell/SAS side incidents isolated correctly
[x] Temporary network configuration removed
[x] Storage baseline restored
[x] Retained VM returned to deallocated
```

Next:

**Phase 5 — Azure Files**
