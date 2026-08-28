# Roadmap

## Project Direction

Azure Support Labs is organized by **support domain**, not by Coursera course.

The Coursera **Microsoft Cloud Support Associate Professional Certificate** defines curriculum coverage, while the lab structure groups related Azure topics into a smaller set of reusable, support-oriented environments.

Core learning cycle:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

The project uses the minimum practical number of Azure resources, reuses infrastructure across related topics when useful, and avoids deploying expensive services only to satisfy syllabus coverage.

---

## Core Lab Sequence

```text
Lab 01 — Azure Foundation & Resource Lifecycle
    ↓
Lab 02 — Azure Compute & Administration
    ↓
Lab 03 — Identity, RBAC & Governance
    ↓
Lab 04 — Azure Networking & Connectivity Troubleshooting
    ↓
Lab 05 — Azure Storage & Data Access
    ↓
Lab 06 — Monitoring, Logs & Incident Diagnosis
    ↓
Lab 07 — Backup, Recovery, Updates & Compliance
```

Troubleshooting is a horizontal skill across all labs, not a separate final topic.

---

## Shared Resource Strategy

Base resources may be reused across multiple labs when their lifecycle allows it:

```text
Resource Group
├── Virtual Network
│   └── Subnet
├── Network Security Group
├── Virtual Machine
│   ├── Network Interface
│   └── Managed Disk
└── Optional Public IP
```

Additional resources are created only when required by a specific lab and deleted when no longer needed.

Typical temporary additions:

```text
Lab 02: App Service
Lab 03: Entra test objects, RBAC assignments, Policy assignments
Lab 04: second VM, second VNet, route table, Load Balancer
Lab 05: Storage Account, Blob Container, optional File Share
Lab 06: Log Analytics Workspace, alerts, Action Group, diagnostic settings
Lab 07: backup vault components, backup policy, recovery points, update configuration
```

---

# Lab 01 — Azure Foundation & Resource Lifecycle

Status: **completed**

## Purpose

Build a clear mental model of Azure resource hierarchy, resource dependencies, and the lifecycle of a small IaaS workload.

## Course coverage

- Course 7 — Cloud Computing Essentials with Azure Management
- Course 8 — Azure Cloud Services, introductory overlap

## Learning objectives

- Understand Subscription → Resource Group → Resource hierarchy.
- Identify the Azure resources created for a basic virtual machine workload.
- Understand dependencies between VM, NIC, IP configuration, NSG, VNet, subnet, and managed disk.
- Use Azure Portal and Azure CLI to inspect resources.
- Use Activity Log to observe control-plane operations.
- Understand resource creation and deletion lifecycle.

## Included topics

- Azure subscription
- Resource Groups
- Azure resources
- Azure Resource Manager concepts
- Virtual Machines
- Virtual Networks
- Subnets
- Network Security Groups
- Public IP
- Network Interfaces
- Managed Disks
- Azure Portal
- Azure CLI basics
- Activity Log
- Resource dependency inspection

## Resources reused

- Existing Azure subscription

## Resources created

- Resource Group
- Virtual Network
- Subnet
- Network Security Group
- Virtual Machine
- Network Interface
- Managed Disk
- Optional Public IP

## Resources deleted

- All temporary Lab 01 resources when the environment is no longer required for follow-on work

## Exclusions

- Advanced routing
- Load balancing
- Entra ID administration
- Advanced RBAC
- Log Analytics
- Backup
- Disaster recovery
- AKS

## Implementation

Files:

- `labs/01-foundation/README.md` — lab contract, scope, learning outcomes, checkpoints
- `labs/01-foundation/EXECUTION.md` — working execution guide

Current execution flow:

**Prepare → Build → Inspect → Map → Observe → Lifecycle → Cleanup**

Detailed controlled-failure troubleshooting scenarios are added only after the foundation execution flow is validated.

---

# Lab 02 — Azure Compute & Administration

Status: **completed**

## Purpose

Learn how Azure workloads are administered through the Portal, Azure CLI, Azure PowerShell, and ARM-based deployment methods.

