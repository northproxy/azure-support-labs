# Azure Knowledge Map

Only add topics after they have been studied or practiced.

Azure
├── Resource management
│   ├── Subscription
│   ├── Resource Group
│   ├── Resources
│   ├── Resource Provider
│   ├── Azure Resource Manager
│   └── ARM Template
│       ├── Parameters
│       ├── Dependencies
│       └── Deployment validation
│
├── Compute
│   ├── Virtual Machine
│   │   ├── Lifecycle
│   │   ├── Sizing
│   │   └── Managed OS / data disk relationships
│   └── App Service
│       ├── App Service Plan
│       ├── Web App
│       ├── Runtime configuration
│       ├── Application settings
│       ├── ZIP deployment
│       ├── Scale up / down
│       ├── Scale out / in
│       └── Startup troubleshooting
│
├── Administration
│   ├── Azure Portal
│   ├── Azure CLI
│   ├── Azure PowerShell
│   └── ARM-based deployment
│
├── Networking
│   ├── Virtual Network
│   │   └── VNet Peering
│   │       ├── Non-overlapping address spaces
│   │       ├── Bidirectional peering configuration
│   │       ├── Peering state
│   │       │   ├── Connected
│   │       │   └── Disconnected
│   │       ├── Private cross-VNet connectivity
│   │       └── RemotePeeringIsDisconnected troubleshooting
│   ├── Subnet
│   ├── Public IP
│   ├── Network Interface
│   ├── Network Security Group
│   │   ├── Inbound rules
│   │   ├── Outbound rules
│   │   ├── Rule priority
│   │   ├── Default rules
│   │   ├── Effective security rules
│   │   └── SSH source /32 troubleshooting
│   ├── Azure Load Balancer
│   │   ├── Standard Public Load Balancer
│   │   ├── Frontend IP configuration
│   │   ├── Backend pool
│   │   ├── Health probe
│   │   │   ├── HTTP probe
│   │   │   └── Backend health convergence
│   │   ├── Load-balancing rule
│   │   ├── Backend traffic distribution
│   │   ├── Backend security path
│   │   └── Backend failure and recovery troubleshooting
│   ├── Network Watcher
│   │   └── IP flow verify
│   └── Routing
│       ├── System routes
│       ├── Route table
│       ├── User-Defined Route
│       ├── Effective routes
│       ├── Longest prefix match
│       └── Next hop
│           ├── Internet
│           ├── VnetLocal
│           ├── VNetPeering
│           └── None
│
├── Storage
│   └── Managed Disk
│
├── Identity
│   ├── Microsoft Entra ID
│   │   ├── User
│   │   ├── External / guest user
│   │   ├── Group
│   │   ├── Group membership
│   │   └── Microsoft Entra roles
│   │       └── Global Administrator
│   ├── Authentication
│   ├── Authorization
│   └── Azure RBAC
│       ├── Security principal
│       ├── Role definition
│       │   ├── Owner
│       │   ├── Contributor
│       │   ├── Reader
│       │   └── Virtual Machine Contributor
│       ├── Role assignment
│       ├── Scope
│       │   ├── Subscription
│       │   ├── Resource Group
│       │   └── Resource
│       ├── Inheritance
│       ├── Least privilege
│       ├── Group-based access
│       └── AuthorizationFailed troubleshooting
│
├── Monitoring
│   └── Activity Log
│
├── Backup & Recovery
│
└── Security & Compliance
    └── Azure Policy
        ├── Policy definition
        │   ├── Built-in definition
        │   ├── Parameters
        │   └── Mode
        │       └── Indexed
        ├── Policy assignment
        ├── Scope
        │   ├── Subscription
        │   └── Resource Group
        ├── Inheritance
        ├── Policy initiative
        ├── Effects
        │   ├── Audit
        │   ├── Deny
        │   └── Disabled
        ├── Compliance evaluation
        │   ├── Compliant
        │   └── NonCompliant
        ├── RBAC versus Policy
        └── RequestDisallowedByPolicy troubleshooting
