targetScope = 'resourceGroup'

param serverName string
param servicePrincipalId string
param roleDefintionId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: serverName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, servicePrincipalId, roleDefintionId)
  properties: {
    roleDefinitionId: roleDefintionId
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
