param location string = resourceGroup().location

param fullProvision bool

param storageAccountName string
param sku string
param kind string
param accessTier string
param publicContainerName string
param privateContainerName string
param firewallIps array

param shortTermBackupRetentionDays int

param privateDnsZoneId string
param privateEndpointName string
param privateEndpointNicName string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkPrivateEndpointSubnetName string

param longTermBackups bool
param backupVaultName string
param longTermBackupRetentionPeriod string

param provisionFrontDoorCdn bool
param frontDoorSku string
param frontDoorProfileName string
param frontDoorEndpointName string
param frontDoorCustomDomains array

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
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
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

    resource privateContainer 'containers' = {
      name: privateContainerName
      properties: {
        publicAccess: 'None'
      }
    }

    resource publicContainer 'containers' = {
      name: publicContainerName
      properties: {
        publicAccess: 'Blob'
      }
    }
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
    containers: [publicContainerName, privateContainerName]
    retentionPeriod: longTermBackupRetentionPeriod
  }
}

module frontDoorCdn './front-door-cdn.bicep' = if (fullProvision && provisionFrontDoorCdn) {
  name: 'front-door-cdn'
  params: {
    location: location
    profileName: frontDoorProfileName
    endpointName: frontDoorEndpointName
    storageAccountName: storageAccountName
    publicContainerName: publicContainerName
    customDomains: frontDoorCustomDomains
    sku: frontDoorSku
  }
}
