param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param cpuCores string
param memory string

param containerRegistryName string
param containerRegistryConfiguration object

@secure()
param containerRegistryPasswordSecret object

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

resource containerAppJob 'Microsoft.App/jobs@2023-05-02-preview' = {
  location: location
  name: containerAppJobName
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      replicaTimeout: 600
      secrets: [containerRegistryPasswordSecret] 
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
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
        }
      ]
    }
  }
}
