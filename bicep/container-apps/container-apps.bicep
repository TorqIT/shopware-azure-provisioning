param location string = resourceGroup().location

param containerAppsEnvironmentName string
param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param databaseServerName string

param containerRegistryName string

param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string

param provisionInit bool
param initContainerAppJobName string
param initContainerAppJobImageName string
param initContainerAppJobCpuCores string
param initContainerAppJobMemory string
param initContainerAppJobRunPimcoreInstall bool
@secure()
param pimcoreAdminPassword string

param phpFpmContainerAppExternal bool
param phpFpmContainerAppCustomDomains array
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool
param phpFpmCpuCores string
param phpFpmMemory string
param phpFpmScaleToZero bool
param phpFpmMaxReplicas int
param phpFpmProvisionWeb2Print bool

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
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
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

// TODO for now, this is optional, but will eventually be a mandatory part of Container App infrastructure
module initContainerAppJob 'container-app-job-init.bicep' = if (provisionInit) {
  name: 'init-container-app-job'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppJobName: initContainerAppJobName
    imageName: initContainerAppJobImageName
    cpuCores: initContainerAppJobCpuCores
    memory: initContainerAppJobMemory
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    storageAccountKeySecret: storageAccountKeySecret
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    defaultEnvVars: environmentVariables.outputs.envVars
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    runPimcoreInstall: initContainerAppJobRunPimcoreInstall
    pimcoreAdminPassword: pimcoreAdminPassword
  }
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
    provisionWeb2Print: phpFpmProvisionWeb2Print
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
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
