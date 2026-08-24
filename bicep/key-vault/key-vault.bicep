param location string = resourceGroup().location

param name string

param virtualNetworkResourceGroupName string = ''
param virtualNetworkName string = ''
param virtualNetworkContainerAppsSubnetName string = ''

param enablePurgeProtection bool = true

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-10-01' existing = if (virtualNetworkName != '') {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-10-01' existing = if (virtualNetworkContainerAppsSubnetName != '') {
  parent: virtualNetwork
  name: virtualNetworkContainerAppsSubnetName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  //checkov:skip=CKV_AZURE_42: soft delete is explicit; purge protection is intentionally parameterizable for non-prod environments
  //checkov:skip=CKV_AZURE_110: purge protection is parameterizable (defaults true); Checkov cannot evaluate the ternary
  //checkov:skip=CKV_AZURE_189: VNet service endpoint firewall rules restrict access; Disabled would block VNet rules and require a private endpoint
  location: location
  name: name
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: [
    ]
    enableSoftDelete: true
    enablePurgeProtection: enablePurgeProtection ? true : null // null is required to set this property to false
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: virtualNetworkName != '' ? [
        {
          id: subnet.id
        }
      ] : []
    }
  }
}

output keyVault object = keyVault
