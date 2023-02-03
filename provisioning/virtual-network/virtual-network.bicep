param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkAddressSpacePrefix string = '10.0.0.0/8'
param subnetName string = 'default'
param subnetAddressPrefix string = '10.0.0.0/23' // an address space of at least /23 is currently required for Container Apps
@description('Boolean value to specify whether the database will be included in the Virtual Network, which will add a Microsoft.Sql endpoint here')
param includeDatabaseInVirtualNetwork bool = true

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpacePrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          serviceEndpoints: (includeDatabaseInVirtualNetwork) ? [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Sql'
            }
          ] : [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}
