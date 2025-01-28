param location string = resourceGroup().location

param storageAccountName string
param sku string
param kind string
param containerName string

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
    accessTier: 'Cool'
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      // Backup operation will temporarily add its IP to the firewall, then immediately remove it
      ipRules: []
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
      name: containerName
    }
  }
}
