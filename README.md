# Azure Support Labs

Practical Microsoft Azure labs created alongside the **Microsoft Cloud Support Associate Professional Certificate** on Coursera.

## Goal

The goal of this project is to turn course topics into hands-on Azure support experience.

Learning cycle:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify → Delete**

Instead of only learning Azure concepts theoretically, each important topic is practiced using real Azure resources where practical.

## Current Progress

* Courses 1–7 completed
* Course 8 — **Azure Cloud Services** in progress
* Lab 01 — **completed**
* Lab 02 — **completed**
* Lab 03 — **completed**
* Lab 04 — **completed** — Phases 1–5 completed

Lab 03 completion summary:

* identity and authentication/authorization baseline completed;
* Azure RBAC role definitions, assignments, scope, inheritance, and least privilege practiced;
* controlled `AuthorizationFailed` scenario diagnosed, fixed, and verified;
* Azure RBAC versus Microsoft Entra roles compared;
* group-based RBAC access verified;
* Azure Policy definitions, assignments, scope, inheritance, initiatives, and compliance evaluation practiced;
* controlled `Audit` and `Deny` scenarios completed, including `RequestDisallowedByPolicy` troubleshooting;
* temporary Microsoft Entra test user and group deleted;
* temporary Lab 03 RBAC and Policy assignments removed;
* temporary Policy test resources deleted;
* `vm-azsl-01` returned to `VM deallocated`;
* primary administrative access and inherited subscription-level security governance left unchanged.

## Project Structure

```text
azure-support-labs/
├── README.md
├── PROJECT.md
├── ROADMAP.md
├── AZURE_MAP.md
├── LAB_TEMPLATE.md
├── docs/
│   ├── architecture/
│   └── screenshots/
├── tools/
│   ├── README.md
│   ├── azure-output-sanitizer.html
│   ├── azure-output-sanitizer.css
│   ├── azure-output-sanitizer.js
│   └── azure-output-sanitizer.png
└── labs/
    ├── course-07/
    ├── course-08/
    ├── course-09/
    ├── course-10/
    ├── course-11/
    └── course-12/
```

## Project Tools

### Azure Output Sanitizer

The repository includes a local browser-based helper for sanitizing Azure CLI and PowerShell output before sharing it with ChatGPT or saving it in project documentation.

Location:

```text
tools/
```

The sanitizer currently replaces GUIDs, IPv4 addresses, UPN/email addresses, MAC addresses, and SSH public keys while preserving useful Azure troubleshooting context such as resource names, provider paths, regions, VM sizes, ports, protocols, CIDR prefix lengths, and resource states.

The tool runs locally in the browser and does not make network requests. It is a lightweight project helper, not a production DLP or secret-scanning solution.

See [`tools/README.md`](tools/README.md) for current rules and limitations.

## Labs

* [x] Lab 01 — Azure Foundation & Resource Lifecycle
* [x] Lab 02 — Azure Compute & Administration
* [x] Lab 03 — Identity, RBAC & Governance — **completed**
* [x] Lab 04 — Azure Networking & Connectivity Troubleshooting — **completed**
* [ ] Lab 05 — Azure Storage & Data Access
* [ ] Lab 06 — Monitoring, Logs & Incident Diagnosis
* [ ] Lab 07 — Backup, Recovery, Updates & Compliance

Lab 03 practical work covered Microsoft Entra users and groups, Azure RBAC roles and assignments, scope and inheritance, least privilege, controlled authorization failure diagnosis, Microsoft Entra roles versus Azure RBAC, group-based access, Azure Policy definitions and assignments, initiatives, compliance evaluation, `Audit` versus `Deny`, controlled governance failure diagnosis, and final cleanup.

Lab 04 progress so far:

* Phase 1 — Networking Baseline Inspection completed;
* VM → NIC → IP configuration, VNet, subnet, NSG attachment, effective security rules, and effective routes inspected;
* real SSH failure caused by an administrator public IPv4 change diagnosed and fixed by updating the restrictive `/32` NSG source;
* Phase 2 — controlled NSG SSH deny scenario completed;
* NSG priority behavior and effective security rules verified;
* Network Watcher IP flow verify identified the exact blocking rule;
* Phase 3 — controlled User-Defined Route failure completed;
* temporary `/32 → None` route reproduced an SSH timeout;
* effective routes and longest prefix match were used to diagnose the routing failure;
* temporary route and route table were removed;
* Phase 4 — VNet Peering & Private Connectivity Troubleshooting completed;
* created a temporary non-overlapping second VNet and private-only VM;
* verified no private connectivity before peering;
* created bidirectional VNet peering and observed the automatic `VNetPeering` effective route;
* verified private ICMP and TCP/22 connectivity;
* deleted one peering side as a controlled failure;
* observed `Disconnected` peering state and loss of the `VNetPeering` route;
* encountered and diagnosed `RemotePeeringIsDisconnected`;
* recreated both peering objects and verified connectivity and routing recovery;
* deleted all temporary Phase 4 resources;
* original retained networking baseline was restored.

