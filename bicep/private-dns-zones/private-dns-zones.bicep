param privateDnsZonesSubscriptionId string
param privateDnsZonesResourceGroupName string
param privateDnsZoneForDatabaseName string
param privateDnsZoneForStorageAccountsName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

resource privateDNSzoneForDatabaseNew 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
  name: privateDnsZoneForDatabaseName
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
    name: 'virtualNetworkLink'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }
}
resource privateDnsZoneForDatabaseExisting 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (privateDnsZonesResourceGroupName != resourceGroup().name) {
  name: privateDnsZoneForDatabaseName
  scope: resourceGroup(privateDnsZonesSubscriptionId, privateDnsZonesResourceGroupName)
}
output zoneIdForDatabase string = ((privateDnsZonesResourceGroupName == resourceGroup().name) ? privateDNSzoneForDatabaseNew.id : privateDnsZoneForDatabaseExisting.id)

resource privateDnsZoneForStorageAccountsNew 'Microsoft.Network/privateDnsZones@2020-06-01' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
  name: privateDnsZoneForStorageAccountsName
  location: 'global'

  resource vnetLink 'virtualNetworkLinks' = if (privateDnsZonesResourceGroupName == resourceGroup().name) {
    name: 'vnet-link'
    location: 'global' 
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}
resource privateDnsZoneForStorageAccountsExisting 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (privateDnsZonesResourceGroupName != resourceGroup().name) {
  name: privateDnsZoneForStorageAccountsName
  scope: resourceGroup(privateDnsZonesSubscriptionId, privateDnsZonesResourceGroupName)
}
output zoneIdForStorageAccounts string = ((privateDnsZonesResourceGroupName == resourceGroup().name) ? privateDnsZoneForStorageAccountsNew.id : privateDnsZoneForStorageAccountsExisting.id)
