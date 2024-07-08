param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param cpuCores string
param memory string

param defaultEnvVars array

param containerRegistryName string
param containerRegistryConfiguration object

@secure()
param containerRegistryPasswordSecret object
@secure()
param storageAccountKeySecret object

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

var environmentVariables = concat(defaultEnvVars, [{name: 'SHOPWARE_SKIP_ASSET_COPY', value: '1'}])

resource containerAppJob 'Microsoft.App/jobs@2023-05-02-preview' = {
  location: location
  name: containerAppJobName
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      replicaTimeout: 600
      secrets: [containerRegistryPasswordSecret, storageAccountKeySecret] 
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
          command: ['/setup']
          env: environmentVariables
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
