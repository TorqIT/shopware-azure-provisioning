param containerAppsEnvironmentName string
param storageAccountName string
param fileShareName string
param mountName string
param mountAccessMode string
param storageType string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageAccountName
}

resource mount 'Microsoft.App/managedEnvironments/storages@2024-10-02-preview' = {
  parent: containerAppsEnvironment
  name: mountName
  properties: {
    nfsAzureFile: (storageType == 'NfsAzureFile') ? {
      server: '${storageAccountName}.file.${environment().suffixes.storage}'
      shareName: '/${storageAccountName}/${fileShareName}'
      accessMode: mountAccessMode
    } : null
    azureFile: (storageType == 'AzureFile') ? {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      accessMode: mountAccessMode
      shareName: fileShareName
    } : null
  }
}
