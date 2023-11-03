param location string = resourceGroup().location

param name string
param phpFpmContainerAppExternal bool

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}
var subnetId = subnet.id

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-02-preview' = {
  name: name
  location: location
  properties: {
    vnetConfiguration: {
      internal: !phpFpmContainerAppExternal
      infrastructureSubnetId: subnetId
    }
  }
}

// If the app is to be internal within the VNet, a private DNS zone needs to be configured
// that will point the domain to the static IP of the Container Apps Environment. Note that a 
// module is necessary here as Bicep will complain about the Environment needing to be fully deployed
// before its properties can be used for the zone's name. For some reason, a separate module eliminates
// that error.
module privateDns 'container-apps-environment-private-dns-zone.bicep' = if (!phpFpmContainerAppExternal) {
  name: 'private-dns-zone'
  params: {
    name: containerAppsEnvironment.properties.defaultDomain
    staticIp: containerAppsEnvironment.properties.staticIp
    vnetId: virtualNetwork.id
  }
}

output id string = containerAppsEnvironment.id
