targetScope = 'subscription'

param syncerServicePrincipalId string

param sourceSubscriptionId string = subscription().subscriptionId
param sourceResourceGroupName string
param sourceMySqlServerName string
param sourceStorageAccountName string

param targetSubscriptionId string = subscription().subscriptionId
param targetResourceGroupName string
param targetMySqlServerName string
param targetStorageAccountName string
param targetPhpContainerAppName string
param targetSupervisordContainerAppName string

// ROLE DEFINITION IDs
var storageBlobDataReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
var storageBlobDataContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

// ROLE ASSIGNMENTS
module sourceMySqlContributorRoleAssignment './mysql-role-assignment.bicep' = {
  scope: resourceGroup(sourceSubscriptionId, sourceResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    serverName: sourceMySqlServerName
    roleDefintionId: contributorRoleDefinitionId
  }
}
module sourceStorageBlobDataReaderRoleAssignment './storage-account-role-assignment.bicep' = {
  scope: resourceGroup(sourceSubscriptionId, sourceResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    serverName: sourceStorageAccountName
    roleDefintionId: storageBlobDataReaderRoleDefinitionId
  }
}
module sourceStorageContributorRoleAssignment './storage-account-role-assignment.bicep' = {
  scope: resourceGroup(sourceSubscriptionId, sourceResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    serverName: sourceStorageAccountName
    roleDefintionId: contributorRoleDefinitionId
  }
}
module targetMySqlContributorRoleAssignment './mysql-role-assignment.bicep' = {
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    serverName: targetMySqlServerName
    roleDefintionId: contributorRoleDefinitionId
  }
}
module targetStorageBlobDataContributorRoleAssignment './storage-account-role-assignment.bicep' = {
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    serverName: targetStorageAccountName
    roleDefintionId: storageBlobDataContributorRoleDefinitionId
  }
}
module targetStorageContributorRoleAssignment './storage-account-role-assignment.bicep' = {
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    serverName: targetStorageAccountName
    roleDefintionId: contributorRoleDefinitionId
  }
}
module targetPhpContainerAppContributorRoleAssignment './container-app-role-assignment.bicep' = {
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    containerAppName: targetPhpContainerAppName
    roleDefintionId: contributorRoleDefinitionId
  }
}
module targetSupervisordContainerAppContributorRoleAssignment './container-app-role-assignment.bicep' = {
  scope: resourceGroup(targetSubscriptionId, targetResourceGroupName)
  params: {
    servicePrincipalId: syncerServicePrincipalId
    containerAppName: targetSupervisordContainerAppName
    roleDefintionId: contributorRoleDefinitionId
  }
}
