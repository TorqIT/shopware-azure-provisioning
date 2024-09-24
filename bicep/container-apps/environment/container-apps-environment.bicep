param location string = resourceGroup().location

param name string
param phpContainerAppExternal bool

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param logAnalyticsWorkspaceName string

param provisionForPortalEngine bool
param portalEngineStorageAccountName string
param portalEngineStorageAccountPublicFileShareName string
param portalEnginePublicStorageMountName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}
var subnetId = subnet.id

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  properties: {
    vnetConfiguration: {
      internal: !phpContainerAppExternal
      infrastructureSubnetId: subnetId
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// If the app is to be internal within the VNet, a private DNS zone needs to be configured
// that will point the domain to the static IP of the Container Apps Environment. Note that a 
// module is necessary here as Bicep will complain about the Environment needing to be fully deployed
// before its properties can be used for the zone's name. For some reason, a separate module eliminates
// that error.
module privateDns 'container-apps-environment-private-dns-zone.bicep' = if (!phpContainerAppExternal) {
  name: 'private-dns-zone'
  params: {
    name: containerAppsEnvironment.properties.defaultDomain
    staticIp: containerAppsEnvironment.properties.staticIp
    vnetId: virtualNetwork.id
  }
}

resource portalEngineStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (provisionForPortalEngine) {
  name: portalEngineStorageAccountName
}
resource portalEngineStorageMount 'Microsoft.App/managedEnvironments/storages@2024-03-01' = if (provisionForPortalEngine) {
  parent: containerAppsEnvironment
  name: portalEnginePublicStorageMountName
  properties: {
    azureFile: {
      accountName: portalEngineStorageAccountName
      accountKey: portalEngineStorageAccount.listKeys().keys[0].value
      shareName: portalEngineStorageAccountPublicFileShareName
      accessMode: 'ReadWrite'
    }
  }
}
