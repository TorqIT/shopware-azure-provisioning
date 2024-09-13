param keyVaultName string
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// Built-in role definition for Key Vault Secrets Officer
resource keyVaultSecretsOfficerRoleDef 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}
resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(resourceGroup().id, keyVaultSecretsOfficerRoleDef.id)
  properties: {
    roleDefinitionId: keyVaultSecretsOfficerRoleDef.id
    principalId: principalId
    principalType: 'User'
  }
}
