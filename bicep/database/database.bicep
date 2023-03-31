param location string = resourceGroup().location

param serverName string

param administratorLogin string
@secure()
param administratorPassword string

param skuName string
param skuTier string
param storageSizeGB int

param databaseName string

param virtualNetworkResourceGroup string
param virtualNetworkName string
param virtualNetworkSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
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
      delegatedSubnetResourceId: subnet.id
      privateDnsZoneResourceId: privateDNSzoneForDatabase.id
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
