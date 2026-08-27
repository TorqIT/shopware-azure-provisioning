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
param databaseName string
param databaseUser string
param databaseServerVersion string
@secure()
param databasePassword string

param storageAccountName string
param storageAccountPublicContainerName string
param storageAccountPrivateContainerName string

param containerRegistryName string

param managedIdentityName string

param initContainerAppJobName string
param initContainerAppJobImageName string
param initContainerAppJobCpuCores string
param initContainerAppJobMemory string
param initContainerAppJobReplicaTimeoutSeconds int

param phpContainerAppExternal bool
param phpContainerAppCustomDomains array
param phpContainerAppName string
param phpContainerAppImageName string
param phpContainerAppProvisionStartupProbe bool
param phpContainerAppStartupProbePath string
param phpContainerAppStartupProbeInitialDelaySeconds int
param phpContainerAppStartupProbePeriodSeconds int
param phpContainerAppStartupProbeFailureThreshold int
param phpContainerAppStartupProbeTimeoutSeconds int
param phpContainerAppProvisionLivenessProbe bool
param phpContainerAppLivenessProbePath string
param phpContainerAppLivenessProbeInitialDelaySeconds int
param phpContainerAppLivenessProbePeriodSeconds int
param phpContainerAppLivenessProbeFailureThreshold int
param phpContainerAppLivenessProbeTimeoutSeconds int
param phpContainerAppProvisionReadinessProbe bool
param phpContainerAppReadinessProbePath string
param phpContainerAppReadinessProbeInitialDelaySeconds int
param phpContainerAppReadinessProbePeriodSeconds int
param phpContainerAppReadinessProbeFailureThreshold int
param phpContainerAppReadinessProbeTimeoutSeconds int
param phpContainerAppProbePort int
param phpContainerAppProbeScheme string
param phpContainerAppCpuCores string
param phpContainerAppMemory string
param phpContainerAppMinReplicas int
param phpContainerAppMaxReplicas int
param phpContainerAppIpSecurityRestrictions array
param phpContainerAppInternalPort int
// Optional scale rules
param phpContainerAppProvisionHttpScaleRule bool
param phpContainerAppHttpScaleRuleConcurrentRequestsThreshold int
param phpContainerAppProvisionCronScaleRule bool
param phpContainerAppCronScaleRuleDesiredReplicas int
param phpContainerAppCronScaleRuleStartSchedule string
param phpContainerAppCronScaleRuleEndSchedule string
param phpContainerAppCronScaleRuleTimezone string

param supervisordContainerAppName string
param supervisordContainerAppImageName string
param supervisordContainerAppCpuCores string
param supervisordContainerAppMemory string
param supervisordContainerAppInternalIngress bool

param appEnv string
param appDebug string
param appUrl string
param appInstallCurrency string
param appInstallCreateCAD bool
param appSalesChannelName string
param appSalesChannelId string
param appSalesChannelCurrencyId string
param appSalesChannelCountryIso string
param appSalesChannelSnippetsetId string
@secure()
param appSecret string
@secure()
param appPassword string
param azureCdnUrl string
param enableOpensearch bool
param opensearchUrl string
param additionalEnvVars array
param additionalSecrets array
param additionalVolumesAndMounts array

// Optional metric alerts provisioning
param provisionMetricAlerts bool
param generalMetricAlertsActionGroupName string
param criticalMetricAlertsActionGroupName string
param phpContainerAppResponseTimeAlertThreshold int
param phpContainerAppResponseTimeAlertTimeWindow string

// Optional (until v3) Opensearch Container App
param provisionOpensearch bool
param opensearchContainerAppName string
param opensearchContainerAppCpuCores string
param opensearchContainerAppMemory string
param opensearchContainerAppMinReplicas int
param opensearchContainerAppMaxReplicas int
param opensearchContainerAppsEnvironmentStorageMountName string
param opensearchStorageAccountFileShareName string
param opensearchContainerAppVolumeName string
param opensearchContainerAppJavaOpts string
param opensearchContainerAppAutoCreateIndex bool

