param location string
param resourceGroupName string
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${resourceGroupName}-container-app-managed-id'
  location: location
}

@description('This is the built-in Key Vault Secret User role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretUserRoleRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(resourceGroupName, managedIdentity.id, keyVaultSecretUserRoleRoleDefinition.id)
  properties: {
    roleDefinitionId: keyVaultSecretUserRoleRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output id string = managedIdentity.id
