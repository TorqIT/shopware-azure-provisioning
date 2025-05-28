param containerAppsEnvironmentName string
param portalEngineStorageAccountName string
@secure()
param portalEngineStorageAccountKey string
param portalEngineStorageAccountPublicBuildFileShareName string
param portalEnginePublicBuildStorageMountName string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource portalEngineStorageMount 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: containerAppsEnvironment
  name: portalEnginePublicBuildStorageMountName
  properties: {
    azureFile: {
      accountName: portalEngineStorageAccountName
      accountKey: portalEngineStorageAccountKey 
      shareName: portalEngineStorageAccountPublicBuildFileShareName
      accessMode: 'ReadWrite'
    }
  }
}
