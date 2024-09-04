param location string = resourceGroup().location

param containerAppsEnvironmentName string
param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param databaseServerName string
param databaseName string
param databaseUser string
@secure()
param databasePassword string

param containerRegistryName string

param shopwareInitContainerAppJobName string
param shopwareInitImageName string
param shopwareInitContainerAppJobCpuCores string
param shopwareInitContainerAppJobMemory string
param shopwareInitContainerAppJobReplicaTimeoutSeconds int

param shopwareWebContainerAppExternal bool
param shopwareWebContainerAppCustomDomains array
param shopwareWebContainerAppName string
param shopwareWebImageName string
param shopwareWebContainerAppCpuCores string
param shopwareWebContainerAppMemory string
param shopwareWebContainerAppMinReplicas int
param shopwareWebContainerAppMaxReplicas int
param shopwareWebContainerAppInternalPort int

param appEnv string
param appUrl string
param appInstallCurrency string
param appInstallLocale string
param appSalesChannelName string
param appInstallCategoryId string
@secure()
param appSecret string
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

resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2024-02-01-preview' existing = {
  name: databaseServerName
}

// Secrets
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
var databaseUrlSecretName = 'database-url'
var databaseUrl = 'mysql://${databaseUser}:${databasePassword}@${databaseServer.properties.fullyQualifiedDomainName}/${databaseName}'
var databaseUrlSecret = {
  name: databaseUrlSecretName
  value: databaseUrl
}
var appSecretSecretname = 'app-secret'
var appSecretSecret = {
  name: appSecretSecretname
  value: appSecret
}

// Environment variables
module environmentVariables './container-apps-variables.bicep' = {
  name: 'container-apps-env-vars'
  params: {
    appEnv: appEnv
    appUrl: appUrl
    appSecretSecretName: appSecretSecretname
    appInstallCurrency: appInstallCurrency
    appInstallLocale: appInstallLocale
    appSalesChannelName: appSalesChannelName
    appInstallCategoryId: appInstallCategoryId
    additionalVars: additionalEnvVars
    databaseUrlSecretName: databaseUrlSecretName
  }
}

module shopwareInitContainerAppJob 'container-app-job-shopware-init.bicep' = {
  name: 'shopware-init-container-app-job'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppJobName: shopwareInitContainerAppJobName
    imageName: shopwareInitImageName
    cpuCores: shopwareInitContainerAppJobCpuCores
    memory: shopwareInitContainerAppJobMemory
    replicaTimeoutSeconds: shopwareInitContainerAppJobReplicaTimeoutSeconds
    environmentVariables: environmentVariables.outputs.envVars
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databaseUrlSecret: databaseUrlSecret
    appSecretSecret: appSecretSecret
  }
}

module shopwareWebContainerApp 'container-app-shopware-web.bicep' = {
  name: 'shopware-web-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: shopwareWebContainerAppName
    imageName: shopwareWebImageName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: shopwareWebContainerAppCpuCores
    memory: shopwareWebContainerAppMemory
    minReplicas: shopwareWebContainerAppMinReplicas
    maxReplicas: shopwareWebContainerAppMaxReplicas
    environmentVariables: environmentVariables.outputs.envVars
    customDomains: shopwareWebContainerAppCustomDomains
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databaseUrlSecret: databaseUrlSecret
    appSecretSecret: appSecretSecret
    internalPort: shopwareWebContainerAppInternalPort
  }
}
