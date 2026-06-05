param location string = resourceGroup().location

param fullProvision bool

param serverName string
param serverVersion string

param administratorLogin string
@secure()
param administratorPassword string

param skuName string
param skuTier string
param storageSizeGB int

param shortTermBackupRetentionDays int
param geoRedundantBackup bool

param databaseName string

param longTermBackups bool
// param backupVaultName string
// param longTermBackupRetentionPeriod string
param databaseBackupsStorageAccountName string
param databaseBackupsStorageAccountSku string
param databaseBackupsStorageAccountKind string
param databaseBackupsStorageAccountContainerName string

param virtualNetworkResourceGroupName string
param virtualNetworkName string
param virtualNetworkPrivateEndpointsSubnetName string
param privateEndpointName string
param privateDnsZoneForDatabaseId string

// Optional metric alerts provisioning
param provisionMetricAlerts bool
param generalMetricAlertsActionGroupName string
param criticalMetricAlertsActionGroupName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}
resource privateEndpointsSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkPrivateEndpointsSubnetName
}

resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: serverVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    network: {
      publicNetworkAccess: 'Enabled'
      privateDnsZoneResourceId: privateDnsZoneForDatabaseId
    }
    backup: {
      backupRetentionDays: shortTermBackupRetentionDays
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

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointsSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: databaseServer.id
          groupIds: [
            'mysqlserver'
          ]
        }
      }
    ]
  }

  resource dnsGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'default'
          properties: {
            privateDnsZoneId: privateDnsZoneForDatabaseId
          }
        }
      ]
    }
  }
}

// Per https://learn.microsoft.com/en-us/azure/backup/backup-azure-mysql-flexible-server, support long-term backups of MySQL servers are currently paused.
// module databaseBackupVault 'database-backup-vault.bicep' = if (longTermBackups) {
//   name: 'database-backup-vault'
//   dependsOn: [databaseServer]
//   params: {
//     backupVaultName: backupVaultName
//     databaseServerName: serverName
//     retentionPeriod: longTermBackupRetentionPeriod
//   }
// }

module databaseBackupsStorageAccount './database-backups-storage-account.bicep' = if (fullProvision && longTermBackups) {
  name: 'database-backups-storage-account'
  params: {
    storageAccountName: databaseBackupsStorageAccountName
    sku: databaseBackupsStorageAccountSku
    kind: databaseBackupsStorageAccountKind
    containerName: databaseBackupsStorageAccountContainerName
  }
}

module cpuUsageAlert './alerts/database-cpu-alerts.bicep' = if (provisionMetricAlerts) {
  name: 'database-cpu-usage-alerts'
  dependsOn: [databaseServer]
  params: {
    databaseServerName: serverName
    generalActionGroupName: generalMetricAlertsActionGroupName
    criticalActionGroupName: criticalMetricAlertsActionGroupName
  }
}
