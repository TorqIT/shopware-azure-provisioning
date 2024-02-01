// Azure currently does not provide an easy way to perform long-term backups of a MySQL database, so we
// use a custom bundle https://github.com/TorqIT/pimcore-database-backup-bundle to store backups in a Storage Account.

param location string = resourceGroup().location

param storageAccountName string
param storageAccountSku string
param storageAccountContainerName string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubnetName string
// Since Azure only permits a single Private DNS Zone per Resource Group per resource type (in this case, Storage Accounts), we 
// re-use the Zone created for the main Storage Account
param privateDnsZoneId string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  kind: 'StorageV2'
  location: location
  name: storageAccountName
  sku: {
    name: storageAccountSku
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    accessTier: 'Cool'
  }

  resource blobService 'blobServices' = {
    name: 'default'
    resource container 'containers' = {
      name: storageAccountContainerName
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${storageAccountName}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-private-endpoint'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }

  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'privatelink-blob-core-windows-net'
          properties: {
            privateDnsZoneId: privateDnsZoneId
          }
        }
      ]
    }
  }
}
