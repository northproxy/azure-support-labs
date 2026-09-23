<#
Script: what-if.ps1

Purpose:
Compare the reproducible Bicep baseline with the current Azure environment
without changing Azure resources.

Project:
Azure Support Labs.

Learning focus:
Bicep, Azure Resource Manager, infrastructure drift, safe deployment validation.

Lifecycle:
Permanent project component.
#>

$ErrorActionPreference = "Stop"

$rg = "rg-azsl-01"
$baseline = Join-Path $PSScriptRoot "baseline"
$template = Join-Path $PSScriptRoot "main.bicep"

$vnet = Get-Content "$baseline\vnet-azsl-01.json" -Raw | ConvertFrom-Json
$nsg = Get-Content "$baseline\nsg-azsl-01.json" -Raw | ConvertFrom-Json
$sshKey = Get-Content "$baseline\vm-azsl-01-key.json" -Raw | ConvertFrom-Json

$vnetPrefix = $vnet.addressSpace.addressPrefixes[0]

$subnetObject = $vnet.subnets |
    Where-Object { $_.name -eq "subnet-azsl-01" }

$subnetPrefix = if ($subnetObject.addressPrefix) {
    $subnetObject.addressPrefix
}
else {
    $subnetObject.addressPrefixes[0]
}

$sshRule = $nsg.securityRules |
    Where-Object { $_.name -eq "allow-ssh-myip" }

$sshSource = $sshRule.sourceAddressPrefix
$sshPublicKey = $sshKey.publicKey

Write-Host "Resource Group: $rg"
Write-Host "Template:       $template"
Write-Host "VNet prefix:    $vnetPrefix"
Write-Host "Subnet prefix:  $subnetPrefix"
Write-Host "SSH source:     $sshSource"
Write-Host ""
Write-Host "Running Azure deployment what-if..."
Write-Host ""

$subscriptionState = az account show `
    --query state `
    --output tsv

if ($subscriptionState -ne "Enabled") {
    Write-Host ""
    Write-Host "Azure subscription state: $subscriptionState"
    Write-Host "What-if cannot run until the subscription is re-enabled."
    exit 1
}

az deployment group what-if `
    --resource-group $rg `
    --template-file $template `
    --parameters `
        vnetAddressPrefix="$vnetPrefix" `
        subnetAddressPrefix="$subnetPrefix" `
        sshSourceAddressPrefix="$sshSource" `
        sshPublicKey="$sshPublicKey"