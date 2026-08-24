param location string = resourceGroup().location

param storageAccountName string
@secure()
param storageAccountKey string
param storageAccountFileShareName string

param keyVaultName string
param managedIdentityForKeyVaultId string

param containerAppsEnvironmentName string
param containerAppsEnvironmentStorageMountName string
param volumeName string

param containerAppName string
param cpuCores string
param memory string
param minReplicas int
param maxReplicas int

param mercureJwtSecretNameInKeyVault string

// Storage Account File Share
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}
resource storageAccountFileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  parent: storageAccount
  name: 'default'
}
resource storageAccountFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: storageAccountFileService
  name: storageAccountFileShareName
}

// Container App Environment storage mount
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-11-02-preview' existing = {
  name: containerAppsEnvironmentName
}
resource storageMount 'Microsoft.App/managedEnvironments/storages@2023-11-02-preview' = {
  parent: containerAppsEnvironment
  name: containerAppsEnvironmentStorageMountName
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: storageAccountFileShareName
      accessMode: 'ReadWrite'
    }
  }
}

// Secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource mercureJwtSecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2025-05-01' existing = {
  parent: keyVault
  name: mercureJwtSecretNameInKeyVault
}
var mercureJwtSecretRefName = 'mercure-jwt-key'
var mercureJwtSecret = {
  name: mercureJwtSecretRefName
  keyVaultUrl: mercureJwtSecretInKeyVault.?properties.secretUri
  identity: managedIdentityForKeyVaultId
}

// Environment variables
var envVars = [
  {
    name: 'MERCURE_PUBLISHER_JWT_KEY'
    secretRef: mercureJwtSecretRefName
  }
  {
    name: 'MERCURE_SUBSCRIBER_JWT_KEY'
    secretRef: mercureJwtSecretRefName
  }
]

resource mercureContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  dependsOn: [storageMount]
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityForKeyVaultId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        allowInsecure: false
        targetPort: 80
      }
      secrets: [mercureJwtSecret]
    }
    template: {
      containers: [
        {
          name: 'mercure'
          image: 'dunglas/mercure:v0.24.2@sha256:916834e499613d475e9ad5118cd2349875338f52d99d65b58aeff82f97ccb0c6'
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          env: envVars
          volumeMounts: [
            {
              mountPath: '/data'
              volumeName: volumeName
              subPath: 'data'
            }
            {
              mountPath: '/config'
              volumeName: volumeName
              subPath: 'config'
            }
          ]
        }
      ]
      volumes: [
        {
          name: volumeName
          storageName: containerAppsEnvironmentStorageMountName
          storageType: 'AzureFile'
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}
