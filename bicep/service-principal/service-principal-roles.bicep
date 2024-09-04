param location string = resourceGroup().location

param servicePrincipalId string
param containerRegistryName string
param provisionInit bool
param shopwareInitContainerAppJobName string
param shopwareWebContainerAppName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}
resource initContainerAppJob 'Microsoft.App/jobs@2024-03-01' existing = if (provisionInit) {
  name: shopwareInitContainerAppJobName
}
resource webContainerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: shopwareWebContainerAppName
}
resource acrPushRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: '8311e382-0749-4cb8-b61a-304f252e45ec'
}
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource containerRegistryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, servicePrincipalId, acrPushRoleDefinition.id)
  properties: {
    roleDefinitionId: acrPushRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource initContainerAppJobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (provisionInit) {
  scope: initContainerAppJob
  name: guid(initContainerAppJob.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource webContainerAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: webContainerApp
  name: guid(webContainerApp.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
