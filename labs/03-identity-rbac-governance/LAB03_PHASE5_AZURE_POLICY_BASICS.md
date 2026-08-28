# Lab 03 — Phase 5: Azure Policy Basics

## Purpose

Understand how Azure Policy differs from Azure RBAC and practice basic governance controls using a safe Resource Group scoped exercise.

## Learning model

```text
Azure RBAC
→ who can perform an action

Azure Policy
→ what resource configurations are allowed, denied, required, or audited
```

The practical workflow followed the project method:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

---

## Baseline

Existing environment reused:

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VM size:        Standard_B2ats_v2
OS disk:        30 GiB StandardSSD_LRS
Data disks:     none
VM state:       Stopped (deallocated)
```

No temporary Lab 03 Policy assignment existed at Resource Group scope before the exercise.

A separate subscription-level assignment was observed in the Azure Portal:

```text
ASC Default
└── Microsoft cloud security benchmark
```

This assignment was inherited by `rg-azsl-01` and was intentionally left unchanged.

---

## Concepts practiced

### Policy definition

A Policy definition contains reusable governance logic.

The built-in definition used in this exercise was:

```text
Allowed locations
Policy type: BuiltIn
Mode: Indexed
```

The core rule structure was inspected directly:

```json
{
  "if": {
    "allOf": [
      {
        "field": "location",
        "notIn": "[parameters('listOfAllowedLocations')]"
      },
      {
        "field": "location",
        "notEquals": "global"
      },
      {
        "field": "type",
        "notEquals": "Microsoft.AzureActiveDirectory/b2cDirectories"
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

This was interpreted as:

```text
IF
resource location is not in the allowed list
AND location is not global
AND the resource type is not the excluded B2C directory type

THEN
apply the configured effect
```

---

## Definition parameters

The built-in definition exposed two important parameters:

```text
listOfAllowedLocations
→ Array

effect
→ Audit
→ Deny
→ Disabled
```

The default effect was `Deny`, so the first assignment explicitly used `Audit` to avoid accidental blocking.

---

## Policy assignment

A Resource Group scoped assignment was created:

```text
Name:          azsl-audit-allowed-locations
Display name:  AZSL Audit Allowed Locations
Scope:         rg-azsl-01
Allowed:       austriaeast
Effect:        Audit
```

The assignment was confirmed with Azure CLI and the Azure Portal.

The assignment showed:

```text
EnforcementMode: Default
Effect:          Audit
```

This demonstrated that `enforcementMode` and Policy `effect` are separate concepts.

---

## Compliance evaluation

A manual Policy scan was triggered for `rg-azsl-01`.

The Azure Portal reported the existing applicable resources as compliant with the `Allowed locations` rule.

Observed result:

```text
Overall resource compliance: 100%
7 out of 7 applicable resources compliant
0 non-compliant
Effect: Audit
```

The definition used `Mode = Indexed`, so not every Resource Group object was necessarily evaluated by this Policy.

---

## Inheritance and initiatives

The Azure Portal also showed a subscription-level assignment:

```text
ASC Default
└── Microsoft cloud security benchmark
```

This provided a practical example of Policy inheritance:

```text
Subscription assignment
        ↓
Resource Group
        ↓
Resources
```

It also introduced the difference between a single Policy definition and an initiative:

```text
Policy definition
→ one governance rule

Policy initiative
→ collection of Policy definitions
```

The inherited subscription-level assignment was observed only and not modified.

---

## Controlled Audit violation

A temporary User Assigned Managed Identity was created outside the allowed region:

```text
Name:     id-azsl-policy-test
Location: northeurope
```

Because the Policy effect was `Audit`, the resource creation was allowed.

After compliance evaluation, the resource appeared as:

```text
Compliance: NonCompliant
Location:   northeurope
```

This confirmed:

```text
Audit
→ does not block the request
→ records the configuration as non-compliant
```

---

## Controlled Policy failure

The same assignment was updated from:

```text
Effect: Audit
```

to:

```text
Effect: Deny
```

A second User Assigned Managed Identity creation was attempted:

```text
Name:     id-azsl-policy-deny-test
Location: northeurope
```

The request failed with:

```text
RequestDisallowedByPolicy
```

The error identified both:

```text
Policy assignment:
AZSL Audit Allowed Locations

Policy definition:
Allowed locations
```

The denied resource was not created.

This demonstrated the governance sequence:

```text
RBAC permission valid
        +
resource request valid at authorization layer
        +
Policy configuration violation
        ↓
RequestDisallowedByPolicy
```

---

## Troubleshooting distinctions

Three different failure classes were observed during Lab 03:

```text
AuthorizationFailed
→ Azure RBAC / authorization problem

RequestDisallowedByPolicy
→ Azure Policy governance problem

RequestDisallowedByAzure + locationineligible
→ Azure platform / regional eligibility restriction
```

A separate attempt to create a Public IP in `westeurope` failed because the selected region was not accepting new customers for the subscription.

This was correctly diagnosed as a platform restriction rather than a Policy failure.

---

## Fix and verification

The Policy assignment was changed back from `Deny` to `Audit`.

A verification identity was created successfully in `northeurope`:

```text
id-azsl-policy-verify
```

This confirmed:

```text
Deny
→ request blocked

Audit
→ request allowed
```

---

## Cleanup

Temporary resources were deleted:

```text
id-azsl-policy-test
id-azsl-policy-verify
azsl-audit-allowed-locations
```

The denied identity was never created:

```text
id-azsl-policy-deny-test
→ not created
```

Final checks confirmed:

```text
Temporary Resource Group scoped Policy assignment: none
Temporary managed identities: none
vm-azsl-01: VM deallocated
```

The inherited subscription-level security benchmark assignment remained unchanged.

---

## Key takeaways

- Azure RBAC answers **who can perform an action**.
- Azure Policy answers **what configurations are allowed, denied, audited, or required**.
- A Policy definition contains reusable governance logic.
- A Policy assignment applies that logic at a specific scope.
- Policy assignments can be inherited from higher scopes.
- Initiatives group multiple Policy definitions.
- `Audit` allows the request but records non-compliance.
- `Deny` blocks a violating request.
- Compliance state is always relative to a particular Policy or initiative.
- `RequestDisallowedByPolicy` is distinct from RBAC authorization failures.
- Platform restrictions can also deny requests and must be distinguished from Policy failures.

---

## Phase result

**Phase 5 — Azure Policy Basics: completed**

Practical coverage completed:

```text
Policy definitions
Policy assignments
Resource Group scope
Inheritance
Initiatives
Policy parameters
Indexed mode
Compliance evaluation
Audit effect
Deny effect
RequestDisallowedByPolicy troubleshooting
RBAC versus Policy
Platform restriction versus Policy restriction
Cleanup and baseline verification
```