// ENVIRONMENT
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}
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
    logAnalyticsCustomerId: logAnalyticsWorkspace.properties.customerId
    logAnalyticsSharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
    additionalVolumesAndMounts: additionalVolumesAndMounts
  }
}

// SECRETS
// Managed Identity allowing the Container App resources access other resources directly (e.g. Key Vault, Container Registry)
module managedIdentityModule './identity/container-apps-managed-identitity.bicep' = if (fullProvision) {
  name: 'container-apps-managed-identity'
  params: {
    location: location
    name: managedIdentityName
    keyVaultName: keyVaultName
    containerRegistryName: containerRegistryName
  }
}
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: managedIdentityName
}
var databaseUrl = 'mysql://${databaseUser}:${databasePassword}@${databaseServerName}.mysql.database.azure.com/${databaseName}'
var databaseUrlSecretRefName = 'database-url'
var databaseUrlSecret = {
  name: databaseUrlSecretRefName
  value: databaseUrl
}
// Set up common secrets for the init, PHP and supervisord Container Apps 
var databasePasswordSecretRefName = 'database-password'
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
    managedIdentityForKeyVaultId: managedIdentity.id
  }
}

// ENV VARS
// Set up common environment variables for the init, PHP and supervisord Container Apps
module environmentVariables 'container-apps-env-variables.bicep' = {
  name: 'environment-variables'
  dependsOn: provisionOpensearch ? [opensearchContainerApp] : []
  params: {
    appEnv: appEnv
    appDebug: appDebug
    appUrl: appUrl
    appSecretSecretRefName: appSecretSecretRefName
    appInstallCurrency: appInstallCurrency
    appInstallCreateCAD: appInstallCreateCAD
    appSalesChannelName: appSalesChannelName
    appSalesChannelId: appSalesChannelId
    appSalesChannelCurrencyId: appSalesChannelCurrencyId
    appSalesChannelCountryIso: appSalesChannelCountryIso
    appSalesChannelSnippetsetId: appSalesChannelSnippetsetId
    azureCdnUrl: azureCdnUrl
    enableOpensearch: enableOpensearch
    opensearchUrl: opensearchUrl
    databaseUrlSecretRefName: databaseUrlSecretRefName
    databaseServerName: databaseServerName
    databaseServerVersion: databaseServerVersion
    databaseName: databaseName
    databaseUser: databaseUser
    databasePasswordSecretRefName: databasePasswordSecretRefName
    provisionOpensearch: provisionOpensearch
    opensearchContainerAppName: opensearchContainerAppName
    storageAccountName: storageAccountName
    storageAccountPublicContainerName: storageAccountPublicContainerName
    storageAccountPrivateContainerName: storageAccountPrivateContainerName
    storageAccountKeySecretRefName: storageAccountKeySecretRefName
    additionalVars: concat(additionalEnvVars, additionalSecretsModule.outputs.envVars)
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
    containerRegistryName: containerRegistryName
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    appSecretSecret: appSecretSecret
    appPassword: appPassword
    databaseServerName: databaseServerName
    databaseName: databaseName
    databaseUser: databaseUser
    managedIdentityId: managedIdentity.id
    additionalSecrets: additionalSecretsModule.outputs.secrets
    additionalVolumesAndMounts: additionalVolumesAndMounts
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
    defaultEnvVars: environmentVariables.outputs.envVars
    containerRegistryName: containerRegistryName
    cpuCores: phpContainerAppCpuCores
    memory: phpContainerAppMemory
    provisionStartupProbe: phpContainerAppProvisionStartupProbe
    startupProbePath: phpContainerAppStartupProbePath
    startupProbeInitialDelaySeconds: phpContainerAppStartupProbeInitialDelaySeconds
    startupProbePeriodSeconds: phpContainerAppStartupProbePeriodSeconds
    startupProbeFailureThreshold: phpContainerAppStartupProbeFailureThreshold
    startupProbeTimeoutSeconds: phpContainerAppStartupProbeTimeoutSeconds
    provisionLivenessProbe: phpContainerAppProvisionLivenessProbe
    livenessProbePath: phpContainerAppLivenessProbePath
    livenessProbeInitialDelaySeconds: phpContainerAppLivenessProbeInitialDelaySeconds
    livenessProbePeriodSeconds: phpContainerAppLivenessProbePeriodSeconds
    livenessProbeFailureThreshold: phpContainerAppLivenessProbeFailureThreshold
    livenessProbeTimeoutSeconds: phpContainerAppLivenessProbeTimeoutSeconds
    provisionReadinessProbe: phpContainerAppProvisionReadinessProbe
    readinessProbePath: phpContainerAppReadinessProbePath
    readinessProbeInitialDelaySeconds: phpContainerAppReadinessProbeInitialDelaySeconds
    readinessProbePeriodSeconds: phpContainerAppReadinessProbePeriodSeconds
    readinessProbeFailureThreshold: phpContainerAppReadinessProbeFailureThreshold
    readinessProbeTimeoutSeconds: phpContainerAppReadinessProbeTimeoutSeconds
    probePort: phpContainerAppProbePort
    probeScheme: phpContainerAppProbeScheme
    minReplicas: phpContainerAppMinReplicas
    maxReplicas: phpContainerAppMaxReplicas
    customDomains: phpContainerAppCustomDomains
    isExternal: phpContainerAppExternal
    ipSecurityRestrictions: phpContainerAppIpSecurityRestrictions
    environmentVariables: environmentVariables.outputs.envVars
    managedIdentityId: managedIdentity.id
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    appSecretSecret: appSecretSecret
    internalPort: phpContainerAppInternalPort
    additionalSecrets: additionalSecretsModule.outputs.secrets
    additionalVolumesAndMounts: additionalVolumesAndMounts

    // Optional scaling rules
    provisionHttpScaleRule: phpContainerAppProvisionHttpScaleRule
    httpScaleRuleConcurrentRequestsThreshold: phpContainerAppHttpScaleRuleConcurrentRequestsThreshold
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
    containerRegistryName: containerRegistryName
    cpuCores: supervisordContainerAppCpuCores
    memory: supervisordContainerAppMemory
    managedIdentityId: managedIdentity.id
    databaseUrlSecret: databaseUrlSecret
    storageAccountKeySecret: storageAccountKeySecret
    appSecretSecret: appSecretSecret
    additionalSecrets: additionalSecretsModule.outputs.secrets
    additionalVolumesAndMounts: additionalVolumesAndMounts
    internalIngress: supervisordContainerAppInternalIngress
  }
}

