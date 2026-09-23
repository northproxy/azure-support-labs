@description('Azure region for all baseline resources.')
param location string = 'austriaeast'

@description('Source CIDR allowed to connect to SSH, for example x.x.x.x/32.')
param sshSourceAddressPrefix string

@description('SSH public key used for the Linux VM.')
param sshPublicKey string

@description('VNet address prefix.')
param vnetAddressPrefix string

@description('Subnet address prefix.')
param subnetAddressPrefix string

@description('Linux administrator username.')
param adminUsername string = 'azureuser'

@description('Exact Ubuntu Marketplace image version. Change deliberately if unavailable.')
param imageVersion string = '24.04.202608070'

@description('Storage account name. Must be globally unique.')
param storageAccountName string = 'stazsl05npx01'

var vmName = 'vm-azsl-01'
var vmSize = 'Standard_B2ats_v2'
var osDiskName = '${vmName}-osdisk'

var sshKeyName = 'vm-azsl-01-key'
var nsgName = 'nsg-azsl-01'
var vnetName = 'vnet-azsl-01'
var subnetName = 'subnet-azsl-01'
var publicIpName = 'vm-azsl-01-ip'
var nicName = 'vm-azsl-01284'
var ipConfigName = 'ipconfig1'

//
// Network Security Group
//

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
}

resource allowSshRule 'Microsoft.Network/networkSecurityGroups/securityRules@2024-05-01' = {
  parent: nsg
  name: 'allow-ssh-myip'
  properties: {
    priority: 1000
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '22'
    sourceAddressPrefix: sshSourceAddressPrefix
    destinationAddressPrefix: '*'
  }
}

//
// Virtual Network
//

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
  }
}

//
// Public IP
//

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

//
// Network Interface
//

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: ipConfigName
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

//
// Azure SSH public-key resource
//

resource sshKey 'Microsoft.Compute/sshPublicKeys@2023-03-01' = {
  name: sshKeyName
  location: location
  properties: {
    publicKey: sshPublicKey
  }
}

//
// Virtual Machine
//

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location

  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }

    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: imageVersion
      }

      osDisk: {
        name: osDiskName
        osType: 'Linux'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'

        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }

    osProfile: {
      computerName: vmName
      adminUsername: adminUsername

      linuxConfiguration: {
        disablePasswordAuthentication: true
        provisionVMAgent: true

        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

//
// Storage Account
//

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location

  sku: {
    name: 'Standard_LRS'
  }

  kind: 'StorageV2'

  properties: {
    accessTier: 'Hot'

    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true

    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: false

    publicNetworkAccess: 'Enabled'

    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

//
// Blob service
//

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'

  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
      allowPermanentDelete: false
    }

    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }

    isVersioningEnabled: false
  }
}

//
// Blob container
//

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: 'azsl05-data'

  properties: {
    publicAccess: 'None'
  }
}

//
// Useful outputs
//

output vmResourceId string = vm.id
output nicResourceId string = nic.id
output publicIpResourceId string = publicIp.id
output storageAccountResourceId string = storageAccount.id
output blobContainerResourceId string = blobContainer.id