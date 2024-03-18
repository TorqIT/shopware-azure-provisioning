param location string = resourceGroup().location

param serverName string

param administratorLogin string
@secure()
param administratorPassword string

param skuName string
param skuTier string
param storageSizeGB int

param backupRetentionDays int
param geoRedundantBackup bool

param databaseName string

param longTermBackups bool
param databaseBackupsStorageAccountName string
param databaseBackupStorageAccountContainerName string
param databaseBackupsStorageAccountSku string
param databaseBackupsStorageAccountPrivateEndpointName string
param databaseBackupsStorageAccountPrivateEndpointNicName string

param virtualNetworkResourceGroupName string
param virtualNetworkName string
param virtualNetworkDatabaseSubnetName string
param virtualNetworkStorageAccountPrivateEndpointSubnetName string

param privateDnsZoneForDatabaseId string
param privateDnsZoneForStorageAccountsId string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}
resource databaseSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkDatabaseSubnetName
}

resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: '8.0.21'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    network: {
      delegatedSubnetResourceId: databaseSubnet.id
      privateDnsZoneResourceId: privateDnsZoneForDatabaseId
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup ? 'Enabled' : 'Disabled'
    }
  }
  
  resource database 'databases' = {
    name: databaseName
    properties: {
      charset: 'utf8mb4'
      collation: 'utf8mb4_unicode_ci'
    }
  }
}

module databaseBackupStorageAccount './database-backup-storage-account.bicep' = if (longTermBackups) {
  name: 'database-backup-storage-account'
  params: {
    location: location
    storageAccountName: databaseBackupsStorageAccountName
    storageAccountSku: databaseBackupsStorageAccountSku
    storageAccountContainerName: databaseBackupStorageAccountContainerName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkStorageAccountPrivateEndpointSubnetName
    privateDnsZoneId: privateDnsZoneForStorageAccountsId
    privateEndpointName: databaseBackupsStorageAccountPrivateEndpointName
    privateEndpointNetworkInterfaceName: databaseBackupsStorageAccountPrivateEndpointNicName
  }
}
