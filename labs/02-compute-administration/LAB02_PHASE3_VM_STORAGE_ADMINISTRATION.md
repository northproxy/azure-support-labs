# Lab 02 — Phase 3: VM Storage Administration

Status: **completed**

## Purpose

Inspect and understand the storage configuration of `vm-azsl-01` before making any storage changes.

This phase focuses on the relationship between the virtual machine and its managed OS disk, the disk's current properties and lifecycle, and the baseline state before adding a separate data disk.

---

## Starting baseline

```text
VM name:             vm-azsl-01
VM size:             Standard_B2ats_v2
OS type:             Linux
Provisioning state:  Succeeded
Power state:         VM deallocated
```

No storage configuration changes had been made at the start of this phase.

---

# Phase 3A — Storage Baseline / Inspection

Status: **completed**

## 1. Inspect the OS disk reference from the VM

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "storageProfile.osDisk" `
  --output json
```

Observed properties:

```text
Caching:        ReadWrite
Create option:  FromImage
Delete option:  Delete
OS type:        Linux
```

Managed OS disk:

```text
vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
```

The VM configuration contains a reference to a separate Azure Managed Disk resource.

Conceptual relationship:

```text
vm-azsl-01
└── storageProfile.osDisk.managedDisk.id
    └── Microsoft.Compute/disks/
        └── vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
```

### Key observations

- `ReadWrite` caching is enabled for the OS disk.
- `FromImage` confirms that the OS disk was created from the VM image.
- `Delete` means the OS disk is currently configured to be deleted with the VM if the VM itself is deleted.
- The OS disk is a separate Azure resource, not embedded inside the VM resource.

---

## 2. Inspect the Managed Disk directly

Command:

```powershell
az disk show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870 `
  --query "{name:name,diskSizeGB:diskSizeGB,sku:sku.name,provisioningState:provisioningState,diskState:diskState,osType:osType}" `
  --output json
```

Observed baseline:

```text
Disk size:             30 GiB
SKU:                   StandardSSD_LRS
OS type:               Linux
Provisioning state:    Succeeded
Disk state:            Reserved
```

### Key observations

`diskSizeGB` identifies the configured managed disk size.

`StandardSSD_LRS` identifies the disk SKU:

```text
Standard SSD
+
Locally-redundant storage (LRS)
```

`provisioningState: Succeeded` confirms that Azure successfully provisioned the disk resource.

`diskState: Reserved` shows that the disk remains reserved for a VM rather than existing as an unattached disk.

---

## 3. Verify the Managed Disk → VM relationship

Command:

```powershell
az disk show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870 `
  --query "{managedBy:managedBy,diskState:diskState}" `
  --output json
```

Observed result:

```text
Disk state:  Reserved
Managed by:  vm-azsl-01
```

The `managedBy` property points back to the Resource ID of:

```text
Microsoft.Compute/virtualMachines/vm-azsl-01
```

This verifies the relationship in both directions:

```text
Virtual Machine
    │
    │ storageProfile.osDisk.managedDisk.id
    ▼
Managed Disk
    │
    │ managedBy
    ▼
Virtual Machine
```

---

## 4. Compare compute lifecycle and storage lifecycle

At inspection time:

```text
VM power state:  VM deallocated
Disk state:      Reserved
```

This demonstrates an important lifecycle distinction:

```text
VM deallocated
    ↓
Compute allocation released

Managed OS disk
    ↓
Resource still exists
    ↓
Data persists
    ↓
Disk remains associated with the VM
```

Deallocating a VM does not delete its managed OS disk.

The VM compute lifecycle and persistent storage lifecycle are therefore related but separate.

---

## 5. Inspect the full VM storage profile

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "storageProfile" `
  --output json
```

Observed storage profile:

```text
Disk controller type:  SCSI
OS disk:               present
Data disks:            none
Image publisher:       canonical
Image offer:           ubuntu-24_04-lts
Image SKU:             server
Image version:         latest
```

The important baseline property is:

```json
"dataDisks": []
```

No additional managed data disks are currently attached to the VM.

---

## Storage baseline summary

```text
vm-azsl-01
├── OS disk
│   ├── Name: vm-azsl-01_OsDisk_1_d56bee3eda6c44939e50a78cff1f3870
│   ├── Size: 30 GiB
│   ├── SKU: StandardSSD_LRS
│   ├── OS: Linux
│   ├── Caching: ReadWrite
│   ├── Create option: FromImage
│   ├── Delete option: Delete
│   ├── Provisioning state: Succeeded
│   ├── Disk state: Reserved
│   └── managedBy → vm-azsl-01
│
├── Disk controller
│   └── SCSI
│
└── Data disks
    └── none
```

