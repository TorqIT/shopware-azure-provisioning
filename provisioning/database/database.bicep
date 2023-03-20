param location string = resourceGroup().location

param serverName string

@minLength(8)
@secure()
param administratorLoginPassword string
param administratorLogin string = 'adminuser'

param skuName string = 'Standard_B1ms'
param skuTier string = 'Burstable'
param storageSizeGB int = 20

param databaseName string = 'pimcore'

param virtualNetworkResourceGroup string = resourceGroup().name
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
  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: 'virtualNetworkLink'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: true
    }
  }
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
    administratorLoginPassword: administratorLoginPassword
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
