# Lab 04 — Phase 5: Create First Load Balancer Backend VM

## Purpose

Create the first private backend virtual machine for the Azure Load Balancer troubleshooting lab.

This VM is intentionally created:

- in the existing `rg-azsl-01` Resource Group;
- in `vnet-azsl-01`;
- in `subnet-azsl-01`;
- in Availability Zone 1;
- without a Public IP;
- without a NIC-level NSG;
- with a Standard SSD OS disk;
- with automatic NIC and OS disk deletion when the VM is deleted.

The VM will later become a member of the Azure Load Balancer backend pool.

---

## PowerShell variables

```powershell
# Existing Azure Resource Group used by the lab.
$resourceGroup = "rg-azsl-01"

# Azure region used by the existing lab environment.
$location = "austriaeast"

# Name of the first temporary Load Balancer backend VM.
$vmName = "vm-azsl-lb-01"

# VM size selected after quota and SKU availability troubleshooting.
# Standard_D1_v2 uses the Standard Dv2 Family quota.
$vmSize = "Standard_D1_v2"

# Availability Zone selected for both Load Balancer backend VMs.
$zone = "1"

# Ubuntu 24.04 LTS Azure CLI image alias.
$image = "Ubuntu2404"

# Local administrator account created inside the Linux VM.
$adminUsername = "azureuser"

# Azure SSH public key resource name associated with this VM.
$sshKeyName = "vm-azsl-lb-01-key"

# Existing Virtual Network from the retained Lab 04 baseline.
$vnetName = "vnet-azsl-01"

# Existing subnet where the backend VM NIC will be connected.
$subnetName = "subnet-azsl-01"

# Managed OS disk storage type.
$storageSku = "StandardSSD_LRS"
```

---

## Create `vm-azsl-lb-01`

```powershell
az vm create `
  --resource-group $resourceGroup `
  --name $vmName `
  --location $location `
  --zone $zone `
  --size $vmSize `
  --image $image `
  --admin-username $adminUsername `
  --generate-ssh-keys `
  --ssh-key-name $sshKeyName `
  --vnet-name $vnetName `
  --subnet $subnetName `
  --public-ip-address '""' `
  --nsg '""' `
  --storage-sku $storageSku `
  --os-disk-delete-option Delete `
  --nic-delete-option Delete
```

---

## Variable reference

| Variable | Value | Purpose |
|---|---|---|
| `$resourceGroup` | `rg-azsl-01` | Existing Resource Group containing the Lab 04 environment |
| `$location` | `austriaeast` | Azure region used by the lab |
| `$vmName` | `vm-azsl-lb-01` | Name of the first Load Balancer backend VM |
| `$vmSize` | `Standard_D1_v2` | VM SKU selected to fit the available Standard Dv2 Family quota |
| `$zone` | `1` | Places the VM in Availability Zone 1 |
| `$image` | `Ubuntu2404` | Ubuntu 24.04 LTS image |
| `$adminUsername` | `azureuser` | Linux administrator username |
| `$sshKeyName` | `vm-azsl-lb-01-key` | Azure SSH public key resource name |
| `$vnetName` | `vnet-azsl-01` | Existing Virtual Network |
| `$subnetName` | `subnet-azsl-01` | Existing subnet used by the backend VM |
| `$storageSku` | `StandardSSD_LRS` | Standard SSD managed OS disk |

---

## Important command options

### `--generate-ssh-keys`

Generates an SSH key pair if the required local key material does not already exist.

Together with:

```powershell
--ssh-key-name $sshKeyName
```

the Azure SSH public key resource is given the explicit lab-friendly name:

```text
vm-azsl-lb-01-key
```

---

### `--public-ip-address '""'`

Prevents Azure CLI from creating a Public IP resource for the VM.

The backend VM should therefore be reachable only through private Azure networking unless another management path is later introduced.

Expected result:

```text
Public IP: none
```

---

### `--nsg '""'`

Prevents Azure CLI from automatically creating and attaching a new Network Security Group to the VM NIC.

For the initial Load Balancer baseline we want:

```text
NIC-level NSG: none
```

This keeps the first connectivity tests simple and avoids introducing an additional filtering variable before Load Balancer troubleshooting begins.

---

### `--storage-sku $storageSku`

Creates the managed OS disk using:

```text
StandardSSD_LRS
```

This matches the low-cost lab design.

---

### `--os-disk-delete-option Delete`

Configures the VM OS disk to be deleted automatically when the temporary VM is deleted.

Desired lab lifecycle:

```text
VM deleted
└── OS disk deleted automatically
```

---

### `--nic-delete-option Delete`

Configures the VM NIC to be deleted automatically with the temporary VM.

Desired lab lifecycle:

```text
VM deleted
├── OS disk deleted automatically
└── NIC deleted automatically
```

---

## Expected architecture after creation

```text
Resource Group: rg-azsl-01
│
├── Virtual Network: vnet-azsl-01
│   └── Subnet: subnet-azsl-01
│       └── NIC: <generated-or-created-NIC-name>
│           ├── Private IP: assigned by Azure
│           ├── Public IP: none
│           └── NIC NSG: none
│
├── Virtual Machine: vm-azsl-lb-01
│   ├── Size: Standard_D1_v2
│   ├── Zone: 1
│   ├── OS: Ubuntu 24.04 LTS
│   └── Admin user: azureuser
│
├── SSH Public Key: vm-azsl-lb-01-key
│
└── Managed OS Disk
    ├── SKU: StandardSSD_LRS
    └── Delete with VM: yes
```

---

## Verification checkpoint

Do **not** create `vm-azsl-lb-02` yet.

First verify the first VM:

```powershell
az vm show `
  --resource-group $resourceGroup `
  --name $vmName `
  --show-details `
  --query "{
    Name:name,
    Location:location,
    Size:hardwareProfile.vmSize,
    Zones:zones,
    PrivateIP:privateIps,
    PublicIP:publicIps,
    ProvisioningState:provisioningState
  }" `
  -o yaml
```

Then obtain the VM NIC name:

```powershell
$nicId = az vm show `
  --resource-group $resourceGroup `
  --name $vmName `
  --query "networkProfile.networkInterfaces[0].id" `
  -o tsv

$nicName = ($nicId -split "/")[-1]

$nicName
```

Inspect the NIC:

```powershell
az network nic show `
  --resource-group $resourceGroup `
  --name $nicName `
  --query "{
    Name:name,
    ProvisioningState:provisioningState,
    PrivateIP:ipConfigurations[0].privateIPAddress,
    PrivateIPAllocation:ipConfigurations[0].privateIPAllocationMethod,
    Subnet:ipConfigurations[0].subnet.id,
    PublicIP:ipConfigurations[0].publicIPAddress.id,
    NSG:networkSecurityGroup.id
  }" `
  -o yaml
```

Expected findings:

```text
VM:                  vm-azsl-lb-01
Size:                Standard_D1_v2
Zone:                1
Private IP:          assigned
Public IP:           none
VNet:                vnet-azsl-01
Subnet:              subnet-azsl-01
NIC-level NSG:       none
OS disk:             StandardSSD_LRS
Delete OS disk:      enabled
Delete NIC:          enabled
Provisioning state:  Succeeded
```

Only after this checkpoint is verified should `vm-azsl-lb-02` be created.
