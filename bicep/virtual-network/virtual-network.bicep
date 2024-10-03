param location string = resourceGroup().location

param virtualNetworkName string
param virtualNetworkAddressSpace string

param defaultSubnetName string
@description('Address space to allocate for the default subnet')
param defaultSubnetAddressSpace string

param containerAppsSubnetName string
@description('Address space to allocate for the Container Apps subnet. Note that a subnet of at least /23 is required, and it must occupied exclusively by the Container Apps Environment and its Apps.')
param containerAppsSubnetAddressSpace string

param databaseSubnetName string
@description('Address space to allocate for the database subnet. Note that a subnet of at least /29 is required and it must be a delegated subnet occupied exclusively by the database.')
param databaseSubnetAddressSpace string

// Optional provisioning of subnet for services VM
param provisionServicesVM bool
param servicesVmSubnetName string
@description('Address space to allocate for the services VM. Note that a subnet of at least /29 is required.')
param servicesVmSubnetAddressSpace string

// Optional provisioning of NAT Gateway for static outbound IP address
param provisionStaticOutboundIp bool
param natGatewayName string
param natGatewayPublicIpName string
param natGatewayPublicIpSku string
module natGateway './nat-gateway.bicep' = if (provisionStaticOutboundIp) {
  name: 'nat-gateway'
  params: {
    gatewayName: natGatewayName
    publicIpName: natGatewayPublicIpName
    publicIpSku: natGatewayPublicIpSku
  }
}

var defaultSubnets = [
  {
    name: defaultSubnetName
    properties: {
      addressPrefix: defaultSubnetAddressSpace
      serviceEndpoints: [
        {
          service: 'Microsoft.Storage'
        }
      ]
    }
  }
  {
    name: containerAppsSubnetName
    properties: {
      addressPrefix: containerAppsSubnetAddressSpace
      delegations: [
        {
          name: 'Microsoft.App/environments'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ]
      natGateway: (provisionStaticOutboundIp) ? {
        id: natGateway.outputs.id
      }: null
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
var servicesVmSubnet = provisionServicesVM ? [{
  name: servicesVmSubnetName
  properties: {
    addressPrefix: servicesVmSubnetAddressSpace
  }
}] : []
var subnets = concat(defaultSubnets, servicesVmSubnet)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  dependsOn: [natGateway]
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
    subnets: subnets
  }
}
