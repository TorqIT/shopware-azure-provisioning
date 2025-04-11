param location string = resourceGroup().location

param fullProvision bool

param containerAppsEnvironmentName string
param containerAppsEnvironmentUseWorkloadProfiles bool

param logAnalyticsWorkspaceName string

param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualNetworkSubnetName string

param keyVaultName string

param databaseServerName string
param databaseServerVersion string
param databasePasswordSecretNameInKeyVault string

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
param pimcoreAdminPasswordSecretName string

param phpContainerAppExternal bool
param phpContainerAppCustomDomains array
param phpContainerAppName string
param phpContainerAppImageName string
param phpContainerAppUseProbes bool
param phpContainerAppCpuCores string
param phpContainerAppMemory string
param phpContainerAppMinReplicas int
param phpContainerAppMaxReplicas int
param phpContainerAppIpSecurityRestrictions array
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
param redisContainerAppMaxMemorySetting string

param appDebug string
param appEnv string
param databaseName string
param databaseUser string
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisSessionDb string
param additionalEnvVars array
param additionalSecrets array
param additionalVolumesAndMounts array

// Optional metric alerts provisioning
param provisionMetricAlerts bool
param generalMetricAlertsActionGroupName string
param criticalMetricAlertsActionGroupName string

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
param n8nDatabaseAdminPasswordSecretName string
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
    useWorkloadProfiles: containerAppsEnvironmentUseWorkloadProfiles
    phpContainerAppExternal: phpContainerAppExternal
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
    virtualNetworkSubnetName: virtualNetworkSubnetName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName

    // Optional Portal Engine storage mount
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountName: portalEngineStorageAccountName
    portalEngineStorageAccountPublicBuildFileShareName: portalEngineStorageAccountPublicBuildFileShareName
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName

    additionalVolumesAndMounts: additionalVolumesAndMounts
  }
}

// SECRETS
// Managed Identity allowing the Container App resources to pull secrets directly from the Key Vault
var managedIdentityName = '${resourceGroup().name}-container-app-managed-id'
module managedIdentityForKeyVaultModule './secrets/container-apps-key-vault-managed-identitity.bicep' = if (fullProvision) {
  name: 'container-apps-key-vault-managed-identity'
  params: {
    location: location
    name: managedIdentityName
    fullProvision: fullProvision
    keyVaultName: keyVaultName
  }
}
resource managedIdentityForKeyVault 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: managedIdentityName
}
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
// Set up common secrets for the init, PHP and supervisord Container Apps 
var databasePasswordSecretRefName = 'database-password'
var portalEngineStorageAccountSecretRefName = 'portal-engine-storage-account-key'
var storageAccountKeySecretRefName = 'storage-account-key'
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}
var containerRegistryPasswordSecret = {
  name: 'container-registry-password'
  value: containerRegistry.listCredentials().passwords[0].value
}
var containerRegistryConfiguration = {
  server: '${containerRegistryName}.azurecr.io'
  username: containerRegistry.listCredentials().username
  passwordSecretRef: 'container-registry-password'
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}
var storageAccountKeySecret = {
  name: 'storage-account-key'
  value: storageAccount.listKeys().keys[0].value  
}
resource databasePasswordSecretInKeyVault 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  parent: keyVault
  name: databasePasswordSecretNameInKeyVault
}
var databasePasswordSecret = {
  name: databasePasswordSecretRefName
  keyVaultUrl: databasePasswordSecretInKeyVault.properties.secretUri
  identity: managedIdentityForKeyVault.id
}
// Optional additional secrets, assumed to exist in Key Vault
module additionalSecretsModule './secrets/container-apps-additional-secrets.bicep' = {
  name: 'container-apps-additional-secrets'
  params: {
    secrets: additionalSecrets
    keyVaultName: keyVaultName
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.id
  }
}
// Optional Portal Engine secrets
resource portalEngineStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (provisionForPortalEngine) {
  name: portalEngineStorageAccountName
}
var portalEngineStorageAccountKeySecret = (provisionForPortalEngine) ? {
  name: portalEngineStorageAccountSecretRefName
  value: portalEngineStorageAccount.listKeys().keys[0].value
} : {}

