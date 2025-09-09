param location string = resourceGroup().location

param fullProvision bool

param storageAccountName string
param sku string
param kind string
param accessTier string
param containerName string
param assetsContainerName string
param fileShares array

param firewallIps array
param cdnAssetAccess bool

param shortTermBackupRetentionDays int

param privateDnsZoneId string
param privateEndpointName string
param privateEndpointNicName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkPrivateEndpointSubnetName string
param virtualNetworkContainerAppsSubnetName string

param longTermBackups bool
param backupVaultName string
param longTermBackupRetentionPeriod string

param provisionFrontDoorCdn bool
param frontDoorCdnProfileName string
param frontDoorCdnEndpointName string
param frontDoorIpRules array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource virtualNetworkContainerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: virtualNetwork
  name: virtualNetworkContainerAppsSubnetName
}

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
    accessTier: accessTier
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      ipRules: [for ip in firewallIps: {value: ip}]
      virtualNetworkRules: [
        {
          // We whitelist the Container Apps subnet in addition to creating a Private Endpoint below.
          // The Private Endpoint allows the Container App to access the Storage Account via DNS (e.g. using Flysystem),
          // while the whitelist approach allows for the Container App to mount File Shares as volumes (which as of writing
          // does not support Private Endpoints)
          id: virtualNetworkContainerAppsSubnet.id
          action: 'Allow'
        }
      ]
      // If using a Front Door - there is currently no clean way to only singularly allow Front Door to access a Storage Account
      // (without upgrading to the expensive Premium tier), so we must open the Storage Account publicly. Anonymous access to 
      // blobs is still denied, and access by the Front Door is done via SAS token generated below
      defaultAction: provisionFrontDoorCdn ? 'Allow' : 'Deny'
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

  resource blobServices 'blobServices' = {
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
      properties: {
        publicAccess: 'None'
      }
    }

    resource storageAccountContainerAssets 'containers' = {
      name: assetsContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }

  resource fileServices 'fileServices' = {
    name: 'default'
      resource fileShare 'shares' = [for fileShare in fileShares: {
        name: fileShare.name
      }
    ]
  }
}

// We use a Private Endpoint (and Private DNS Zone) to integrate with the Virtual Network
module storageAccountPrivateEndpoint './storage-account-private-endpoint.bicep' = {
  name: 'storage-account-private-endpoint'
  dependsOn: [storageAccount]
  params: {
    location: location
    storageAccountName: storageAccountName
    privateDnsZoneId: privateDnsZoneId
    privateEndpointName: privateEndpointName
    privateEndpointNicName: privateEndpointNicName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkPrivateEndpointSubnetName
  }
}

module storageAccountBackupVault './storage-account-backup-vault.bicep' = if (fullProvision && longTermBackups) {
  name: 'storage-account-backup-vault'
  dependsOn: [storageAccount]
  params: {
    location: location
    backupVaultName: backupVaultName
    storageAccountName: storageAccountName
    containerName: containerName
    assetsContainerName: assetsContainerName
    retentionPeriod: longTermBackupRetentionPeriod
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

module frontDoorCdn './storage-account-front-door-cdn.bicep' = if (provisionFrontDoorCdn) {
  name: 'storage-account-front-door-cdn'
  params: {
    frontDoorProfileName: frontDoorCdnProfileName
    endpointName: frontDoorCdnEndpointName
    storageAccountName: storageAccountName
    storageAccountAssetsContainerName: assetsContainerName
    ipRules: frontDoorIpRules
  }
}
