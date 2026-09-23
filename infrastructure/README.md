# Reproducible Azure Lab Infrastructure

## Purpose

This directory contains Infrastructure as Code for recreating the core Azure Support Labs environment when real Azure resources are required.

The project is moving away from a permanently retained Azure baseline toward an ephemeral lab model:

**Deploy → Lab → Observe → Troubleshoot → Verify → Document → Delete**

This reduces ongoing Azure cost while keeping the environment reproducible.

## Current State

The previous persistent Azure lab environment was captured before cleanup.

The captured environment included:

- Resource Group: `rg-azsl-01`
- Virtual Machine: `vm-azsl-01`
- VM size: `Standard_B2ats_v2`
- Linux administrator: `azureuser`
- Ubuntu 24.04 LTS Marketplace image
- Standard SSD OS disk
- Virtual Network: `vnet-azsl-01`
- Subnet: `subnet-azsl-01`
- Network Security Group: `nsg-azsl-01`
- SSH rule: `allow-ssh-myip`
- Network Interface: `vm-azsl-01284`
- Standard Static Public IPv4 address
- Azure SSH public-key resource
- Storage Account: `stazsl05npx01`
- StorageV2 / Standard_LRS / Hot
- Blob container: `azsl05-data`

During baseline capture, a stale disconnected VNet peering resource from an earlier networking lab was discovered and removed before the clean baseline was exported.

## Cost Cleanup

The persistent lab environment was deleted after the baseline was captured.

The subscription currently retains only the Azure-created Network Watcher environment:

```text
NetworkWatcherRG
└── NetworkWatcher_austriaeast
```

The previous persistent VM, managed disk, Public IP, NIC, NSG, VNet, Storage Account, and Blob data have been deleted.

No Pay-As-You-Go upgrade was performed as part of this cleanup.

## IaC Files

### `main.bicep`

Clean, manually reconstructed Bicep definition for the reusable lab baseline.

It intentionally does not reproduce runtime-generated Azure properties or the old generated OS disk name.

Important deployment values are parameterized, including:

- VNet address prefix
- subnet address prefix
- SSH source CIDR
- SSH public key
- administrator username
- Ubuntu image version
- Storage Account name

The SSH private key is never stored in Bicep or committed to the repository.

### `what-if.ps1`

Prepares deployment parameters from a captured local baseline and runs an Azure Resource Manager `what-if` comparison.

The script does not deploy resources.

The first `what-if` attempt could not complete because the Azure subscription had entered the `Warned` / read-only state after expiration of the free usage period.

## Local-Only Baseline

The following directory is intentionally excluded from Git:

```text
infrastructure/baseline/
```

It contains raw Azure exports and resource snapshots used to reconstruct and verify the Bicep definition.

Examples include:

```text
azure-export-before-cleanup.json
azure-export.json
azure-export.generated.bicep
resource-inventory.json
vm-azsl-01.json
vm-azsl-01-osdisk.json
vm-azsl-01284.json
vm-azsl-01-ip.json
vm-azsl-01-key.json
vnet-azsl-01.json
nsg-azsl-01.json
stazsl05npx01.json
stazsl05npx01-blob-service.json
stazsl05npx01-containers.json
stazsl05npx01-role-assignments.json
```

These files are reference evidence, not portable deployment templates.

They may contain Azure resource IDs, principal IDs, IP addresses, and other environment-specific metadata, so they should remain local unless explicitly sanitized.

## Validation Status

Completed:

```text
Baseline inventory captured
Raw Resource Group export captured
Stale disconnected VNet peering discovered
Stale peering removed
Clean Resource Group export captured
Compute configuration captured
Networking configuration captured
Storage configuration captured
RBAC configuration captured
Clean main.bicep created
Bicep compilation successful
Persistent lab resources deleted
Final subscription resource inventory verified
```

Pending:

```text
ARM what-if validation
Real deployment validation
Post-deployment verification
Automated deploy script
Automated cleanup script
```

These steps require a subscription that allows Azure Resource Manager write operations.

## Planned Workflow

When real Azure labs resume:

```text
1. Enable an Azure subscription suitable for the lab.
2. Review expected cost.
3. Run Bicep validation / what-if.
4. Deploy only the required environment.
5. Perform the lab.
6. Verify the learning objective and troubleshooting result.
7. Save sanitized evidence.
8. Delete billable resources.
9. Verify the subscription resource inventory.
```

This infrastructure is intended for learning and troubleshooting labs, not production deployment.
