# Lab 02 — Phase 5: ARM-based Deployment

Status: **completed**

## Purpose

Understand Azure Resource Manager deployment fundamentals and practice a small, controlled ARM template deployment in the retained Lab 02 Resource Group.

This phase focused on declarative deployment, template structure, parameters, resource declarations, deployment validation, repeatability, desired-state updates, deployment history, controlled failure, troubleshooting, recovery, and cleanup.

---

## Starting baseline

```text
Resource Group:       rg-azsl-01
VM:                   vm-azsl-01
VM size:              Standard_B2ats_v2
Provisioning state:   Succeeded
Power state:          VM deallocated
OS disk:              30 GiB StandardSSD_LRS
Data disks:           none
```

The existing VM infrastructure was intentionally kept outside the first ARM template.

---

# Phase 5A — ARM Template Fundamentals / Prepare

Status: **completed**

## ARM mental model

Azure Portal, Azure CLI, Azure PowerShell, and ARM templates all operate through the Azure control plane.

```text
Azure Portal
Azure CLI
Azure PowerShell
ARM Template
        │
        ▼
Azure Resource Manager
        │
        ▼
Resource Providers
        │
        ▼
Azure Resources
```

Azure CLI and Azure PowerShell do not manage Azure resources directly. They send requests through Azure Resource Manager.

Example:

```text
Stop-AzVM
    ↓
Azure PowerShell
    ↓
Azure Resource Manager
    ↓
Microsoft.Compute
    ↓
Virtual Machine
```

ARM templates use a declarative model:

```text
Azure CLI / PowerShell
    "Perform this operation."

ARM template
    "Make Azure look like this."
```

---

## ARM template structure

The following top-level sections were studied:

```json
{
  "$schema": "...",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {},
  "resources": [],
  "outputs": {}
}
```

Key roles:

```text
$schema         → template schema
contentVersion  → template content version
parameters      → deployment input
variables       → internal reusable values
resources       → resource declarations
outputs         → deployment output values
```

The `resources` section is the central declaration area for Azure resources.

---

## Resource types and Resource Providers

Example:

```text
Microsoft.Network/networkInterfaces
```

Meaning:

```text
Microsoft.Network  → Resource Provider namespace
networkInterfaces  → resource type
```

Other familiar resource types:

```text
Microsoft.Compute/virtualMachines
Microsoft.Network/virtualNetworks
Microsoft.Network/networkSecurityGroups
Microsoft.Storage/storageAccounts
```

---

## `apiVersion`

`apiVersion` identifies the Azure Resource Manager API version used for a particular resource type.

It is not the VM version, operating system version, or Storage Account version.

```text
resource type
    ↓
apiVersion
    ↓
Resource Provider API version
```

---

## Dependencies

ARM uses dependencies to determine a valid deployment order.

Example:

```text
VNet
  ↓
Subnet
  ↓
NIC
  ↓
VM
```

Two dependency concepts were introduced:

```text
explicit dependency
implicit dependency
```

The first controlled deployment used one independent resource and therefore required no `dependsOn`.

---

## Deployment scope

ARM deployments run at a defined scope.

Common scopes:

```text
Tenant
Management Group
Subscription
Resource Group
```

The first deployment used Resource Group scope:

```text
rg-azsl-01
```

Important distinction:

```text
scope
→ where the deployment runs

resources
→ what the template manages
```

Deploying to `rg-azsl-01` did not require the template to describe the existing VM infrastructure.

---

## First deployment target

A temporary Storage Account was selected because it is small, inexpensive, independent, easy to inspect, and easy to remove.

```text
Resource type:  Microsoft.Storage/storageAccounts
Kind:           StorageV2
SKU:            Standard_LRS
Scope:          rg-azsl-01
Lifecycle:      temporary learning resource
```

Template files:

```text
templateStorage.json
parameters.json
```

The template used:

```json
"name": "[parameters('storageAccountName')]"
```

and:

```json
"location": "[resourceGroup().location]"
```

This demonstrated ARM expressions, parameter lookup, and the `resourceGroup()` template function.

---

# Phase 5B — First Controlled ARM Deployment

Status: **completed**

## Validation

The template was validated before deployment:

```powershell
az deployment group validate `
  --resource-group rg-azsl-01 `
  --template-file .\templateStorage.json `
  --parameters .\parameters.json
```

Validation returned:

```text
error:              null
provisioningState:  Succeeded
mode:               Incremental
```

The validation output also showed:

```text
Resource Provider:  Microsoft.Storage
Resource type:      storageAccounts
Location:           austriaeast
```

The future resource ID was resolved during validation without creating the resource.

---

## Initial deployment

The first real deployment was executed as:

```text
deploy-storage-arm-01
```

Created resource:

```text
Name:               stazslarm01284
Location:           austriaeast
Kind:               StorageV2
SKU:                Standard_LRS
ProvisioningState:  Succeeded
```

This confirmed the full path:

```text
parameters.json
      ↓
templateStorage.json
      ↓
Azure Resource Manager
      ↓
Microsoft.Storage
      ↓
storageAccounts
      ↓
stazslarm01284
```

---

## Deployment object vs resource object

The ARM deployment object was inspected separately from the Storage Account.

```text
Microsoft.Resources/deployments
└── deploy-storage-arm-01
```

The deployment object contained:

```text
mode
parameters
templateHash
timestamp
outputResources
provisioningState
```

The actual resource was:

```text
Microsoft.Storage/storageAccounts
└── stazslarm01284
```

Key distinction:

```text
deployment object
≠
resource object

