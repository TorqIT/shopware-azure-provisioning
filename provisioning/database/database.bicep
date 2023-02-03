param location string = resourceGroup().location
param serverName string

@minLength(8)
@secure()
param administratorLoginPassword string
param administratorLogin string = 'adminuser'

@allowed([1, 2, 4, 8, 16, 32])
param skuCapacity int = 1
param skuName string = 'B_Gen5_1'
param skuSizeMB int = 51200
param skuTier string = 'Basic'
param skuFamily string = 'Gen5'

param mariadbVersion string = '10.2'

param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'

param databaseName string = 'pimcore'
param databaseCharset string = 'utf8mb4'
param databaseCollation string = 'utf8mb4_unicode_ci'

param includeInVirtualNetwork bool = true
param virtualNetworkName string = 'VNet'
param virtualNetworkSubnetName string = 'Subnet'
param virtualNetworkRuleName string = 'AllowSubnet'

var subnetId = resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)

resource mariaDbServer 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
    size: '${skuSizeMB}' // String value expected here
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: mariadbVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
  
  resource database 'databases@2018-06-01' = {
    name: databaseName
    properties: {
      charset: databaseCharset
      collation: databaseCollation
    }
  }

  resource virtualNetworkRule 'virtualNetworkRules@2018-06-01' = if (includeInVirtualNetwork) {
    name: virtualNetworkRuleName
    properties: {
      virtualNetworkSubnetId: subnetId
      ignoreMissingVnetServiceEndpoint: true
    }
  }
}
