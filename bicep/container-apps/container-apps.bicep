param location string = resourceGroup().location

param containerAppsEnvironmentName string
param containerAppsEnvironmentUseWorkloadProfiles bool

param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param keyVaultName string

param databaseServerName string
param databaseName string
param databaseUser string
param databasePasswordSecretNameInKeyVault string

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

param supervisordContainerAppName string
param supervisordContainerAppImageName string
param supervisordContainerAppCpuCores string
param supervisordContainerAppMemory string

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
param additionalSecrets array

module containerAppsEnvironment 'environment/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    location: location
    name: containerAppsEnvironmentName
    phpContainerAppExternal: phpContainerAppExternal
    useWorkloadProfiles: containerAppsEnvironmentUseWorkloadProfiles
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// SECRETS
// Managed Identity allowing the Container App resources to pull secrets directly from the Key Vault
module managedIdentityForKeyVault './secrets/container-apps-key-vault-managed-identitity.bicep' = {
  name: 'container-apps-key-vault-managed-identity'
  params: {
    location: location
    keyVaultName: keyVaultName
    resourceGroupName: resourceGroup().name
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
// Set up common secrets for the init, PHP and supervisord Container Apps 
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
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
resource databaseServer 'Microsoft.DBforMySQL/flexibleServers@2024-02-01-preview' existing = {
  name: databaseServerName
}
resource databasePasswordSecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  parent: keyVault
  name: databasePasswordSecretNameInKeyVault
}
var databaseUrl = 'mysql://${databaseUser}:${databasePasswordSecretInKeyVault.properties.value}@${databaseServer.properties.fullyQualifiedDomainName}/${databaseName}'
var databaseUrlSecretRefName = 'database-url'
var databaseUrlSecret = {
  name: databaseUrlSecretRefName
  value: databaseUrl
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}
var storageAccountKeySecretRefName = 'storage-account-key'
var storageAccountKeySecret = {
  name: storageAccountKeySecretRefName
  value: storageAccount.listKeys().keys[0].value
}
var appSecretSecretRefName = 'app-secret'
var appSecretSecret = {
  name: appSecretSecretRefName
  value: appSecret
}
// Optional additional secrets, assumed to exist in Key Vault
module additionalSecretsModule './secrets/container-apps-additional-secrets.bicep' = {
  name: 'container-apps-additional-secrets'
  params: {
    keyVaultName: keyVaultName
    secrets: additionalSecrets
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.outputs.id
  }
}

// Environment variables
module environmentVariables './container-apps-env-variables.bicep' = {
  name: 'container-apps-env-vars'
  params: {
    appEnv: appEnv
    appUrl: appUrl
    appSecretSecretRefName: appSecretSecretRefName
    appInstallCurrency: appInstallCurrency
    appInstallLocale: appInstallLocale
    appSalesChannelName: appSalesChannelName
    appInstallCategoryId: appInstallCategoryId
    enableOpensearch: enableOpensearch
    opensearchUrl: opensearchUrl
    databaseUrlSecretRefName: databaseUrlSecretRefName
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    storageAccountName: storageAccountName
    storageAccountPublicContainerName: storageAccountPublicContainerName
    storageAccountKeySecretRefName: storageAccountKeySecretRefName
    additionalVars: additionalEnvVars
  }
}

module initContainerAppJob 'container-app-job-init.bicep' = {
  name: 'init-container-app-job'
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
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.outputs.id
    keyVaultName: keyVaultName
    additionalSecrets: additionalSecretsModule.outputs.secrets
  }
}

module phpContainerApp 'container-app-php.bicep' = {
  name: 'php-container-app'
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
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.outputs.id
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    appSecretSecret: appSecretSecret
    internalPort: phpContainerAppInternalPort
    additionalSecrets: additionalSecretsModule.outputs.secrets

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
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.outputs.id
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    additionalSecrets: additionalSecretsModule.outputs.secrets
  }
}