## Course coverage

- Course 7 — Azure management concepts
- Course 8 — Azure compute services
- Course 9 — Azure CLI, PowerShell, and ARM

## Learning objectives

- Manage VM lifecycle and configuration.
- Inspect compute-related resource properties and dependencies.
- Compare Portal, CLI, PowerShell, and ARM as Azure administration interfaces.
- Perform repeatable resource queries and basic deployments.
- Understand ARM template structure, parameters, dependencies, and deployment results.
- Understand the role of App Service as a PaaS compute option.

## Included topics

- VM lifecycle
- VM sizing and configuration
- Managed disks
- Azure CLI
- Azure PowerShell
- Azure Resource Manager
- ARM templates
- Parameters and dependencies
- Resource deployment and inspection
- App Service fundamentals
- Basic deployment troubleshooting

## Resources reused

- Resource Group
- Existing VM
- Existing VNet, subnet, NSG, NIC, and disk

## Resources created

- Temporary App Service Plan
- Temporary App Service
- Temporary resources deployed through ARM when required

## Resources deleted

- App Service resources after validation
- Temporary deployment-test resources

## Completion summary

Completed practical coverage:

```text
VM lifecycle and configuration
Managed disk administration
Azure CLI administration
Azure PowerShell administration
ARM template deployment and troubleshooting
App Service Plan and Web App fundamentals
Python App Service deployment
Application settings and runtime configuration
Scaling fundamentals
Controlled App Service startup failure diagnosis
Final cleanup and baseline verification
```

Final retained baseline:

```text
VM:                  vm-azsl-01
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:          none
Temporary App Service resources: none
Temporary ARM deployment resources: none
```

## Exclusions

- Full AKS cluster deployment
- Production-grade CI/CD
- Advanced application architecture
- Autoscaling design beyond certificate scope

## Optional extension

- AKS architecture and concepts
- AKS hands-on only if justified later by learning value and cost

---

# Lab 03 — Identity, RBAC & Governance

Status: **completed**

## Purpose

Understand the difference between identity, authentication, authorization, and governance, and diagnose Azure access failures safely.

## Course coverage

- Course 8 — IAM and RBAC
- Course 9 — Microsoft Entra ID and advanced RBAC
- Course 12 — Azure Policy and compliance overlap

## Learning objectives

- Understand Microsoft Entra ID identity objects.
- Distinguish authentication from authorization.
- Understand Azure RBAC role definitions, role assignments, scope, and inheritance.
- Apply least-privilege access principles.
- Distinguish Azure RBAC from Microsoft Entra roles.
- Understand RBAC versus Azure Policy.
- Inspect access and governance configuration with Portal, CLI, and PowerShell.

## Included topics

- Microsoft Entra ID
- Users
- Groups
- Identity types
- Authentication concepts
- Authorization
- Azure RBAC
- Built-in roles
- Role assignments
- Scope
- Inheritance
- Least privilege
- Azure Policy basics
- Policy assignments
- Access troubleshooting

## Resources reused

- Existing subscription
- Existing Resource Group
- Existing VM or other resource as RBAC target

## Resources created

- Test Entra user when appropriate
- Test Entra group when appropriate
- Temporary RBAC assignments
- Temporary Policy assignments

## Resources deleted

- Temporary test identities when no longer useful
- Temporary role assignments
- Temporary Policy assignments

## Exclusions

- Full on-premises Active Directory deployment
- Microsoft Entra Connect deployment
- Hybrid identity infrastructure
- Complex Conditional Access design

## Progress

Completed practical coverage so far:

```text
Identity and access baseline
External/guest Entra user inspection
Azure RBAC role definitions and assignments
Subscription scope and inheritance
Reader least-privilege assignment
Controlled AuthorizationFailed troubleshooting
Virtual Machine Contributor remediation
Least-privilege cleanup
Azure RBAC versus Microsoft Entra roles
Microsoft Entra group creation and membership
Group-based RBAC assignment and verification
Azure Policy definition and parameter inspection
Resource Group scoped Policy assignment
Policy scope and inheritance observation
Policy initiative observation
Compliance evaluation and manual scan
Controlled Audit non-compliance scenario
Controlled Deny governance failure
RequestDisallowedByPolicy troubleshooting
Policy versus RBAC versus platform restriction diagnosis
Policy cleanup and baseline verification
```

