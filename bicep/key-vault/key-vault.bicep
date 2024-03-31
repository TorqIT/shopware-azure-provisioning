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
    enabledForTemplateDeployment: true
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: localIpAddress != '' ? [
        {
          value: localIpAddress
        }
      ] : []
    }
  }
}