deployment state
≠
resource state
```

The same deployment was also inspected through Azure Portal.

---

## Redeployment behavior

The same template and parameters were deployed again using:

```text
deploy-storage-arm-02
```

Both deployments completed successfully:

```text
deploy-storage-arm-01  → Succeeded
deploy-storage-arm-02  → Succeeded
```

Only one Storage Account existed:

```text
stazslarm01284
```

This demonstrated declarative redeployment behavior:

```text
desired state already exists
        ↓
ARM evaluates current state
        ↓
same resource remains
        ↓
no duplicate resource is created
```

---

## Desired-state update

The Storage Account template was updated with:

```json
"properties": {
  "minimumTlsVersion": "TLS1_2"
}
```

The template was validated and redeployed.

Result:

```text
Name:               stazslarm01284
Minimum TLS:        TLS1_2
ProvisioningState:  Succeeded
```

The same resource was updated instead of creating a new resource.

---

# Phase 5C — Parameters & Repeatability

Status: **completed**

The TLS configuration was parameterized:

```json
"minimumTlsVersion": {
  "type": "string",
  "defaultValue": "TLS1_2"
}
```

The Storage Account resource used:

```json
"minimumTlsVersion": "[parameters('minimumTlsVersion')]"
```

A parameter file was used to provide the value:

```json
"minimumTlsVersion": {
  "value": "TLS1_2"
}
```

The deployment completed successfully and the existing Storage Account remained in the expected state.

---

## `defaultValue`

`minimumTlsVersion` was then removed from `parameters.json`.

Because the template contained:

```json
"defaultValue": "TLS1_2"
```

the deployment still applied:

```text
minimumTlsVersion = TLS1_2
```

This confirmed:

```text
parameter supplied
→ ARM uses supplied value

parameter omitted
→ ARM uses defaultValue
```

---

# Phase 5D — Controlled Failure / Troubleshooting

Status: **completed**

A controlled template parameter validation failure was introduced.

The parameter definition was constrained with:

```json
"allowedValues": [
  "TLS1_0",
  "TLS1_1",
  "TLS1_2",
  "TLS1_3"
]
```

The parameter file intentionally supplied:

```text
TLS9_9
```

Validation returned:

```text
code: InvalidTemplate
```

The diagnostic message identified that `TLS9_9` was not part of the allowed value set.

The error also identified the template path:

```text
properties.template.parameters.minimumTlsVersion.allowedValues
```

Troubleshooting flow:

```text
Break
→ TLS9_9

Diagnose
→ InvalidTemplate

Root cause
→ parameter value violates allowedValues

Fix
→ TLS1_2

Verify
→ error: null
```

This demonstrated an ARM template validation failure before resource provisioning.

Key distinction:

```text
template validation failure
≠
resource provisioning failure
```

---

# Phase 5E — Cleanup / Documentation

Status: **completed**

The temporary Storage Account was removed after validation.

The retained VM baseline was checked again.

Verified final VM state:

```text
VM:                  vm-azsl-01
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:          none
```

The existing Lab 02 infrastructure was not modified by the ARM deployment exercises.

ARM deployment history was intentionally retained as useful lab evidence.

---

## Completed Phase 5 flow

```text
[✓] Phase 5A — ARM Template Fundamentals / Prepare
    [✓] ARM mental model
    [✓] Template structure
    [✓] Parameters
    [✓] Resource declarations
    [✓] Resource Provider namespace / resource type
    [✓] apiVersion
    [✓] Dependencies
    [✓] Deployment scope
    [✓] ARM expressions and functions
    [✓] First safe resource selected

[✓] Phase 5B — First Controlled ARM Deployment
    [✓] Template validation
    [✓] Storage Account deployment
    [✓] Deployment inspection
    [✓] Portal inspection
    [✓] Deployment object vs resource object
    [✓] Redeployment behavior
    [✓] Desired-state update

[✓] Phase 5C — Parameters & Repeatability
    [✓] Parameter file
    [✓] Parameterized TLS property
    [✓] defaultValue behavior

[✓] Phase 5D — Controlled Failure / Troubleshooting
    [✓] Invalid parameter introduced
    [✓] InvalidTemplate diagnosed
    [✓] allowedValues constraint understood
    [✓] Error corrected
    [✓] Validation recovery verified

[✓] Phase 5E — Cleanup / Documentation
    [✓] Temporary Storage Account removed
    [✓] VM baseline preserved
    [✓] Findings documented
```

---

## Key learning outcomes

- Azure Portal, CLI, PowerShell, and ARM templates operate through the Azure control plane.
- ARM templates describe desired state declaratively.
- Resource Provider namespaces and resource types define what Azure resource is managed.
- `apiVersion` selects the Resource Provider API version.
- Parameters make templates reusable.
- `defaultValue` supplies a value when a parameter is omitted.
- `allowedValues` constrains acceptable parameter values.
- ARM expressions can call functions such as `parameters()` and `resourceGroup()`.
- Deployment scope does not require a template to contain every resource already present in that scope.
- A deployment object is separate from the resource that it creates or updates.
- Reapplying the same desired state does not create duplicate resources.
- Changing desired state can update an existing resource.
- Validation can catch template-level errors before resource provisioning.
- Deployment history provides useful operational and troubleshooting evidence.

---

## Final checkpoint

```text
Phase 5 — completed

VM:                  vm-azsl-01
VM size:             Standard_B2ats_v2
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:          none
Temporary ARM resource:
                      removed
```

Next:

```text
App Service fundamentals
```
