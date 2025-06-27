param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppName string
param imageName string
param environmentVariables array
param containerRegistryName string
param cpuCores string
param memory string
param managedIdentityId string
param additionalVolumesAndMounts array

@secure()
param databaseUrlSecret object
@secure()
param storageAccountKeySecret object
@secure()
param appSecretSecret object
param additionalSecrets array

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

var defaultSecrets = [databaseUrlSecret, storageAccountKeySecret, appSecretSecret]
var secrets = concat(defaultSecrets, additionalSecrets)

module volumesModule './container-apps-volumes.bicep' = {
  name: 'container-app-supervisord-volumes'
  params: {
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
