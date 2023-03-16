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

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: publicAssetAccess
    publicNetworkAccess: publicAssetAccess ? 'Enabled' : null
    networkAcls: {
      virtualNetworkRules: [
        {
          id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)
          action: 'Allow'
        }
      ]
      defaultAction: publicAssetAccess ? 'Allow' : 'Deny'
      bypass: 'None'
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

var storageAccountDomainName = split(storageAccount.properties.primaryEndpoints.blob, '/')[2]
resource cdn 'Microsoft.Cdn/profiles@2022-11-01-preview' = if (publicAssetAccess) {
  location: location
  name: storageAccountName
  sku: {
    name: 'Standard_Microsoft'
  }

  resource endpoint 'endpoints@2022-11-01-preview' = {
    location: location
    name: storageAccountName
    properties: {
      originHostHeader: storageAccountDomainName
      isHttpAllowed: false
      origins: [
        {
          name: storageAccount.name
          properties: {
            hostName: storageAccountDomainName
          } 
        }
      ]
    }
  }
}
