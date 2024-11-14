param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppsEnvironmentUseWorkloadProfiles bool

param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param databaseServerName string

param databaseName string
param databaseUser string
@secure()
param databasePassword string

param storageAccountName string
param storageAccountPublicContainerName string

param containerRegistryName string

param initContainerAppJobName string
param initContainerAppJobImageName string
param initContainerAppJobCpuCores string
param initContainerAppJobMemory string
param initContainerAppJobReplicaTimeoutSeconds int

param phpContainerAppExternal bool
param phpContainerAppCustomDomains array
param phpContainerAppName string
param phpContainerAppImageName string
param phpContainerAppCpuCores string
param phpContainerAppMemory string
param phpContainerAppMinReplicas int
param phpContainerAppMaxReplicas int
param phpContainerAppIpSecurityRestrictions array
param phpContainerAppInternalPort int
// Optional scale rules
param phpContainerAppProvisionCronScaleRule bool
param phpContainerAppCronScaleRuleDesiredReplicas int
param phpContainerAppCronScaleRuleStartSchedule string
param phpContainerAppCronScaleRuleEndSchedule string
param phpContainerAppCronScaleRuleTimezone string

param appEnv string
param appUrl string
param appInstallCurrency string
param appInstallLocale string
param appSalesChannelName string
param appInstallCategoryId string
@secure()
param appSecret string
param enableOpensearch bool
param opensearchUrl string
param additionalEnvVars array

module containerAppsEnvironment 'environment/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    location: location
    name: containerAppsEnvironmentName
    shopwareWebContainerAppExternal: phpContainerAppExternal
    useWorkloadProfiles: containerAppsEnvironmentUseWorkloadProfiles
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// Set up common secrets for the PHP and supervisord Container Apps
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2024-02-01-preview' existing = {
  name: databaseServerName
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
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
var storageAccountKeySecretName = 'storage-account-key'
var storageAccountKeySecret = {
  name: storageAccountKeySecretName
  value: storageAccount.listKeys().keys[0].value
}
var appSecretSecretname = 'app-secret'
var appSecretSecret = {
  name: appSecretSecretname
  value: appSecret
}

// Environment variables
module environmentVariables './container-apps-env-variables.bicep' = {
  name: 'container-apps-env-vars'
  params: {
    appEnv: appEnv
    appUrl: appUrl
    appSecretSecretName: appSecretSecretname
    appInstallCurrency: appInstallCurrency
    appInstallLocale: appInstallLocale
    appSalesChannelName: appSalesChannelName
    appInstallCategoryId: appInstallCategoryId
    enableOpensearch: enableOpensearch
    opensearchUrl: opensearchUrl
    databaseUrlSecretName: databaseUrlSecretName
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    storageAccountName: storageAccountName
    storageAccountPublicContainerName: storageAccountPublicContainerName
    storageAccountKeySecretName: storageAccountKeySecretName
    additionalVars: additionalEnvVars
  }
}

module shopwareInitContainerAppJob 'container-app-job-shopware-init.bicep' = {
  name: 'shopware-init-container-app-job'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppJobName: initContainerAppJobName
    imageName: initContainerAppJobImageName
    cpuCores: initContainerAppJobCpuCores
    memory: initContainerAppJobMemory
    replicaTimeoutSeconds: initContainerAppJobReplicaTimeoutSeconds
    environmentVariables: environmentVariables.outputs.envVars
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    appSecretSecret: appSecretSecret
  }
}

module shopwareWebContainerApp 'container-app-shopware-web.bicep' = {
  name: 'shopware-web-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: phpContainerAppName
    imageName: phpContainerAppImageName
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: phpContainerAppCpuCores
    memory: phpContainerAppMemory
    minReplicas: phpContainerAppMinReplicas
    maxReplicas: phpContainerAppMaxReplicas
    ipSecurityRestrictions: phpContainerAppIpSecurityRestrictions
    environmentVariables: environmentVariables.outputs.envVars
    customDomains: phpContainerAppCustomDomains
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    appSecretSecret: appSecretSecret
    internalPort: phpContainerAppInternalPort

    // Optional scaling rules
    provisionCronScaleRule: phpContainerAppProvisionCronScaleRule
    cronScaleRuleDesiredReplicas: phpContainerAppCronScaleRuleDesiredReplicas
    cronScaleRuleStartSchedule: phpContainerAppCronScaleRuleStartSchedule
    cronScaleRuleEndSchedule: phpContainerAppCronScaleRuleEndSchedule
    cronScaleRuleTimezone: phpContainerAppCronScaleRuleTimezone
  }
}