// Optional (until v3) Opensearch Container App
module opensearchContainerApp 'container-app-opensearch.bicep' = if (provisionOpensearch) {
  name: 'opensearch-container-app'
  dependsOn: [containerAppsEnvironment]
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppName: opensearchContainerAppName
    cpuCores: opensearchContainerAppCpuCores
    memory: opensearchContainerAppMemory
    minReplicas: opensearchContainerAppMinReplicas
    maxReplicas: opensearchContainerAppMaxReplicas
    containerAppsEnvironmentStorageMountName: opensearchContainerAppsEnvironmentStorageMountName
    storageAccountFileShareName: opensearchStorageAccountFileShareName
    volumeName: opensearchContainerAppVolumeName
    keyVaultName: keyVaultName
    managedIdentityForKeyVaultId: managedIdentity.id
    storageAccountKey: storageAccount.listKeys().keys[0].value
    storageAccountName: storageAccountName
    javaOpts: opensearchContainerAppJavaOpts
    autoCreateIndex: opensearchContainerAppAutoCreateIndex
  }
}

// Optional metric alerts
module alerts './alerts/container-app-alerts.bicep' = [for containerAppName in [phpContainerAppName, supervisordContainerAppName]: if (provisionMetricAlerts) {
  name: '${containerAppName}-alerts'
  dependsOn: [phpContainerApp, supervisordContainerApp]
  params: {
    containerAppName: containerAppName
    generalMetricAlertsActionGroupName: generalMetricAlertsActionGroupName
    responseTimeAlertThreshold: phpContainerAppResponseTimeAlertThreshold
    responseTimeAlertTimeWindow: phpContainerAppResponseTimeAlertTimeWindow
  }
}]
