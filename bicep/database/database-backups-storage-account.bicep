param location string = resourceGroup().location

param storageAccountName string
param sku string
param kind string
param containerName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  //checkov:skip=CKV_AZURE_43: storage account name is parameterized and validated by the calling template
  //checkov:skip=CKV_AZURE_59: publicNetworkAccess must be Enabled so the backup script can temporarily add its IP to the firewall
  //checkov:skip=CKV_AZURE_206: replication SKU is parameterized; LRS is acceptable for backup storage
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
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      // Backup operation will temporarily add its IP to the firewall, then immediately remove it
      ipRules: []
      defaultAction: 'Deny'
      bypass: 'AzureServices'
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
