param location string = resourceGroup().location

param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param storageAccountAccessTier string
param storageAccountFileShareName string
param storageAccountFileShareAccessTier string

param databaseServerName string
param databaseAdminUser string
@secure()
param databaseAdminPassword string
param databaseSkuName string
param databaseSkuTier string
param databaseStorageSizeGB int
param databaseBackupRetentionDays int
param databaseName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkContainerAppsSubnetName string
param virtualNetworkDatabaseSubnetName string

param containerAppsEnvironmentName string
param containerAppsEnvironmentStorageMountName string

param n8nContainerAppName string
param n8nContainerAppCpuCores string
param n8nContainerAppMemory string
param n8nContainerAppMinReplicas int
param n8nContainerAppMaxReplicas int
param n8nContainerAppCustomDomains array
param n8nContainerAppVolumeName string

module n8nFileStorage './n8n-file-storage.bicep' = {
  name: 'n8n-file-storage'
  params: {
    storageAccountName: storageAccountName
    storageAccountKind: storageAccountKind
    storageAccountSku: storageAccountSku
    storageAccountAccessTier: storageAccountAccessTier
    storageAccountFileShareAccessTier: storageAccountFileShareAccessTier
    storageAccountFileShareName: storageAccountFileShareName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkContainerAppsSubnetName: virtualNetworkContainerAppsSubnetName
  }
}

module n8nPostgresDatabase './n8n-database.bicep' = {
  name: 'n8n-postgres-database'
  params: {
    location: location
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseBackupRetentionDays: databaseBackupRetentionDays
    databaseAdminUser: databaseAdminUser
    databaseAdminPassword: databaseAdminPassword
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
    databaseStorageSizeGB: databaseStorageSizeGB
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkDatabaseSubnetName: virtualNetworkDatabaseSubnetName
  }
}

module n8nContainerApp './n8n-container-app.bicep' = {
  name: 'n8n-container-app'
  dependsOn: [n8nFileStorage, n8nPostgresDatabase]
  params: {
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppsEnvironmentStorageMountName: containerAppsEnvironmentStorageMountName
    n8nContainerAppCpuCores: n8nContainerAppCpuCores
    n8nContainerAppCustomDomains: n8nContainerAppCustomDomains
    n8nContainerAppMaxReplicas: n8nContainerAppMaxReplicas
    n8nContainerAppMemory: n8nContainerAppMemory
    n8nContainerAppMinReplicas: n8nContainerAppMinReplicas
    n8nContainerAppName: n8nContainerAppName
    n8nContainerAppVolumeName: n8nContainerAppVolumeName
    storageAccountName: storageAccountName
    storageAccountFileShareName: storageAccountFileShareName
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseAdminUser
    databasePassword: databaseAdminPassword
  }
}
