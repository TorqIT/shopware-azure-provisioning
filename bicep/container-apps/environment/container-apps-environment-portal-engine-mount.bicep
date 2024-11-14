param containerAppsEnvironmentName string
param portalEngineStorageAccountName string
param portalEngineStorageAccountPublicBuildFileShareName string
param portalEnginePublicBuildStorageMountName string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource portalEngineStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: portalEngineStorageAccountName
}

resource portalEngineStorageMount 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: containerAppsEnvironment
  name: portalEnginePublicBuildStorageMountName
  properties: {
    azureFile: {
      accountName: portalEngineStorageAccountName
      accountKey: portalEngineStorageAccount.listKeys().keys[0].value
      shareName: portalEngineStorageAccountPublicBuildFileShareName
      accessMode: 'ReadWrite'
    }
  }
}