---

## Completed checks

```text
[✓] Managed OS disk identified
[✓] OS disk reference inspected from the VM
[✓] Managed Disk inspected directly
[✓] Disk size verified
[✓] Disk SKU verified
[✓] Disk provisioning state verified
[✓] Disk state verified
[✓] VM → Managed Disk relationship verified
[✓] Managed Disk → VM relationship verified
[✓] Compute lifecycle vs persistent storage lifecycle understood
[✓] Full VM storageProfile inspected
[✓] Disk controller type identified
[✓] Data disk baseline confirmed: none
[✓] No storage configuration changes made during inspection
```

---

# Phase 3B — Managed Data Disk Administration

Status: **completed**

A temporary managed data disk was created, inspected, attached to `vm-azsl-01`, initialized inside Linux, used for a basic read/write verification, detached, deleted, and the original VM baseline was restored.

## 1. Verify VM placement

Command:

```powershell
az vm show `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01 `
  --query "{location:location,zones:zones}" `
  --output json
```

Observed result:

```text
Location:  austriaeast
Zones:     null
```

The VM was not pinned to a specific Availability Zone, so no zone-specific disk placement parameter was required for this exercise.

---

## 2. Create a temporary managed data disk

Disk configuration:

```text
Name:  vm-azsl-01-data-01
Size:  4 GiB
SKU:   StandardSSD_LRS
```

Command:

```powershell
az disk create `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01-data-01 `
  --location austriaeast `
  --size-gb 4 `
  --sku StandardSSD_LRS `
  --output json
```

The disk was created as a separate Azure Managed Disk resource before being attached to the VM.

---

## 3. Inspect the unattached disk

Observed result:

```text
Disk size:             4 GiB
SKU:                   StandardSSD_LRS
Provisioning state:    Succeeded
Disk state:            Unattached
Managed by:            null
Location:              austriaeast
Zones:                 null
```

This demonstrated that a Managed Disk can exist independently of a VM.

---

## 4. Attach the disk to the VM

Command:

```powershell
az vm disk attach `
  --resource-group rg-azsl-01 `
  --vm-name vm-azsl-01 `
  --name vm-azsl-01-data-01
```

The VM storage profile showed:

```text
Name:           vm-azsl-01-data-01
Create option:  Attach
LUN:            0
Caching:        None
Delete option:  Detach
toBeDetached:   false
```

`managedDisk.id` pointed to the temporary Managed Disk resource.

---

## 5. Verify the reverse Managed Disk → VM relationship

Observed result:

```text
Disk state:  Reserved
Managed by:  vm-azsl-01
```

This verified the relationship in both directions:

```text
Virtual Machine
    │
    │ storageProfile.dataDisks[].managedDisk.id
    ▼
Managed Data Disk
    │
    │ managedBy
    ▼
Virtual Machine
```

---

## 6. Start the VM and inspect runtime state

Observed Azure-side state:

```text
Power state:        VM running
Provisioning state: Succeeded
```

Azure Portal briefly reported that the VM agent status was not ready. The VM itself was running and SSH connectivity worked, so the storage exercise continued while keeping the agent issue separate from the disk lifecycle.

---

## 7. Inspect the attached disk from Linux

Inside Ubuntu:

```bash
lsblk
lsblk -f
```

Observed:

```text
sda       30G  disk
├─sda1    29G  part  /
├─sda14    4M  part
├─sda15  106M  part  /boot/efi
└─sda16  913M  part  /boot

sdb        4G  disk
```

The Azure data disk appeared in Linux as `/dev/sdb` with no partition or filesystem.

This confirmed that Azure attachment exposes a block device to the guest OS but does not automatically partition, format, or mount it.

---

## 8. Partition the disk

Commands:

```bash
sudo parted /dev/sdb --script mklabel gpt
sudo parted /dev/sdb --script mkpart primary ext4 0% 100%
```

Verification:

```text
sdb       4G  disk
└─sdb1    4G  part
```

---

## 9. Create an ext4 filesystem

Command:

```bash
sudo mkfs.ext4 /dev/sdb1
```

Observed filesystem:

```text
/dev/sdb1
FSTYPE: ext4
FSVER:  1.0
UUID:   f7a590ca-2351-4160-8388-fbe384038cca
```

---

## 10. Mount the filesystem

Commands:

```bash
sudo mkdir -p /mnt/data
sudo mount /dev/sdb1 /mnt/data
```

Verification:

```text
Filesystem:  /dev/sdb1
Size:        3.9G
Available:   approximately 3.7G
Mount point: /mnt/data
```

The mount was intentionally temporary. `/etc/fstab` was not modified.

---

## 11. Verify basic read/write access

A small test file was written and read back successfully:

```text
/mnt/data/test.txt
```

Content:

```text
Azure Support Labs - Phase 3B
```

---

## 12. Unmount before detach

Command:

```bash
sudo umount /mnt/data
```

Verification confirmed that `/dev/sdb1` had no mount point.

---

## 13. Detach the disk

Command:

```powershell
az vm disk detach `
  --resource-group rg-azsl-01 `
  --vm-name vm-azsl-01 `
  --name vm-azsl-01-data-01
```

