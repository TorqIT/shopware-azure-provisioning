param location string = resourceGroup().location

param storageAccountName string
param sku string
param kind string
param accessTier string
param containerName string
param assetsContainerName string
param cdnAssetAccess bool
param shortTermBackupRetentionDays int

param virtualNetworkName string
param virtualNetworkResourceGroupName string
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
    allowBlobPublicAccess: cdnAssetAccess
    publicNetworkAccess: cdnAssetAccess ? 'Enabled' : 'Disabled'
    accessTier: accessTier
    networkAcls: {
      defaultAction: cdnAssetAccess ? 'Allow' : 'Deny'
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
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: shortTermBackupRetentionDays + 1
      }
      changeFeed: {
        enabled: true
        retentionInDays: shortTermBackupRetentionDays + 1
      }
      isVersioningEnabled: true
      restorePolicy: {
        enabled: true
        days: shortTermBackupRetentionDays
      }
    }

    resource storageAccountContainer 'containers' = {
      name: containerName
    }

    resource storageAccountContainerAssets 'containers' = {
      name: assetsContainerName
      properties: {
        publicAccess: cdnAssetAccess ? 'Blob' : 'None'
      }
    }
  }
}

// We use a Private Endpoint (and Private DNS Zone) to integrate with the Virtual Network
module storageAccountPrivateEndpoint './storage-account-private-endpoint.bicep' = {
  name: 'storage-account-private-endpoint'
  params: {
    location: location
    storageAccountName: storageAccountName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkSubnetName
  }
}
output privateDnsZoneId string = storageAccountPrivateEndpoint.outputs.privateDnsZoneId

module storageAccountBackupVault './storage-account-backup-vault.bicep' = {
  name: 'storage-account-backup-vault'
  dependsOn: [storageAccount]
  params: {
    storageAccountName: storageAccountName
    containerName: containerName
    assetsContainerName: assetsContainerName
    location: location
  }
}

var storageAccountDomainName = split(storageAccount.properties.primaryEndpoints.blob, '/')[2]
resource cdn 'Microsoft.Cdn/profiles@2022-11-01-preview' = if (cdnAssetAccess) {
  location: location
  name: storageAccountName
  sku: {
    name: 'Standard_Microsoft'
  }

  resource endpoint 'endpoints' = {
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
