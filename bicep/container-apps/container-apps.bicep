param location string = resourceGroup().location

param containerAppsEnvironmentName string
param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param containerRegistryName string

param storageAccountName string
param storageAccountPublicContainerName string
param storageAccountPrivateContainerName string

param shopwareInitContainerAppJobName string
param shopwareInitImageName string
param shopwareInitContainerAppJobCpuCores string
param shopwareInitContainerAppJobMemory string

param shopwareWebContainerAppExternal bool
param shopwareWebContainerAppCustomDomains array
param shopwareWebContainerAppName string
param shopwareWebImageName string
param shopwareWebContainerAppCpuCores string
param shopwareWebContainerAppMemory string
param shopwareWebContainerAppMinReplicas int
param shopwareWebContainerAppMaxReplicas int

param additionalEnvVars array

module containerAppsEnvironment 'environment/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    location: location
    name: containerAppsEnvironmentName
    shopwareWebContainerAppExternal: shopwareWebContainerAppExternal
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Secrets
var storageAccountKeySecretName = 'storage-account-key'
var storageAccountKeySecret = {
  name: storageAccountKeySecretName
  value: storageAccount.listKeys().keys[0].value  
}

module environmentVariables 'container-apps-variables.bicep' = {
  name: 'environment-variables'
  params: {
    storageAccountName: storageAccountName
    storageAccountPublicContainerName: storageAccountPublicContainerName
    storageAccountPrivateContainerName: storageAccountPrivateContainerName
    storageAccountKeySecretName: storageAccountKeySecretName
    additionalVars: additionalEnvVars
  }
}

var containerRegistryPasswordSecretName = 'container-registry-password'
var containerRegistryPasswordSecret = {
  name: containerRegistryPasswordSecretName
  value: containerRegistry.listCredentials().passwords[0].value
}
var containerRegistryConfiguration = {
  server: '${containerRegistryName}.azurecr.io'
  username: containerRegistry.listCredentials().username
  passwordSecretRef: containerRegistryPasswordSecretName
}

module shopwareInitContainerAppJob 'container-app-job-shopware-init.bicep' = {
  name: 'shopware-init-container-app-job'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppJobName: shopwareInitContainerAppJobName
    imageName: shopwareInitImageName
    cpuCores: shopwareInitContainerAppJobCpuCores
    memory: shopwareInitContainerAppJobMemory
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
    defaultEnvVars: environmentVariables.outputs.envVars
  }
}

module shopwareWebContainerApp 'container-app-shopware-web.bicep' = {
  name: 'shopware-web-container-app'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: shopwareWebContainerAppName
    imageName: shopwareWebImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: shopwareWebContainerAppCpuCores
    memory: shopwareWebContainerAppMemory
    minReplicas: shopwareWebContainerAppMinReplicas
    maxReplicas: shopwareWebContainerAppMaxReplicas
    customDomains: shopwareWebContainerAppCustomDomains
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
  }
}
