param appDebug string
param appEnv string
param storageAccountName string
param storageAccountPublicContainerName string
param storageAccountPrivateContainerName string
param storageAccountKeySecretName string
param additionalVars array

var defaultEnvVars = [
  {
    name: 'AZURE_STORAGE_ACCOUNT_PUBLIC_CONTAINER'
    value: storageAccountPublicContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_PRIVATE_CONTAINER'
    value: storageAccountPrivateContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: storageAccountKeySecretName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
]

output envVars array = concat(defaultEnvVars, additionalVars)
