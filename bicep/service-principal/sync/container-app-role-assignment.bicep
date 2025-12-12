targetScope = 'resourceGroup'

param containerAppName string
param servicePrincipalId string
param roleDefintionId string
  
resource containerApp 'Microsoft.App/containerApps@2025-07-01' existing = {
  name: containerAppName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerApp
  name: guid(containerApp.id, servicePrincipalId, roleDefintionId)
  properties: {
    roleDefinitionId: roleDefintionId
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
