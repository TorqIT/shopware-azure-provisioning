param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkAddressSpace string

param containerAppsSubnetName string
@description('Address space to allocate for the Container Apps subnet. Note that a subnet of at least /23 is required, and it must occupied exclusively by the Container Apps Environment and its Apps.')
param containerAppsSubnetAddressSpace string

param databaseSubnetName string
@description('Address space to allocate for the database subnet. Note that a subnet of at least /29 is required and it must be a delegated subnet occupied exclusively by the database.')
param databaseSubnetAddressSpace string

param provisionN8N bool
param n8nDatabaseSubnetName string
@description('Address space to allocate for the n8n Postgres database subnet. Note that a subnet of at least /28 is required and it must be a delegated subnet occupied exclusively by the database.')
param n8nDatabaseSubnetAddressSpace string

param provisionServicesVM bool
param servicesVmSubnetName string
@description('Address space to allocate for the services VM. Note that a subnet of at least /29 is required.')
param servicesVmSubnetAddressSpace string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
    subnets: [
      {
        name: containerAppsSubnetName
        properties: {
          addressPrefix: containerAppsSubnetAddressSpace
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: databaseSubnetName
        properties: {
          addressPrefix: databaseSubnetAddressSpace
          delegations: [
            {
              name: 'Microsoft.DBforMySQL/flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
        }
      }
      
    ]
  }

  // We deploy these subnets as resources instead of as part of the properties above,
  // as there is no way to deploy conditionally using the above pattern
  resource n8nSubnet 'subnets' = if (provisionN8N) {
    name: servicesVmSubnetName
    properties: {
      addressPrefix: servicesVmSubnetAddressSpace
    }
  }
  resource servicesVmSubnet 'subnets' = if (provisionServicesVM) {
    name: servicesVmSubnetName
    properties: {
      addressPrefix: servicesVmSubnetAddressSpace
    }
  }
}
