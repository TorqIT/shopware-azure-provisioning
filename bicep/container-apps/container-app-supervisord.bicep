param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param cpuCores string
param memory string
param managedIdentityId string

@secure()
param databasePasswordSecret object
@secure()
param storageAccountKeySecret object
param additionalSecrets array
param additionalVolumesAndMounts array

// Optional Portal Engine provisioning
param provisionForPortalEngine bool
@secure()
param portalEngineStorageAccountKeySecret object

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

var defaultSecrets = [databasePasswordSecret, storageAccountKeySecret]
var portalEngineSecrets = provisionForPortalEngine ? [portalEngineStorageAccountKeySecret] : []
var secrets = concat(defaultSecrets, portalEngineSecrets, additionalSecrets)

module volumesModule './container-apps-volumes.bicep' = {
  name: 'container-app-supervisord-volumes'
  params: {
    provisionForPortalEngine: false // deliberately don't create a volume mount for Portal Engine build as it is not required for supervisord
    portalEnginePublicBuildStorageMountName: '' 
    additionalVolumesAndMounts: additionalVolumesAndMounts
  }
}

resource supervisordContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: secrets
      registries: [
        {
          identity: managedIdentityId
          server: '${containerRegistryName}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          name: imageName
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          env: environmentVariables
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          volumeMounts: volumesModule.outputs.volumeMounts
        }
      ]
      volumes: volumesModule.outputs.volumes
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
