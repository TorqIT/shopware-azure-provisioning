param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param cpuCores string
param memory string
param replicaTimeoutSeconds int

param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param containerRegistryPasswordSecret object
@secure()
param databaseUrlSecret object
@secure()
param storageAccountKeySecret object
@secure()
param appSecretSecret object

param environmentVariables array

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

var secrets = [containerRegistryPasswordSecret, databaseUrlSecret, storageAccountKeySecret, appSecretSecret]

resource containerAppJob 'Microsoft.App/jobs@2024-03-01' = {
  location: location
  name: containerAppJobName
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      replicaTimeout: replicaTimeoutSeconds
      secrets: secrets
      triggerType: 'Manual'
      eventTriggerConfig: {
        scale: {
          minExecutions: 0
          maxExecutions: 1
        }
      }
      registries: [
        containerRegistryConfiguration
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/${imageName}:latest'
          name: imageName
          env: environmentVariables
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
        }
      ]
    }
  }
}
