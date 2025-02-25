param containerAppsEnvironmentName string
param storageAccountName string
param fileShareName string
param mountName string
param mountAccessMode string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource mount 'Microsoft.App/managedEnvironments/storages@2024-10-02-preview' = {
  parent: containerAppsEnvironment
  name: mountName
  properties: {
    nfsAzureFile: {
      server: '${storageAccountName}.file.${environment().suffixes.storage}'
      shareName: '/${storageAccountName}/${fileShareName}'
      accessMode: mountAccessMode
    }
  }
}
