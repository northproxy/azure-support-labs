# Lab 05 — Azure Storage & Data Access

## Status

**In progress**

## Purpose

Understand Azure storage architecture, data-access paths, security controls, and common storage access failures through practical hands-on exercises.

## Learning Method

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

## Reused Azure Baseline

```text
Resource Group: rg-azsl-01
VM:             vm-azsl-01
VNet:           vnet-azsl-01
Subnet:         subnet-azsl-01
NSG:            nsg-azsl-01
```

The retained VM and networking baseline should remain unchanged unless a phase explicitly requires temporary integration with Storage.

## Planned Phases

### Phase 1 — Storage Account Baseline & Architecture

Goals:

- create a low-cost Storage Account;
- inspect account properties and service endpoints;
- understand performance tier and redundancy;
- compare Portal and Azure CLI views;
- establish a clean Storage baseline before creating data objects.

### Phase 2 — Blob Storage & Data Access

Goals:

- create a Blob Container;
- upload and inspect test blobs;
- understand blob URLs and object hierarchy;
- verify data access through Azure Portal and Azure CLI;
- introduce basic access methods such as Microsoft Entra authorization, account keys, and SAS where appropriate.

### Phase 3 — Storage Authorization Troubleshooting

Goals:

- create a controlled authorization failure;
- distinguish authentication from authorization;
- inspect Azure RBAC scope and data-plane roles;
- diagnose the failure before changing access;
- apply the minimum required fix and verify recovery.

### Phase 4 — Storage Networking Troubleshooting

Goals:

- inspect public network access settings;
- understand Storage Account firewall and selected network behavior;
- create a controlled network-access failure;
- distinguish network denial from authorization failure;
- restore access and verify the data path.

### Phase 5 — Azure Files

Goals:

- create an Azure File Share;
- understand SMB-based access;
- compare Azure Files with Blob Storage;
- optionally test access from the retained VM if useful and cost-effective.

### Phase 6 — Cleanup & Documentation

Goals:

- delete temporary data and Storage resources;
- verify that the retained Azure baseline is unchanged;
- document troubleshooting findings;
- update project-level `README.md`, `ROADMAP.md`, and `AZURE_MAP.md`.

## Core Topics

```text
Storage Account
├── Performance tier
├── Redundancy
├── Service endpoints
├── Blob service
│   ├── Containers
│   └── Blobs
├── File service
│   └── File shares
├── Authentication
├── Authorization
├── Azure RBAC
├── SAS
├── Account keys
├── Public network access
└── Firewall / network restrictions
```

## Expected Troubleshooting Questions

During this lab we should be able to answer:

- Is the Storage Account itself provisioned correctly?
- Is the requested service endpoint correct?
- Does the caller have valid authentication?
- Does the caller have the required data-plane permissions?
- Is the Storage Account network path allowing the request?
- Is the object or container present?
- Is the failure caused by identity, authorization, networking, or data state?

## Cost and Lifecycle

Use low-cost Standard storage and minimal test data.

Temporary Storage resources should be deleted after the lab unless they are intentionally retained for Lab 06 monitoring exercises.

## Completion Criteria

Lab 05 is complete when:

- Storage Account architecture has been inspected;
- Blob Storage has been used for real data operations;
- at least one controlled authorization failure has been diagnosed and fixed;
- at least one controlled storage networking failure has been diagnosed and fixed;
- Azure Files has been reviewed or practiced as planned;
- temporary resources have been deleted;
- the retained Azure baseline has been verified;
- project documentation has been updated.
