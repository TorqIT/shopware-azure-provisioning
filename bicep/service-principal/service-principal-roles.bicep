param location string = resourceGroup().location

param servicePrincipalId string
param containerRegistryName string
param provisionInit bool
param initContainerAppJobName string
param phpContainerAppName string
param supervisordContainerAppName string
param databaseLongTermBackups bool = false
param databaseServerName string = ''
param databaseBackupsStorageAccountName string = ''
param fileStorageAccountName string = ''
param keyVaultName string
param keyVaultResourceGroupName string = resourceGroup().name

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}
resource initContainerAppJob 'Microsoft.App/jobs@2024-03-01' existing = if (provisionInit) {
  name: initContainerAppJobName
}
resource phpContainerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: phpContainerAppName
}
resource supervisordContainerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: supervisordContainerAppName
}
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = if (databaseLongTermBackups) {
  name: databaseServerName
}
resource databaseBackupsStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (databaseLongTermBackups) {
  name: databaseBackupsStorageAccountName
}
resource fileStorageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = if (!empty(fileStorageAccountName)) {
  name: fileStorageAccountName
}

resource acrPushRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: '8311e382-0749-4cb8-b61a-304f252e45ec'
}
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}
resource storageBlobContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = if (databaseLongTermBackups) {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
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

resource phpContainerAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: phpContainerApp
  name: guid(phpContainerApp.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource supervisordContainerAppRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: supervisordContainerApp
  name: guid(supervisordContainerApp.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

module keyVaultRoleAssignment './service-principal-key-vault-role-assignment.bicep' = {
  name: 'service-principal-key-vault-role-assignment'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    servicePrincipalId: servicePrincipalId
  }
}

resource databaseServerContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (databaseLongTermBackups) {
  scope: databaseServer
  name: guid(databaseServer.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
resource databaseBackupsStorageAccountContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (databaseLongTermBackups) {
  scope: databaseBackupsStorageAccount
  name: guid(databaseBackupsStorageAccount.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
resource databaseBackupsStorageAccountBlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (databaseLongTermBackups) {
  scope: databaseBackupsStorageAccount
  name: guid(databaseBackupsStorageAccount.id, servicePrincipalId, storageBlobContributorRoleDefinition.id)
  properties: {
    roleDefinitionId: storageBlobContributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource fileStorageAccountContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(fileStorageAccountName)) {
  scope: fileStorageAccount
  name: guid(fileStorageAccount.id, servicePrincipalId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
