param location string = resourceGroup().location

param name string
param localIpAddress string = ''

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
    networkAcls: {
      defaultAction: 'Deny'
      // TODO VNet access so Container Apps can directly pull secrets from here
      ipRules: localIpAddress != '' ? [
        {
          value: localIpAddress
        }
      ] : []
    }
  }
}
