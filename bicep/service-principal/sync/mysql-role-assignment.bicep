targetScope = 'resourceGroup'

param serverName string
param servicePrincipalId string
param roleDefintionId string

resource mySqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: serverName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: mySqlServer
  name: guid(mySqlServer.id, servicePrincipalId, roleDefintionId)
  properties: {
    roleDefinitionId: roleDefintionId
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
