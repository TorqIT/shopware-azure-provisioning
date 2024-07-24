param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkDatabaseSubnetName string

param databaseServerName string
param databaseAdminUser string
@secure()
param databaseAdminPassword string
param databaseSkuName string
param databaseSkuTier string
param databaseStorageSizeGB int
param databaseBackupRetentionDays int
param databaseName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

resource databaseSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkDatabaseSubnetName
}

resource privateDNSzoneForDatabase 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${databaseServerName}.private.postgres.database.azure.com'
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'vnet-link'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }

}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: databaseServerName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    version: '14'
    administratorLogin: databaseAdminUser
    administratorLoginPassword: databaseAdminPassword
    network: {
      delegatedSubnetResourceId: databaseSubnet.id
      privateDnsZoneArmResourceId: privateDNSzoneForDatabase.id
    }
    storage: {
      storageSizeGB: databaseStorageSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }

  resource database 'databases' = {
    name: databaseName
  }

  resource serverParameters 'configurations' = {
    name: 'require_secure_transport'
    properties: {
      source: 'user-override'
      value: 'OFF'
    }
  }
}
