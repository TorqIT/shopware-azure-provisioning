param location string = resourceGroup().location

param containerAppsEnvironmentName string
param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param databaseServerName string

param containerRegistryName string

// param storageAccountName string
// param storageAccountContainerName string
// param storageAccountAssetsContainerName string

param initContainerAppJobName string
param initContainerAppJobCpuCores string
param initContainerAppJobMemory string

param shopwareContainerAppExternal bool
param shopwareContainerAppCustomDomains array
param shopwareContainerAppName string
param shopwareImageName string
param shopwareContainerAppCpuCores string
param shopwareContainerAppMemory string
param shopwareContainerAppMinReplicas int
param shopwareContainerAppMaxReplicas int

param appDebug string
param appEnv string
param databaseName string
param databaseUser string
param additionalEnvVars array
@secure()
param databasePassword string

module containerAppsEnvironment 'environment/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    location: location
    name: containerAppsEnvironmentName
    shopwareContainerAppExternal: shopwareContainerAppExternal
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}
// resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
//   name: storageAccountName
// }
resource database 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' existing = {
  name: databaseServerName
}

var containerRegistryPasswordSecret = {
  name: 'container-registry-password'
  value: containerRegistry.listCredentials().passwords[0].value
}
// var storageAccountKeySecret = {
//   name: 'storage-account-key'
//   value: storageAccount.listKeys().keys[0].value  
// }
var databasePasswordSecretName = 'database-password'
var databaseUrlSecretName = 'database-url'
var databasePasswordSecret = {
  name: databasePasswordSecretName
  value: databasePassword
}
var databaseUrlSecret = {
  name: databaseUrlSecretName
  value: 'mysql://${databaseUser}:${databasePassword}@${database.properties.fullyQualifiedDomainName}:3306/${databaseName}'
}

module environmentVariables 'container-apps-variables.bicep' = {
  name: 'environment-variables'
  params: {
    appDebug: appDebug
    appEnv: appEnv
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    databasePasswordSecretName: databasePasswordSecretName
    databaseUrlSecretName: databaseUrlSecretName
    additionalVars: additionalEnvVars
  }
}

var containerRegistryConfiguration = {
  server: '${containerRegistryName}.azurecr.io'
  username: containerRegistry.listCredentials().username
  passwordSecretRef: 'container-registry-password'
}

module initContainerAppJob 'container-app-job-init.bicep' = {
  name: 'init-container-app-job'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppJobName: initContainerAppJobName
    imageName: shopwareImageName
    cpuCores: initContainerAppJobCpuCores
    memory: initContainerAppJobMemory
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    // storageAccountKeySecret: storageAccountKeySecret
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    databaseUrlSecret: databaseUrlSecret
    defaultEnvVars: environmentVariables.outputs.envVars
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
  }
}

module shopwareContainerApp 'container-apps-shopware.bicep' = {
  name: 'shopware-container-app'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: shopwareContainerAppName
    imageName: shopwareImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: shopwareContainerAppCpuCores
    memory: shopwareContainerAppMemory
    minReplicas: shopwareContainerAppMinReplicas
    maxReplicas: shopwareContainerAppMaxReplicas
    customDomains: shopwareContainerAppCustomDomains
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    // storageAccountKeySecret: storageAccountKeySecret
  }
}
