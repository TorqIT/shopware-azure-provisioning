param location string = resourceGroup().location

param name string
param localIpAddress string = ''
// param virtualNetworkName string

// resource virtualNetwork 'Microsoft.ScVmm/virtualNetworks@2023-04-01-preview' existing = {
//   name: virtualNetworkName
//   scope: resourceGroup()
// }

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
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    networkAcls: {
      defaultAction: 'Deny'
      // TODO VNet access - likely just for Container Apps subnet?
      // virtualNetworkRules: [
      //   {
      //   }
      // ]
      ipRules: localIpAddress != '' ? [
        {
          value: localIpAddress
        }
      ] : []
    }
  }
}
