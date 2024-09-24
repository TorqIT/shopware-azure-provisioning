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
param initContainerAppJobReplicaTimeoutSeconds int
@secure()
param pimcoreAdminPassword string

param phpContainerAppExternal bool
param phpContainerAppCustomDomains array
param phpContainerAppName string
param phpContainerAppImageName string
param phpContainerAppUseProbes bool
param phpContainerAppCpuCores string
param phpContainerAppMemory string
param phpContainerAppMinReplicas int
param phpContainerAppMaxReplicas int
// Optional scale rules
param phpContainerAppProvisionCronScaleRule bool
param phpContainerAppCronScaleRuleDesiredReplicas int
param phpContainerAppCronScaleRuleStartSchedule string
param phpContainerAppCronScaleRuleEndSchedule string
param phpContainerAppCronScaleRuleTimezone string

param supervisordContainerAppName string
param supervisordContainerAppImageName string
param supervisordContainerAppCpuCores string
param supervisordContainerAppMemory string

param redisContainerAppName string
param redisContainerAppCpuCores string
param redisContainerAppMemory string

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

// Optional Portal Engine provisioning
param provisionForPortalEngine bool
param portalEngineStorageAccountName string
param portalEngineStorageAccountPublicBuildFileShareName string
param portalEnginePublicBuildStorageMountName string
param portalEngineStorageAccountDownloadsContainerName string

// Optional n8n Container App
param provisionN8N bool
param n8nContainerAppName string
param n8nContainerAppCpuCores string
param n8nContainerAppMemory string
param n8nContainerAppMinReplicas int
param n8nContainerAppMaxReplicas int
param n8nContainerAppCustomDomains array
param n8nContainerAppsEnvironmentStorageMountName string
param n8nStorageAccountFileShareName string
param n8nContainerAppVolumeName string
param n8nStorageAccountName string
param n8nDatabaseServerName string
param n8nDatabaseName string
param n8nDatabaseAdminUser string
@secure()
param n8nDatabaseAdminPassword string
param n8nContainerAppProvisionCronScaleRule bool
param n8nContainerAppCronScaleRuleDesiredReplicas int
param n8nContainerAppCronScaleRuleStartSchedule string
param n8nContainerAppCronScaleRuleEndSchedule string
param n8nContainerAppCronScaleRuleTimezone string

module containerAppsEnvironment 'environment/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    location: location
    name: containerAppsEnvironmentName
    phpContainerAppExternal: phpContainerAppExternal
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName

    // Optional Portale Engine storage mount
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountName: portalEngineStorageAccountName
    portalEngineStorageAccountPublicFileShareName: portalEngineStorageAccountPublicBuildFileShareName
    portalEnginePublicStorageMountName: portalEnginePublicBuildStorageMountName
  }
}

// Set up common secrets for the PHP and supervisord Container Apps
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}
var containerRegistryPasswordSecret = {
  name: 'container-registry-password'
  value: containerRegistry.listCredentials().passwords[0].value
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}
var storageAccountKeySecret = {
  name: 'storage-account-key'
  value: storageAccount.listKeys().keys[0].value  
}
var databasePasswordSecret = {
  name: 'database-password'
  value: databasePassword
}
// Optional Portal Engine provisioning
resource portalEngineStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (provisionForPortalEngine) {
  name: portalEngineStorageAccountName
}
var portalEngineStorageAccountKeySecret = (provisionForPortalEngine) ? {
  name: 'portal-engine-storage-account-key'
  value: portalEngineStorageAccount.listKeys().keys[0].value
} : {}

// Set up common environment variables for the PHP and supervisord Container Apps
module environmentVariables 'container-apps-env-variables.bicep' = {
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
    additionalEnvVars: additionalEnvVars

    // Optional Portal Engine provisioning
    provisionPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountName: portalEngineStorageAccountName
    portalEngineStorageAccountDownloadsContainerName: portalEngineStorageAccountDownloadsContainerName
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
    replicaTimeoutSeconds: initContainerAppJobReplicaTimeoutSeconds
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

    // Optional Portal Engine provisioning
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountKeySecret: portalEngineStorageAccountKeySecret
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
  }
}

module phpContainerApp 'container-app-php.bicep' = {
  name: 'php-container-app'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: phpContainerAppName
    imageName: phpContainerAppImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: phpContainerAppCpuCores
    memory: phpContainerAppMemory
    useProbes: phpContainerAppUseProbes
    minReplicas: phpContainerAppMinReplicas
    maxReplicas: phpContainerAppMaxReplicas
    customDomains: phpContainerAppCustomDomains
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret

    // Optional Portal Engine provisioning
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountKeySecret: portalEngineStorageAccountKeySecret
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName

    // Optional scaling rules
    provisionCronScaleRule: phpContainerAppProvisionCronScaleRule
    cronScaleRuleDesiredReplicas: phpContainerAppCronScaleRuleDesiredReplicas
    cronScaleRuleStartSchedule: phpContainerAppCronScaleRuleStartSchedule
    cronScaleRuleEndSchedule: phpContainerAppCronScaleRuleEndSchedule
    cronScaleRuleTimezone: phpContainerAppCronScaleRuleTimezone
  }
}

module supervisordContainerApp 'container-app-supervisord.bicep' = {
  name: 'supervisord-container-app'
  dependsOn: [containerAppsEnvironment, environmentVariables]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: supervisordContainerAppName
    imageName: supervisordContainerAppImageName
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    cpuCores: supervisordContainerAppCpuCores
    memory: supervisordContainerAppMemory
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret

    // Optional Portal Engine provisioning
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountKeySecret: portalEngineStorageAccountKeySecret
  }
}

module redisContainerApp 'container-app-redis.bicep' = {
  name: 'redis-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: redisContainerAppName
    cpuCores: redisContainerAppCpuCores
    memory: redisContainerAppMemory
  }
}

// Optional n8n Container App
module n8nContainerApp './container-app-n8n.bicep' = if (provisionN8N) {
  name: 'n8n-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppsEnvironmentStorageMountName: n8nContainerAppsEnvironmentStorageMountName
    containerAppName: n8nContainerAppName
    cpuCores: n8nContainerAppCpuCores
    memory: n8nContainerAppMemory
    minReplicas: n8nContainerAppMinReplicas
    maxReplicas: n8nContainerAppMaxReplicas
    customDomains: n8nContainerAppCustomDomains
    volumeName: n8nContainerAppVolumeName
    storageAccountName: n8nStorageAccountName
    storageAccountFileShareName: n8nStorageAccountFileShareName
    databaseServerName: n8nDatabaseServerName
    databaseName: n8nDatabaseName
    databaseUser: n8nDatabaseAdminUser
    databasePassword: n8nDatabaseAdminPassword

    // Optional scaling rules
    provisionCronScaleRule: n8nContainerAppProvisionCronScaleRule
    cronScaleRuleDesiredReplicas: n8nContainerAppCronScaleRuleDesiredReplicas
    cronScaleRuleStartSchedule: n8nContainerAppCronScaleRuleStartSchedule
    cronScaleRuleEndSchedule: n8nContainerAppCronScaleRuleEndSchedule
    cronScaleRuleTimezone: n8nContainerAppCronScaleRuleTimezone
  }
}
