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
param javaOpts string
param autoCreateIndex bool

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

resource opensearchContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
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
        targetPort: 9200
      }
    }
    template: {
      containers: [
        {
          name: 'opensearch'
          image: 'opensearchproject/opensearch:2.19.6'
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          env: [
            {
              name: 'discovery.type'
              value: 'single-node'
            }
            {
              name: 'node.name'
              value: 'opensearch'
            }
            {
              name: 'DISABLE_SECURITY_PLUGIN'
              value: 'true'
            }
            {
              name: 'OPENSEARCH_JAVA_OPTS'
              value: javaOpts
            }
            {
              name: 'cluster.routing.allocation.disk.threshold_enabled'
              value: 'false'
            }
            {
              name: 'action.auto_create_index'
              value: '${autoCreateIndex}'
            }
          ]
          volumeMounts: [
            {
              mountPath: '/usr/share/opensearch/data'
              volumeName: volumeName
            }
          ]
        }
      ]
      volumes: [
        {
          name: volumeName
          storageName: containerAppsEnvironmentStorageMountName
          storageType: 'AzureFile'
          mountOptions: 'uid=1000,gid=1000,nobrl' // nobrl is very important to prevent file locking between replicas/revisions
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}