// ENV VARS
// Set up common environment variables for the init, PHP and supervisord Container Apps
module environmentVariables 'container-apps-env-variables.bicep' = {
  name: 'environment-variables'
  params: {
    appDebug: appDebug
    appEnv: appEnv
    databaseServerName: databaseServerName
    databaseServerVersion: databaseServerVersion
    databaseName: databaseName
    databaseUser: databaseUser
    databasePasswordSecretRefName: databasePasswordSecretRefName
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisHost: redisContainerAppName
    redisDb: redisDb
    redisSessionDb: redisSessionDb
    storageAccountName: storageAccountName
    storageAccountContainerName: storageAccountContainerName
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountKeySecretRefName: storageAccountKeySecretRefName
    additionalEnvVars: concat(additionalEnvVars, additionalSecretsModule.outputs.envVars)

    // Optional Portal Engine provisioning
    provisionPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountName: portalEngineStorageAccountName
    portalEngineStorageAccountDownloadsContainerName: portalEngineStorageAccountDownloadsContainerName
    portalEngineStorageAccountKeySecretRefName: portalEngineStorageAccountSecretRefName
  }
}

// TODO for now, this is optional, but will eventually be a mandatory part of Container App infrastructure
module initContainerAppJob 'container-app-job-init.bicep' = if (provisionInit) {
  name: 'init-container-app-job'
  dependsOn: [containerAppsEnvironment]
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
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.id
    keyVaultName: keyVaultName
    pimcoreAdminPasswordSecretName: pimcoreAdminPasswordSecretName
    additionalSecrets: additionalSecretsModule.outputs.secrets
    additionalVolumesAndMounts: additionalVolumesAndMounts
    
    // Optional Portal Engine provisioning
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountKeySecret: portalEngineStorageAccountKeySecret
    portalEnginePublicBuildStorageMountName: portalEnginePublicBuildStorageMountName
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
    environmentVariables: environmentVariables.outputs.envVars
    containerRegistryConfiguration: containerRegistryConfiguration
    containerRegistryName: containerRegistryName
    cpuCores: phpContainerAppCpuCores
    memory: phpContainerAppMemory
    useProbes: phpContainerAppUseProbes
    minReplicas: phpContainerAppMinReplicas
    maxReplicas: phpContainerAppMaxReplicas
    customDomains: phpContainerAppCustomDomains
    ipSecurityRestrictions: phpContainerAppIpSecurityRestrictions
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.id
    containerRegistryPasswordSecret: containerRegistryPasswordSecret
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
    additionalSecrets: additionalSecretsModule.outputs.secrets
    additionalVolumesAndMounts: additionalVolumesAndMounts

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
  dependsOn: [containerAppsEnvironment]
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
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.id
    databasePasswordSecret: databasePasswordSecret
    storageAccountKeySecret: storageAccountKeySecret
    additionalSecrets: additionalSecretsModule.outputs.secrets
    additionalVolumesAndMounts: additionalVolumesAndMounts

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
    maxMemorySetting: redisContainerAppMaxMemorySetting
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
    keyVaultName: keyVaultName
    managedIdentityForKeyVaultId: managedIdentityForKeyVault.id
    storageAccountName: n8nStorageAccountName
    storageAccountFileShareName: n8nStorageAccountFileShareName
    databaseServerName: n8nDatabaseServerName
    databaseName: n8nDatabaseName
    databaseUser: n8nDatabaseAdminUser
    databasePasswordSecretName: n8nDatabaseAdminPasswordSecretName

    // Optional scaling rules
    provisionCronScaleRule: n8nContainerAppProvisionCronScaleRule
    cronScaleRuleDesiredReplicas: n8nContainerAppCronScaleRuleDesiredReplicas
    cronScaleRuleStartSchedule: n8nContainerAppCronScaleRuleStartSchedule
    cronScaleRuleEndSchedule: n8nContainerAppCronScaleRuleEndSchedule
    cronScaleRuleTimezone: n8nContainerAppCronScaleRuleTimezone
  }
}

// Optional metric alerts
module alerts './alerts/container-app-alerts.bicep' = [for containerAppName in [phpContainerAppName, supervisordContainerAppName]: if (provisionMetricAlerts) {
  name: '${containerAppName}-alerts'
  dependsOn: [phpContainerApp, supervisordContainerApp]
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
  }
}] 