* Phase 5 — Azure Load Balancer & Backend Connectivity Troubleshooting completed;
* diagnosed regional vCPU quota exhaustion and VM image-generation compatibility while preparing two temporary backend VMs;
* verified nginx and HTTP/80 independently on both backends;
* built and verified a Standard Public Load Balancer with frontend, backend pool, HTTP health probe, and TCP/80 rule;
* diagnosed an external HTTP timeout as a backend security-path problem;
* restored connectivity with a dedicated NIC-level backend NSG;
* verified traffic distribution across both healthy backends;
* stopped nginx on one backend and verified health-probe-based removal from new-flow distribution;
* restored nginx and verified the backend returned to rotation;
* deleted all temporary Phase 5 resources;
* retained Azure networking baseline was verified after cleanup.


## Main Areas

* Azure resource management
* Compute
* Networking
* Identity and RBAC
* Monitoring
* Backup and recovery
* Security and compliance
* Cloud troubleshooting

## Documentation

* [`PROJECT.md`](PROJECT.md) — project goals and learning method
* [`ROADMAP.md`](ROADMAP.md) — learning phases and progress
* [`AZURE_MAP.md`](AZURE_MAP.md) — growing Azure knowledge map
* [`LAB_TEMPLATE.md`](LAB_TEMPLATE.md) — standard structure for practical labs
* [`labs/03-identity-rbac-governance/README.md`](labs/03-identity-rbac-governance/README.md) — Lab 03 overview and phase index
* [`labs/03-identity-rbac-governance/LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md`](labs/03-identity-rbac-governance/LAB03_PHASE1_IDENTITY_AND_ACCESS_BASELINE.md) — identity and access baseline
* [`labs/03-identity-rbac-governance/LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md`](labs/03-identity-rbac-governance/LAB03_PHASE2_ROLE_DEFINITIONS_SCOPE_INHERITANCE_AND_LEAST_PRIVILEGE.md) — RBAC scope, inheritance, least privilege, and authorization troubleshooting
* [`labs/03-identity-rbac-governance/LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md`](labs/03-identity-rbac-governance/LAB03_PHASE3_AZURE_RBAC_VERSUS_MICROSOFT_ENTRA_ROLES.md) — Azure RBAC versus Microsoft Entra roles
* [`labs/03-identity-rbac-governance/LAB03_PHASE4_GROUP_BASED_RBAC.md`](labs/03-identity-rbac-governance/LAB03_PHASE4_GROUP_BASED_RBAC.md) — group-based RBAC
* [`labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md`](labs/03-identity-rbac-governance/LAB03_PHASE5_AZURE_POLICY_BASICS.md) — Azure Policy basics, compliance, and governance troubleshooting
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE1_NETWORKING_BASELINE_INSPECTION.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE1_NETWORKING_BASELINE_INSPECTION.md) — networking baseline, effective NSG rules, and effective routes
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE2_NSG_CONNECTIVITY_TROUBLESHOOTING.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE2_NSG_CONNECTIVITY_TROUBLESHOOTING.md) — controlled NSG SSH failure and Network Watcher diagnosis
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE3_ROUTING_AND_UDR_TROUBLESHOOTING.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE3_ROUTING_AND_UDR_TROUBLESHOOTING.md) — controlled UDR failure, effective routes, and longest prefix match
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE4_VNET_PEERING_PRIVATE_CONNECTIVITY_TROUBLESHOOTING.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE4_VNET_PEERING_PRIVATE_CONNECTIVITY_TROUBLESHOOTING.md) — VNet peering, private connectivity, effective routing, controlled peering failure, and recovery
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md) — backend topology preparation, quota troubleshooting, SKU selection, and image-generation compatibility
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md) — nginx backend preparation and independent HTTP verification
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md) — Standard Public Load Balancer build and control-plane verification
* [`labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md`](labs/04-networking-connectivity-troubleshooting/LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md) — backend security-path diagnosis, health-probe failure/recovery, and cleanup
* [`labs/04-networking-connectivity-troubleshooting/LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md`](labs/04-networking-connectivity-troubleshooting/LAB04_TROUBLESHOOTING_SSH_SOURCE_IP_CHANGED.md) — real SSH troubleshooting case caused by client public IP change

## Current Checkpoint

Labs 01–03 are completed.

Lab 04 is **completed**.

Completed:

```text
Phase 1 — Networking Baseline Inspection
Phase 2 — NSG Connectivity Troubleshooting
Phase 3 — Routing and User-Defined Route Troubleshooting
Phase 4 — VNet Peering & Private Connectivity Troubleshooting
Phase 5 — Azure Load Balancer & Backend Connectivity Troubleshooting
```

Current retained networking baseline:

```text
VM:                 vm-azsl-01
NIC:                vm-azsl-01284
VNet:               vnet-azsl-01
Subnet:             subnet-azsl-01
NSG:                nsg-azsl-01
Subnet route table: none
Active UDRs:        none
Effective routing:  Azure system routes only
VNet peerings:      none
Temporary peer VNet: none
Temporary peer VM:  none
SSH rule:           allow-ssh-myip
SSH connectivity:   working
```

Next:

**Lab 05 — Azure Storage & Data Access**

## Certification Path

Planned progression:

**Microsoft Cloud Support Associate → AZ-900 → further Azure administration labs → AZ-104**

## Cost and Security

Labs are designed to use low-cost resources.

Temporary resources should normally be deleted after each lab.

Sensitive data such as credentials, secrets, tenant information, billing data and raw private screenshots are not stored in this repository.
