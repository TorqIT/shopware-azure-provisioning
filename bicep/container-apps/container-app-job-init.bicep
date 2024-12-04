param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppJobName string
param imageName string
param cpuCores string
param memory string
param replicaTimeoutSeconds int

param keyVaultName string

param containerRegistryName string
param containerRegistryConfiguration object
@secure()
param containerRegistryPasswordSecret object
param managedIdentityForKeyVaultId string

@secure()
param databaseUrlSecret object
@secure()
param storageAccountKeySecret object
@secure()
param appSecretSecret object
@secure()
param appPassword string
param additionalSecrets array

param environmentVariables array

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: containerAppsEnvironmentName
  scope: resourceGroup()
}
var containerAppsEnvironmentId = containerAppsEnvironment.id

// Secrets
var appPasswordSecretRefName = 'app-password'
var appPasswordSecret = {
  name: appPasswordSecretRefName
  value: appPassword
}
var appPasswordEnvVar = {
  name: 'APP_PASSWORD'
  secretRef: appPasswordSecretRefName
}
var defaultSecrets = [containerRegistryPasswordSecret, databaseUrlSecret, storageAccountKeySecret, appSecretSecret, appPasswordSecret]
var secrets = concat(defaultSecrets, additionalSecrets)

module volumesModule './container-apps-volumes.bicep' = {
  name: 'container-app-php-volumes'
}

resource containerAppJob 'Microsoft.App/jobs@2024-03-01' = {
  location: location
  name: containerAppJobName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityForKeyVaultId}': {}
    }
  }
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
          env: concat(environmentVariables, [appPasswordEnvVar])
          resources: {
            cpu: json(cpuCores)
            memory: memory
          }
          volumeMounts: volumesModule.outputs.volumeMounts
        }
      ]
      volumes: volumesModule.outputs.volumes
    }
  }
}
