param storageAccountName string
param location string = resourceGroup().location
param sku string = 'Standard_LRS'
param kind string = 'StorageV2'
param accessTier string = 'Cool'
param containerName string
param assetsContainerName string
param publicAssetAccess bool = false
param virtualNetworkName string
param virtualNetworkSubnetName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)
          action: 'Allow'
        }
      ]
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
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
    accessTier: accessTier
  }
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/${containerName}'
}

resource storageAccountContainerAssets 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/${assetsContainerName}'
  properties: {
    publicAccess: publicAssetAccess ? 'Blob' : 'None'
  }
}
