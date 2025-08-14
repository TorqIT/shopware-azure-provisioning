param location string = resourceGroup().location

param keyVaultName string
param managedIdentityForKeyVaultId string

param secrets array

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = [for secret in secrets: {
  parent: keyVault
  name: secret.secretNameInKeyVault
}]

output secrets array = [for i in range(0, length(secrets)): {
  name: secrets[i].secretRefInContainerApp
  keyVaultUrl: keyVaultSecrets[i].properties.secretUri
  identity: managedIdentityForKeyVaultId
}]
// Only define environment variables for secrets with the secretEnvVarNameInContainerApp (or envVarNameInContainerApp) property
var secretsWithEnvVars = filter(secrets, secret => contains(secret, 'secretEnvVarNameInContainerApp') || contains(secret, 'envVarNameInContainerApp'))
output envVars array = [for secret in secretsWithEnvVars: {
  name: secret.secretEnvVarNameInContainerApp
  secretRef: secret.secretRefInContainerapp
}]