Final cleanup state:

```text
AZSL RBAC Test User        → deleted
AZSL RBAC VM Operators     → deleted
Temporary RBAC assignments → removed
Temporary Policy resources → deleted
Temporary Policy assignment→ deleted
vm-azsl-01                 → VM deallocated
```

Known finding retained for later review:

- The primary administrative user currently has two duplicate `Owner` role assignment objects at subscription scope. They were intentionally left unchanged during the lab.

Completion checkpoint:

- Phases 1–5 completed.
- Temporary Microsoft Entra test user deleted.
- Temporary Microsoft Entra test group deleted.
- Temporary Lab 03 RBAC assignments removed.
- Temporary managed identities used for Policy testing deleted.
- Temporary Resource Group scoped Policy assignment deleted.
- Subscription-level `ASC Default` / Microsoft cloud security benchmark assignment was observed and intentionally left unchanged.
- Primary administrative `Owner` access was left unchanged.
- Final confirmed VM state: `VM deallocated`.
- Lab 03 environment returned to the retained Azure baseline.

Implementation files:

- `labs/03-identity-rbac-governance/README.md` — Lab 03 overview and phase index.
- `labs/03-identity-rbac-governance/LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md`
- `labs/03-identity-rbac-governance/LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md`
- `labs/03-identity-rbac-governance/LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md`
- `labs/03-identity-rbac-governance/LAB03_PHASE4_GROUP_BASED_RBAC.md`
- `labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md`

## Optional extension

- Custom Azure RBAC role
- Advanced Entra identity scenarios

---

# Lab 04 — Azure Networking & Connectivity Troubleshooting

Status: **planned**

## Purpose

Build the strongest practical networking and connectivity troubleshooting foundation in the project.

## Course coverage

- Course 2 — secure networking foundation
- Course 6 — troubleshooting methodology
- Course 7 — Azure networking fundamentals
- Course 8 — Azure networking and load balancing
- Course 9 — advanced networking and Network Watcher
- Course 10 — Azure network configuration

## Learning objectives

- Understand Azure IP configuration and network resource relationships.
- Configure and inspect VNets, subnets, NICs, and NSGs.
- Understand system routes and user-defined routes.
- Understand and test VNet peering.
- Understand Azure Load Balancer components.
- Diagnose VM connectivity using Azure-native and guest-level tools.
- Use Network Watcher capabilities where appropriate.

## Included topics

- Private and public IP addressing
- VNets
- Subnets
- NICs
- NSGs
- Inbound and outbound rules
- System routing
- User-defined routes
- Route tables
- VNet peering
- Azure Load Balancer
- Backend pools
- Health probes
- Load-balancing rules
- Network Watcher
- VM connectivity troubleshooting
- DNS and TCP/IP troubleshooting context

## Resources reused

- Existing Resource Group or dedicated networking Resource Group
- Existing base VM where practical

## Resources created

- VNet
- Multiple subnets as required
- NSG
- Route table
- VM-01
- Temporary VM-02 for multi-endpoint scenarios
- Optional second VNet for peering
- Azure Load Balancer

## Resources deleted

- VM-02 after multi-endpoint scenarios
- Second VNet after peering exercises
- Load Balancer after completion
- Route table when no longer required
- Other networking resources according to lab lifecycle

## Exclusions

- ExpressRoute deployment
- Production VPN gateway architecture
- Large multi-region network design
- Permanent Azure Firewall deployment
- Permanent Azure Bastion deployment

## Optional extensions

- Azure Bastion
- Azure Firewall
- Traffic Manager
- ExpressRoute architecture review

---

