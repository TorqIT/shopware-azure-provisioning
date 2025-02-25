param location string = resourceGroup().location

param storageAccountName string
param storageAccountSku string
param fileShares array

param virtualNetworkName string
param virtualNetworkResourceGroupName string
@description('The VNet subnet that requires access to this Storage Account')
param virtualNetworkSubnetName string

// TODO short-term and long-term backups

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkSubnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'FileStorage'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: false // as NFS is unencrypted, this must be set to false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      virtualNetworkRules: [
        {
          id: subnet.id
        }
      ]
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource fileServices 'fileServices' = {
    name: 'default'

    resource fileShare 'shares' = [for fileShare in fileShares: {
      name: fileShare.name
      properties: {
        enabledProtocols: 'NFS'
        shareQuota: fileShare.?maxSizeGB ?? 100
      }
    }]
  }
}
