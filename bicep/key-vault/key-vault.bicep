param location string = resourceGroup().location

param name string

param virtualNetworkResourceGroupName string = ''
param virtualNetworkName string = ''
param virtualNetworkContainerAppsSubnetName string = ''

param enablePurgeProtection bool = true

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' existing = if (virtualNetworkName != '') {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = if (virtualNetworkContainerAppsSubnetName != '') {
  parent: virtualNetwork
  name: virtualNetworkContainerAppsSubnetName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
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