# Lab 05 — Azure Storage & Data Access

Status: **planned**

## Purpose

Understand Azure storage architecture, access paths, security controls, and common data-access failures.

## Course coverage

- Course 3 — storage and backup foundation
- Course 10 — Azure Storage
- Course 11 — storage monitoring overlap

## Learning objectives

- Understand Storage Account architecture.
- Work with Blob Storage and containers.
- Understand Azure Files and managed disks.
- Understand storage replication choices at certificate level.
- Distinguish storage identity, authorization, network access, and data availability problems.
- Inspect storage metrics and diagnostic information where useful.

## Included topics

- Storage Accounts
- Blob Storage
- Containers and blobs
- Azure Files
- Managed Disks
- Storage replication concepts
- Storage security
- Access control concepts
- Storage monitoring
- Data-access troubleshooting

## Resources reused

- Existing VM
- Existing managed disk
- Existing Entra/RBAC knowledge

## Resources created

- Storage Account
- Blob Container
- Test blob/object
- Optional Azure File Share

## Resources deleted

- Test data
- File Share if created only for the lab
- Storage Account when no longer required by later labs

## Exclusions

- Production data migration
- Large-scale storage lifecycle design
- Full Azure File Sync deployment
- Advanced Data Lake architecture

## Optional extension

- Azure File Sync concepts or hands-on exercise if later justified

---

# Lab 06 — Monitoring, Logs & Incident Diagnosis

Status: **planned**

## Purpose

Turn known Azure workloads into observable systems and use telemetry as evidence for support diagnosis.

## Course coverage

- Course 6 — diagnostic methodology
- Course 7 — Azure Monitor introduction
- Course 9 — network monitoring overlap
- Course 11 — Azure Monitoring and Analytics Fundamentals

## Learning objectives

- Understand the role of Azure Monitor.
- Distinguish metrics, Activity Log, resource logs, and guest telemetry.
- Use Log Analytics Workspace for centralized log analysis.
- Write basic KQL queries relevant to support investigation.
- Configure and inspect alerts.
- Understand Action Groups.
- Correlate telemetry with known configuration or service failures.
- Verify recovery using monitoring evidence.

## Included topics

- Azure Monitor
- Metrics
- Activity Log
- Resource logs
- Log Analytics Workspace
- KQL fundamentals
- Diagnostic settings
- Alert rules
- Thresholds and conditions
- Action Groups
- Dashboards and Workbooks concepts
- Incident investigation
- Performance and availability diagnosis

## Resources reused

- Existing VM
- Existing networking resources
- Existing Storage Account
- Existing NSG and RBAC configuration

## Resources created

- Log Analytics Workspace
- Diagnostic settings
- Alert Rule
- Action Group
- Additional monitoring configuration when required

## Resources deleted

- Temporary alerts and diagnostic configuration when no longer useful
- Log Analytics Workspace after all dependent labs are complete, unless retained intentionally for later analysis

## Exclusions

- Enterprise-scale observability design
- Large-volume log ingestion
- Production SIEM architecture

## Optional extension

- Microsoft Sentinel concepts and a tightly controlled hands-on exercise if cost and learning value justify it

---

# Lab 07 — Backup, Recovery, Updates & Compliance

Status: **planned**

## Purpose

Practice the operational lifecycle of protecting, maintaining, recovering, and governing an Azure workload.

## Course coverage

- Course 3 — backup and recovery foundation
- Course 12 — backup, security, compliance, patching, and disaster recovery

## Learning objectives

- Understand Azure Backup concepts and policies.
- Protect a VM or supported workload.
- Inspect backup jobs and recovery points.
- Perform or validate restore workflows at an appropriate scope.
- Understand backup failure diagnosis.
- Use Azure Update Manager concepts and assessment.
- Understand patching and update compliance.
- Apply basic Azure Policy-based compliance checks.
- Distinguish backup from disaster recovery.
- Understand RPO, RTO, replication, failover, and Site Recovery concepts.

## Included topics

