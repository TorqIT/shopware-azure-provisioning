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
