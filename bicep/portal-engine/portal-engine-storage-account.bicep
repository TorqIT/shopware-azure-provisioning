param location string = resourceGroup().location

param storageAccountName string
param sku string
param kind string
param accessTier string

param downloadsContainerName string

param publicBuildFileShareName string
param publicBuildFileShareAccessTier string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkContainerAppsSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource virtualNetworkSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkContainerAppsSubnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    accessTier: accessTier
    networkAcls: {
      // Container App volume mounts do not currently work with Private Endpoints, so we use a firewall instead
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: virtualNetworkSubnet.id
        }
      ]
      defaultAction: 'Deny'
      bypass: 'None'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource blobService 'blobServices' = {
    name: 'default'

    resource storageAccountContainer 'containers' = {
      name: downloadsContainerName
    }
  }

  resource fileServices 'fileServices' = {
    name: 'default'

    resource fileShare 'shares' = {
      name: publicBuildFileShareName
      properties: {
        accessTier: publicBuildFileShareAccessTier
      }
    }
  }
}
