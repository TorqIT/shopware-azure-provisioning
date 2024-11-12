param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkAddressSpace string

param containerAppsSubnetName string
@description('Address space to allocate for the Container Apps subnet. Note that a subnet of at least /23 is required, and it must occupied exclusively by the Container Apps Environment and its Apps.')
param containerAppsSubnetAddressSpace string
param containerAppsEnvironmentUseWorkloadProfiles bool

param databaseSubnetName string
@description('Address space to allocate for the database subnet. Note that a subnet of at least /29 is required and it must be a delegated subnet occupied exclusively by the database.')
param databaseSubnetAddressSpace string

param privateEndpointsSubnetName string
@description('Address space to allocate for Private Endpoints')
param privateEndpointsSubnetAddressSpace string

param provisionN8N bool
param n8nDatabaseSubnetName string
@description('Address space to allocate for the n8n Postgres database subnet. Note that a subnet of at least /28 is required and it must be a delegated subnet occupied exclusively by the database.')
param n8nDatabaseSubnetAddressSpace string

param provisionServicesVM bool
param servicesVmSubnetName string
@description('Address space to allocate for the services VM. Note that a subnet of at least /29 is required.')
param servicesVmSubnetAddressSpace string

var defaultSubnets = [
  {
    name: containerAppsSubnetName
    properties: {
      addressPrefix: containerAppsSubnetAddressSpace
      // When using workload profiles with Container Apps requires the subnet to be delegated to Microsoft.App/environments;
      // for some reason, using a Consumption-only plan does not work with this setup
      delegations: containerAppsEnvironmentUseWorkloadProfiles ? [
        {
          name: 'Microsoft.App/environments'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ] : []
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
// TODO this is a leftover of placing Private Endpoints improperly into the Container Apps subnet. This is to accommodate legacy apps
// that use this setup, but all new applications should provision a separate subnet for Private Endpoints.
var privateEndpointsSubnet = (privateEndpointsSubnetName != containerAppsSubnetName) ? [{
  name: privateEndpointsSubnetName
  properties: {
    addressPrefix: privateEndpointsSubnetAddressSpace
  }
}]: []
var n8nPostgresSubnet = provisionN8N ? [{
  name: n8nDatabaseSubnetName
  properties: {
    addressPrefix: n8nDatabaseSubnetAddressSpace
    delegations: [
      {
        name: 'Microsoft.DBforPostgreSQL/flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
}] : []
var servicesVmSubnet = provisionServicesVM ? [{
  name: servicesVmSubnetName
  properties: {
    addressPrefix: servicesVmSubnetAddressSpace
  }
}] : []
var subnets = concat(defaultSubnets, privateEndpointsSubnet, n8nPostgresSubnet, servicesVmSubnet)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
    subnets: subnets
  }
}
