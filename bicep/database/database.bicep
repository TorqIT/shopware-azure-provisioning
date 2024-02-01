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

param databaseBackupsStorageAccountName string
param databaseBackupStorageAccountContainerName string
param databaseBackupsStorageAccountSku string
param storageAccountPrivateDnsZoneId string

param virtualNetworkResourceGroupName string
param virtualNetworkName string
param virtualNetworkDatabaseSubnetName string
param virtualNetworkContainerAppsSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}
resource databaseSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkDatabaseSubnetName
}

// A private DNS zone is required for VNet integration
resource privateDNSzoneForDatabase 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${serverName}.private.mysql.database.azure.com'
  location: 'global'
}
resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDNSzoneForDatabase
  name: 'virtualNetworkLink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: true
  }
}

resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = {
  dependsOn: [virtualNetworkLink]
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
      privateDnsZoneResourceId: privateDNSzoneForDatabase.id
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

module databaseBackupStorageAccount './database-backup-storage-account.bicep' = {
  name: 'database-backup-storage-account'
  params: {
    location: location
    storageAccountName: databaseBackupsStorageAccountName
    storageAccountSku: databaseBackupsStorageAccountSku
    storageAccountContainerName: databaseBackupStorageAccountContainerName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    privateDnsZoneId: storageAccountPrivateDnsZoneId
  }
}
