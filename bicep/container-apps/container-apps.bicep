param location string = resourceGroup().location

param containerAppsEnvironmentName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param databaseServerName string

param containerRegistryName string

param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string

param phpFpmContainerAppExternal bool
param phpFpmContainerAppCustomDomain string
param phpFpmContainerAppCertificateName string
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool

param supervisordContainerAppName string
param supervisordImageName string

param redisContainerAppName string
param redisImageName string

param appDebug string
param appEnv string
param databaseName string
param databaseUser string
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisSessionDb string
param additionalEnvVars array
@secure()
param databasePassword string

module containerAppsEnvironment 'environment/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    location: location
    name: containerAppsEnvironmentName
    phpFpmContainerAppExternal: phpFpmContainerAppExternal
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Set up common secrets for the PHP-FPM and supervisord Container Apps
var containerRegistryPasswordSecret = {
  name: 'container-registry-password'
  value: containerRegistry.listCredentials().passwords[0].value
}
var storageAccountKeySecret = {
  name: 'storage-account-key'
  value: storageAccount.listKeys().keys[0].value  
}
var databasePasswordSecret = {
  name: 'database-password'
  value: databasePassword
}

// Set up common environment variables for the Container Apps
module environmentVariables 'container-apps-variables.bicep' = {
  name: 'environment-variables'
  params: {
    appDebug: appDebug
    appEnv: appEnv
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisHost: redisContainerAppName
    redisDb: redisDb
    redisSessionDb: redisSessionDb
    storageAccountName: storageAccountName
    storageAccountContainerName: storageAccountContainerName
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    additionalVars: additionalEnvVars
  }
}

var containerRegistryConfiguration = {
  server: '${containerRegistryName}.azurecr.io'
  username: containerRegistry.listCredentials().username
  passwordSecretRef: 'container-registry-password'
}

module phpFpmContainerApp 'container-apps-php-fpm.bicep' = {
  name: 'php-fpm-container-app'
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: phpFpmContainerAppName
    imageName: phpFpmImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    useProbes: phpFpmContainerAppUseProbes
    customDomain: phpFpmContainerAppCustomDomain
    certificateName: phpFpmContainerAppCertificateName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
  }
}

module supervisordContainerApp 'container-apps-supervisord.bicep' = {
  name: 'supervisord-container-app'
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerAppName: supervisordContainerAppName
    imageName: supervisordImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
  }
}

module redisContainerApp 'container-apps-redis.bicep' = {
  name: 'redis-container-app'
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerAppName: redisContainerAppName
    imageName: redisImageName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
  }
}

