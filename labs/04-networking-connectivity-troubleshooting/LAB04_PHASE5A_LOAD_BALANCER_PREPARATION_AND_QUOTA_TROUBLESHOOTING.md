# Lab 04 — Phase 5A: Load Balancer Preparation & Quota Troubleshooting

## Status

**Completed**

This block covers the infrastructure preparation required before the Load Balancer itself was built: backend topology selection, regional and family vCPU quota troubleshooting, VM SKU selection, image-generation compatibility, cleanup of the failed design, and creation of two private-only backend VMs.

The next block is:

[`LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md`](LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md)

---

## Goal

Prepare two temporary backend VMs for the Load Balancer without changing the retained `vm-azsl-01` baseline, while diagnosing real Azure deployment constraints instead of working around them blindly.

## Selected Topology

We decided to keep the existing retained VM out of the Load Balancer backend pool and build an isolated temporary backend pair.

Planned topology:

```text
Internet
   |
   v
Standard Public IP
   |
   v
Standard Public Load Balancer
   |
   v
Backend Pool
   ├── vm-azsl-lb-01
   └── vm-azsl-lb-02

Both backend VMs:
- private IP only
- no Public IP
- same VNet
- same subnet
- no NIC-level NSG initially
```

Retained resources remain outside the temporary backend topology.

---

---

## Existing Azure Baseline

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VM size:        Standard_B2ats_v2
NIC:            vm-azsl-01284
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
Subnet CIDR:    <PRIVATE-SUBNET>/24
NSG:            nsg-azsl-01
Public IP:      vm-azsl-01-ip
```

Networking baseline:

```text
NSG attached to NIC: yes
Subnet-level NSG:    none
Subnet route table:  none
Active UDRs:         none
VNet peerings:       none
SSH rule:            allow-ssh-myip
SSH source:          current administrator public IPv4 /32
SSH connectivity:    working
```

---

---

## Initial Backend VM Design

The first plan was to create two identical temporary backend VMs:

```text
vm-azsl-lb-01 → Standard_B2ats_v2
vm-azsl-lb-02 → Standard_B2ats_v2
```

Both were intended to use:

```text
Region:          Austria East
Zone:            1
Image:           Ubuntu Server 24.04 LTS
Authentication:  SSH public key
Username:        azureuser
Public IP:       None
NIC NSG:         None
Public inbound:  None
VNet:            vnet-azsl-01
Subnet:          subnet-azsl-01
OS disk:         30 GiB Standard SSD
Delete OS disk:  Yes
Delete NIC:      Yes
Load balancing:  None
```

---

---

## First Temporary VM Creation

`vm-azsl-lb-01` was successfully created using `Standard_B2ats_v2`.

Observed properties:

```text
Name:                vm-azsl-lb-01
Region:              austriaeast
Size:                Standard_B2ats_v2
Provisioning state:  Succeeded
OS:                  Ubuntu 24.04 LTS
OS disk:             30 GiB StandardSSD_LRS
OS disk deleteOption: Delete
Data disks:          none
Authentication:      SSH key only
Trusted Launch:      enabled
Availability Zone:   1
NIC deleteOption:    Delete
```

Its NIC was inspected and confirmed to match the intended private-only backend design:

```text
NSG:                  null
Private IP:           dynamic
Public IP:            null
Subnet:               subnet-azsl-01
VNet:                 vnet-azsl-01
```

---

---

## Problem Encountered

Creation of `vm-azsl-lb-02` failed because Azure would not allow another `Standard_B2ats_v2` VM.

At first this looked like a possible SKU or Availability Zone issue.

The troubleshooting sequence was:

```text
Symptom
↓
Second VM size unavailable
↓
Check SKU availability by region and zone
↓
Standard_B2ats_v2 exists in Austria East
↓
Portal reports insufficient regional quota
↓
Inspect Azure VM usage/quota
↓
Root cause confirmed
```

---

---

## Quota Root Cause

Azure CLI showed:

```text
Standard Basv2 Family vCPUs   4 / 4
Total Regional vCPUs          4 / 4
```

The current VM allocation was effectively:

```text
vm-azsl-01       → 2 vCPU
vm-azsl-lb-01    → 2 vCPU
-------------------------
Total            → 4 vCPU
Regional limit   → 4 vCPU
```

The second VM therefore could not be deployed.

This was not a Load Balancer issue and not primarily a subnet or zone issue.

---

---

## Quota Increase Attempt

The Azure Portal showed:

```text
Ineligible for quota adjustment.
Azure subscription 1 is not eligible for quota adjustment.
Consider upgrading your subscription.
```

Decision:

**Do not upgrade the subscription only for this lab.**

The lab design should adapt to the current subscription limits instead.

---

---

## Investigation of 1-vCPU VM Sizes

Several 1-vCPU sizes were checked.

Unavailable for the subscription in all of Austria East:

```text
Standard_B1s
Standard_B1ms
Standard_B1ls
Standard_A1_v2
Standard_F1
Standard_F1s
```

These returned:

```text
reasonCode: NotAvailableForSubscription
restriction type: Location
location: AustriaEast
```

Two usable 1-vCPU candidates were found:

```text
Standard_D1_v2
Standard_DS1_v2
```

For these sizes, the only restriction was Zone 3.

Therefore they are usable in Zone 1 or Zone 2.

---

---

## New VM Size Decision

The final decision was to use:

```text
vm-azsl-lb-01 → Standard_D1_v2 → 1 vCPU
vm-azsl-lb-02 → Standard_D1_v2 → 1 vCPU
```

Both should use Availability Zone 1 if the Portal allows it.

This keeps the isolated two-backend design while staying within the subscription's regional vCPU quota.

---

---

## Cleanup Performed

The original temporary `vm-azsl-lb-01` using `Standard_B2ats_v2` was deleted.

Its dependent temporary resources were also removed:

```text
vm-azsl-lb-01
vm-azsl-lb-01900
vm-azsl-lb-01_OsDisk_1_...
vm-azsl-lb-01-key
```

The retained Azure baseline was verified to remain intact.

Remaining retained resources:

```text
nsg-azsl-01
vm-azsl-01
vm-azsl-01-ip
vm-azsl-01-key
vm-azsl-01284
vm-azsl-01_OsDisk_1_...
vnet-azsl-01
```

---

---

## Quota After Cleanup

After deleting the temporary 2-vCPU backend VM, quota was verified again:

```text
Name                       Current    Limit
-------------------------  ---------  -----
Total Regional vCPUs       2          4
Standard Dv2 Family vCPUs  0          4
```

This confirms that there are now exactly two free regional vCPUs available.

That is enough for two `Standard_D1_v2` backend VMs.

---

---

## Final Backend VM Design

The selected backend design was implemented as follows:

```text
vm-azsl-lb-01
  Size: Standard_D1_v2
  vCPU: 1
  Zone: 1

