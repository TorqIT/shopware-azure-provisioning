param location string = resourceGroup().location

param keyVaultName string
param servicePrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretsUserDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, servicePrincipalId, keyVaultSecretsUserDefinition.id)
  properties: {
    roleDefinitionId: keyVaultSecretsUserDefinition.id
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
