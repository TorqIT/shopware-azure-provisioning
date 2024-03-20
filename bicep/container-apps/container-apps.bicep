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

param databaseLongTermBackups bool
param databaseBackupsStorageAccountName string
param databaseBackupsStorageAccountContainerName string

param phpFpmContainerAppExternal bool
param phpFpmContainerAppCustomDomains array
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool
param phpFpmCpuCores string
param phpFpmMemory string
param phpFpmScaleToZero bool
param phpFpmMaxReplicas int

param supervisordContainerAppName string
param supervisordImageName string
param supervisordCpuCores string
param supervisordMemory string

param redisContainerAppName string
param redisImageName string
param redisCpuCores string
param redisMemory string

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

param provisionElasticsearch bool
param elasticsearchContainerAppName string
param elasticsearchNodeName string
param elasticsearchCpuCores string
param elasticsearchMemory string

param provisionOpenSearch bool
param openSearchContainerAppName string
param openSearchCpuCores string
param openSearchMemory string

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
resource databaseBackupsStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (databaseLongTermBackups) {
  name: databaseBackupsStorageAccountName
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
var databaseBackupsStorageAccountKeySecret = (databaseLongTermBackups) ? {
  name: 'database-backups-storage-account-key'
  value: databaseBackupsStorageAccount.listKeys().keys[0].value
} : {}

// Set up common environment variables for the PHP-FPM and supervisord Container Apps
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
    databaseLongTermBackups: databaseLongTermBackups
    databaseBackupsStorageAccountName: databaseBackupsStorageAccountName
    databaseBackupsStorageAccountContainerName: databaseBackupsStorageAccountContainerName
    elasticSearchHost: elasticsearchContainerAppName
    openSearchHost: openSearchContainerAppName
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
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: phpFpmContainerAppName
    imageName: phpFpmImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: phpFpmCpuCores
    memory: phpFpmMemory
    useProbes: phpFpmContainerAppUseProbes
    scaleToZero: phpFpmScaleToZero
    maxReplicas: phpFpmMaxReplicas
    customDomains: phpFpmContainerAppCustomDomains
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
    databaseBackupsStorageAccountKeySecret: databaseBackupsStorageAccountKeySecret
  }
}

module supervisordContainerApp 'container-apps-supervisord.bicep' = {
  name: 'supervisord-container-app'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerAppName: supervisordContainerAppName
    imageName: supervisordImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    cpuCores: supervisordCpuCores
    memory: supervisordMemory
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
    databaseBackupsStorageAccountKeySecret: databaseBackupsStorageAccountKeySecret
  }
}

module redisContainerApp 'container-apps-redis.bicep' = {
  name: 'redis-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerAppName: redisContainerAppName
    imageName: redisImageName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: redisCpuCores
    memory: redisMemory
  }
}

module elasticsearchContainerApp './container-apps-elasticsearch.bicep' = if (provisionElasticsearch) {
  name: 'elasticsearch-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppName: elasticsearchContainerAppName
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    cpuCores: elasticsearchCpuCores
    memory: elasticsearchMemory
    nodeName: elasticsearchNodeName
  }
}

module openSearchContainerApp './container-apps-open-search.bicep' = if (provisionOpenSearch) {
  name: 'open-search-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppName: openSearchContainerAppName
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    cpuCores: openSearchCpuCores
    memory: openSearchMemory
  }
}