VM-side verification:

```json
[]
```

Managed Disk-side verification:

```text
Disk state:  Unattached
Managed by:  null
```

Detaching removed the VM association without deleting the Managed Disk resource.

---

## 14. Delete the temporary Managed Disk

Command:

```powershell
az disk delete `
  --resource-group rg-azsl-01 `
  --name vm-azsl-01-data-01 `
  --yes
```

The temporary Managed Disk was successfully deleted.

---

## 15. Restore the cost-safe VM baseline

The VM was deallocated after the storage exercise.

Final state:

```text
VM name:             vm-azsl-01
VM size:             Standard_B2ats_v2
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:          none
```

---

## Phase 3B lifecycle summary

```text
Create Managed Disk
    ↓
Unattached
    ↓
Attach to vm-azsl-01
    ↓
Reserved / managedBy → VM
    ↓
Linux detects /dev/sdb
    ↓
Create GPT partition
    ↓
/dev/sdb1
    ↓
Create ext4 filesystem
    ↓
Mount at /mnt/data
    ↓
Verify read/write
    ↓
Unmount
    ↓
Detach
    ↓
Unattached / managedBy: null
    ↓
Delete Managed Disk
    ↓
Restore VM deallocated baseline
```

---

## Completed checks

```text
[✓] VM placement inspected
[✓] Temporary 4 GiB StandardSSD_LRS Managed Disk created
[✓] Unattached state verified
[✓] managedBy: null verified before attach
[✓] Managed Disk attached to vm-azsl-01
[✓] LUN 0 verified
[✓] createOption: Attach verified
[✓] caching: None verified
[✓] deleteOption: Detach verified
[✓] VM → Managed Disk relationship verified
[✓] Managed Disk → VM relationship verified
[✓] Disk state transition Unattached → Reserved observed
[✓] VM started and runtime state verified
[✓] SSH connectivity verified
[✓] New disk detected in Linux as /dev/sdb
[✓] GPT partition table created
[✓] /dev/sdb1 created
[✓] ext4 filesystem created
[✓] Filesystem mounted at /mnt/data
[✓] Basic read/write test completed
[✓] Filesystem unmounted before detach
[✓] Data disk detached
[✓] VM dataDisks returned to []
[✓] Disk state returned to Unattached
[✓] managedBy returned to null
[✓] Temporary Managed Disk deleted
[✓] VM deallocated after the exercise
[✓] Final baseline restored
```

---

# Phase 3 completion summary

Status: **completed**

Phase 3 demonstrated both sides of VM storage administration:

```text
Phase 3A
    ↓
Inspect existing OS disk and lifecycle relationships

Phase 3B
    ↓
Create and administer a temporary data disk through its full lifecycle
```

Key concepts confirmed:

- Azure Managed Disks are separate Azure resources.
- A disk can exist without being attached to a VM.
- VM disk references and the disk's `managedBy` property expose the relationship in opposite directions.
- `diskState` changes as disk attachment state changes.
- Azure attachment exposes a block device to Linux but does not create a partition, filesystem, or mount point.
- Linux guest storage administration is separate from Azure control-plane disk administration.
- Detaching a disk does not delete it.
- Temporary resources should be explicitly deleted after validation.
- Deallocating the VM releases compute allocation while persistent OS storage remains.

---

## Final checkpoint

```text
Phase 3A — Storage Baseline / Inspection: completed
Phase 3B — Managed Data Disk Administration: completed
Phase 3 — VM Storage Administration: completed

VM:          vm-azsl-01
VM size:     Standard_B2ats_v2
VM state:    deallocated
OS disk:     30 GiB StandardSSD_LRS
Disk state:  Reserved
Data disks:  none
```