- Azure Backup
- VM Backup
- Backup policies
- Recovery points
- Restore concepts and operations
- Backup monitoring
- Backup troubleshooting
- Azure Update Manager
- Update assessment
- Patching
- Update compliance
- Azure Policy
- Compliance state
- Auditing concepts
- Disaster recovery concepts
- RPO and RTO
- Azure Site Recovery concepts

## Resources reused

- Existing VM
- Existing Resource Group
- Existing monitoring knowledge
- Existing Policy knowledge

## Resources created

- Backup vault components as appropriate
- Backup policy
- Recovery point
- Update Manager configuration as required
- Temporary Policy assignments for compliance validation

## Resources deleted

- Backup configuration and vault resources after recovery exercises and retention constraints are satisfied
- Temporary Policy assignments
- Temporary update configuration
- Remaining lab Resource Groups at project cleanup

## Exclusions

- Production disaster recovery architecture
- Permanent cross-region replicated environment
- Full Azure Site Recovery deployment in the core track

## Optional extension

- Azure Site Recovery hands-on lab

---

# Optional Extension Labs

Optional labs do not block completion of the core project.

```text
Lab 02X — AKS Concepts and Optional Hands-on
Lab 03X — Advanced Entra ID / Custom RBAC
Lab 04X — Bastion / Firewall / Traffic Manager
Lab 05X — Azure File Sync
Lab 06X — Microsoft Sentinel
Lab 07X — Azure Site Recovery
```

These extensions should be added only when they provide clear learning value relative to complexity and Azure cost.

---

# Coursera Course Coverage Matrix

| Course | Project coverage |
|---|---|
| Course 1 — Introduction to Computers | Foundation knowledge; no Azure lab required |
| Course 2 — Introduction to Secure Networking | Foundation for Lab 04 |
| Course 3 — Software, Hardware, and Data Backup | Foundation for Labs 05 and 07 |
| Course 4 — Cybersecurity and Privacy | Foundation for Labs 03 and 04 |
| Course 5 — Microsoft 365 Ecosystem | Separate non-Azure practice where useful |
| Course 6 — Technical Diagnostics and Troubleshooting | Methodology used across every lab |
| Course 7 — Cloud Computing Essentials with Azure Management | Labs 01, 02, 03, 06 |
| Course 8 — Azure Cloud Services | Labs 01, 02, 03, 04 |
| Course 9 — Azure Identity and Networking Essentials | Labs 02, 03, 04, 06 |
| Course 10 — Azure Network Configuration | Labs 04 and 05 |
| Course 11 — Azure Monitoring and Analytics Fundamentals | Lab 06 |
| Course 12 — Azure Backup, Security, and Compliance Administration | Lab 07 |

---

# Completion Order

Recommended progression:

```text
[x] Lab 01 — Azure Foundation & Resource Lifecycle
[x] Lab 02 — Azure Compute & Administration
[x] Lab 03 — Identity, RBAC & Governance
[ ] Lab 04 — Azure Networking & Connectivity Troubleshooting
[ ] Lab 05 — Azure Storage & Data Access
[ ] Lab 06 — Monitoring, Logs & Incident Diagnosis
[ ] Lab 07 — Backup, Recovery, Updates & Compliance
```

Lab 01 is completed.

Lab 02 is completed.

Lab 03 is completed. Identity, Azure RBAC, scope/inheritance, least privilege, Microsoft Entra role comparison, group-based RBAC, Azure Policy basics, compliance evaluation, `Audit`/`Deny`, inheritance, initiatives, and governance troubleshooting were practiced.

Current stage: prepare Lab 04 — Azure Networking & Connectivity Troubleshooting.

Labs should be implemented in medium-sized increments rather than designed in full upfront.

---

# Certification Milestone

After completing the Coursera certificate and the core Azure Support Labs:

- Review AZ-900 exam objectives.
- Map completed labs to AZ-900 domains.
- Fill remaining knowledge gaps.
- Take AZ-900.
- Use the project as a foundation for later Azure administration labs and AZ-104 preparation.
