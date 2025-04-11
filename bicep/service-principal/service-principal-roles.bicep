param location string = resourceGroup().location

param servicePrincipalId string
param containerRegistryName string
param databaseLongTermBackups bool = false
param databaseBackupsStorageAccountName string = ''
param keyVaultName string
param keyVaultResourceGroupName string = resourceGroup().name

// Existing resources
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}
resource databaseBackupsStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (databaseLongTermBackups) {
  name: databaseBackupsStorageAccountName
}

// Role definitions
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

// Role assignments
resource containerRegistryRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, servicePrincipalId, acrPushRoleDefinition.id)
  properties: {
    roleDefinitionId: acrPushRoleDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
resource resourceGroupContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(resourceGroup().id, servicePrincipalId, contributorRoleDefinition.id)
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