vm-azsl-lb-02
  Size: Standard_D1_v2
  vCPU: 1
  Zone: 1
```

Both VMs use:

```text
Ubuntu Server 24.04 LTS
Image SKU: server-gen1
Private IP only
No Public IP
No NIC NSG initially
vnet-azsl-01
subnet-azsl-01
Standard SSD OS disk
Delete OS disk with VM: Yes
Delete NIC with VM: Yes
Load balancing option during VM creation: None
```

The explicit Gen1 image reference used for deployment was:

```text
Canonical:ubuntu-24_04-lts:server-gen1:latest
```

---

---

## Additional Troubleshooting Finding — VM Generation Compatibility

The first attempt to recreate `vm-azsl-lb-01` with `Standard_D1_v2` failed even though quota and regional SKU availability were no longer blocking deployment.

Azure returned:

```text
The selected VM size 'Standard_D1_v2' cannot boot Hypervisor Generation '2'.
```

The attempted combination was effectively:

```text
VM size: Standard_D1_v2
Image:   Ubuntu2404
```

The image selected through the generic Ubuntu 24.04 alias required Hyper-V Generation 2, while the selected VM size required a compatible Generation 1 image.

The deployment was retried with:

```text
Canonical:ubuntu-24_04-lts:server-gen1:latest
```

No networking or quota settings were changed. The VM then deployed successfully.

Troubleshooting sequence:

```text
DeploymentFailed
↓
Inspect nested ARM deployment error
↓
BadRequest
↓
VM size cannot boot Hypervisor Generation 2
↓
Keep Standard_D1_v2
↓
Change only the Ubuntu image generation
↓
Use server-gen1 image
↓
Deployment succeeds
```

Key lesson:

**VM deployment can fail even when quota, region, and zone are valid if the selected image generation is incompatible with the VM size. Check the nested ARM error before changing unrelated networking or quota settings.**

The first failed attempt also generated the local SSH key files:

```text
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

This SSH key generation was not the cause of the deployment failure.

---

---

## Backend VM Baseline Checkpoint

Both temporary Load Balancer backend VMs are now created and running.

### `vm-azsl-lb-01`

Observed VM state:

```text
Name:              vm-azsl-lb-01
Location:          austriaeast
Size:              Standard_D1_v2
Power state:       VM running
Availability Zone: 1
Private IP:        assigned
Public IP:         none
```

NIC inspection confirmed:

```text
NIC:                   vm-azsl-lb-01VMNic
Provisioning state:    Succeeded
Private IP:            assigned dynamically
Private IP allocation: Dynamic
Subnet:                vnet-azsl-01/subnet-azsl-01
Public IP:             null
NIC-level NSG:         null
```

### `vm-azsl-lb-02`

Observed VM state:

```text
Name:              vm-azsl-lb-02
Location:          austriaeast
Size:              Standard_D1_v2
Power state:       VM running
Availability Zone: 1
Private IP:        assigned
Public IP:         none
```

NIC inspection confirmed:

```text
NIC:                   vm-azsl-lb-02VMNic
Provisioning state:    Succeeded
Private IP:            assigned dynamically
Private IP allocation: Dynamic
Subnet:                vnet-azsl-01/subnet-azsl-01
Public IP:             null
NIC-level NSG:         null
```

Current temporary backend topology:

```text
vnet-azsl-01
└── subnet-azsl-01
    ├── vm-azsl-lb-01VMNic
    │   ├── private IP only
    │   ├── no Public IP
    │   └── no NIC-level NSG
    │
    └── vm-azsl-lb-02VMNic
        ├── private IP only
        ├── no Public IP
        └── no NIC-level NSG
```

---

## Completion Checkpoint

```text
vm-azsl-lb-01 → Standard_D1_v2 → Zone 1 → private IP only → ready
vm-azsl-lb-02 → Standard_D1_v2 → Zone 1 → private IP only → ready
Public IP on backends: none
NIC-level NSG:         none initially
Subnet:                subnet-azsl-01
VNet:                  vnet-azsl-01
Regional vCPU usage:   4 / 4 after both backends are running
```

Key troubleshooting outcomes:

```text
Regional quota exhaustion diagnosed
Quota increase unavailable for subscription
1-vCPU compatible SKU selected
Gen2 image incompatibility diagnosed
Gen1 Ubuntu image selected
Two backend VMs successfully deployed
```
