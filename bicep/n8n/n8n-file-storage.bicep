param location string = resourceGroup().location

param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param storageAccountAccessTier string
param storageAccountFileShareName string
param storageAccountFileShareAccessTier string

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
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    accessTier: storageAccountAccessTier
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

  resource fileServices 'fileServices' = {
    name: 'default'

    resource fileShare 'shares' = {
      name: storageAccountFileShareName
      properties: {
        accessTier: storageAccountFileShareAccessTier
      }
    }
  }
}
