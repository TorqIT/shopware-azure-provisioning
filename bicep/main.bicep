param location string = resourceGroup().location

param containerRegistryName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

// Virtual Network
param virtualNetworkName string
param virtualNetworkAddressSpace string = '10.0.0.0/16'
// If set to a value other than the Resource Group used for the rest of the resources, the VNet will be assumed to already exist in that Resource Group
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkContainerAppsSubnetName string = 'pimcore-container-apps'
param virtualNetworkContainerAppsSubnetAddressSpace string = '10.0.0.0/23'
param virtualNetworkDatabaseSubnetName string = 'pimcore-database'
param virtualNetworkDatabaseSubnetAddressSpace string = '10.0.2.0/28'
// TODO legacy applications place Private Endpoints in the same subnet as the Container Apps, but this
// is incorrect as such a subnet should be only occupied by the Container Apps. This setup works fine for
// Consumption plan CAs but not workload profiles, and in general should be avoided
param virtualNetworkPrivateEndpointsSubnetName string = virtualNetworkContainerAppsSubnetName
param virtualNetworkPrivateEndpointsSubnetAddressSpace string = '10.0.5.0/29'
module virtualNetwork 'virtual-network/virtual-network.bicep' = if (virtualNetworkResourceGroupName == resourceGroup().name) {
  name: 'virtual-network'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    containerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    containerAppsSubnetAddressSpace:  virtualNetworkContainerAppsSubnetAddressSpace
    containerAppsEnvironmentUseWorkloadProfiles: containerAppsEnvironmentUseWorkloadProfiles
    databaseSubnetAddressSpace: virtualNetworkDatabaseSubnetAddressSpace
    databaseSubnetName: virtualNetworkDatabaseSubnetName
    privateEndpointsSubnetName: virtualNetworkPrivateEndpointsSubnetName
    privateEndpointsSubnetAddressSpace: virtualNetworkPrivateEndpointsSubnetAddressSpace
    // Optional services VM provisioning (see configuration below)
    provisionServicesVM: provisionServicesVM
    servicesVmSubnetName: servicesVmSubnetName
    servicesVmSubnetAddressSpace: servicesVmSubnetAddressSpace
    // Optional n8n provisioning (see more n8n configuration below)
    provisionN8N: provisionN8N
    n8nDatabaseSubnetName: n8nVirtualNetworkDatabaseSubnetName
    n8nDatabaseSubnetAddressSpace: n8nVirtualNetworkDatabaseSubnetAddressSpace
  }
}

// Key Vault
param keyVaultName string
// If set to a value other than the Resource Group used for the rest of the resources, the Key Vault will be assumed to already exist in that Resource Group
param keyVaultResourceGroupName string = resourceGroup().name
param keyVaultEnablePurgeProtection bool = true
module keyVaultModule './key-vault/key-vault.bicep' = if (keyVaultResourceGroupName == resourceGroup().name) {
  name: 'key-vault'
  dependsOn: [virtualNetwork]
  params: {
    name: keyVaultName
    localIpAddress: localIpAddress
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkName: virtualNetworkName
    virtualNetworkContainerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    enablePurgeProtection: keyVaultEnablePurgeProtection
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

param privateDnsZonesSubscriptionId string = subscription().id
param privateDnsZonesResourceGroupName string = resourceGroup().name
param privateDnsZoneForDatabaseName string = 'privatelink.mysql.database.azure.com'
param privateDnsZoneForStorageAccountsName string = 'privatelink.blob.${environment().suffixes.storage}'
module privateDnsZones './private-dns-zones/private-dns-zones.bicep' = {
  name: 'private-dns-zones'
  params:{
    privateDnsZonesSubscriptionId: privateDnsZonesSubscriptionId
    privateDnsZonesResourceGroupName: privateDnsZonesResourceGroupName
    privateDnsZoneForDatabaseName: privateDnsZoneForDatabaseName
    privateDnsZoneForStorageAccountsName: privateDnsZoneForStorageAccountsName
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
  }
}

// Backup Vault
// TODO remove once all clients are moved over to use this model - relic of previously using the Backup Vault for Storage Accounts only
param storageAccountBackupVaultName string = '${storageAccountName}-backup-vault'
param backupVaultName string = storageAccountBackupVaultName
module backupVault 'backup-vault/backup-vault.bicep' = if (/*databaseLongTermBackups || */storageAccountLongTermBackups) {
  name: 'backup-vault'
  params: {
    name: backupVaultName
  }
}

// Storage Account
param storageAccountName string
param storageAccountSku string = 'Standard_LRS'
param storageAccountKind string = 'StorageV2'
param storageAccountAccessTier string = 'Hot'
param storageAccountContainerName string = 'pimcore'
param storageAccountAssetsContainerName string = 'pimcore-assets'
@allowed(['public', 'partial', 'private'])
param storageAccountAssetsContainerAccessLevel string = 'private'
param storageAccountFirewallIps array = []
param storageAccountCdnAccess bool = false
param storageAccountBackupRetentionDays int = 7
param storageAccountPrivateEndpointName string = '${storageAccountName}-private-endpoint'
param storageAccountPrivateEndpointNicName string = ''
param storageAccountLongTermBackups bool = true
param storageAccountLongTermBackupRetentionPeriod string = 'P365D'
module storageAccount 'storage-account/storage-account.bicep' = {
  name: 'storage-account'
  dependsOn: [virtualNetwork, backupVault]
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: storageAccountContainerName
    assetsContainerName: storageAccountAssetsContainerName
    accessTier: storageAccountAccessTier
    kind: storageAccountKind
    sku: storageAccountSku
    assetsContainerAccessLevel: storageAccountAssetsContainerAccessLevel
    firewallIps: storageAccountFirewallIps
    cdnAssetAccess: storageAccountCdnAccess
    virtualNetworkName: virtualNetworkName
    virtualNetworkPrivateEndpointSubnetName: virtualNetworkPrivateEndpointsSubnetName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    shortTermBackupRetentionDays: storageAccountBackupRetentionDays
    privateDnsZoneId: privateDnsZones.outputs.zoneIdForStorageAccounts
    privateEndpointName: storageAccountPrivateEndpointName
    privateEndpointNicName: storageAccountPrivateEndpointNicName
    longTermBackups: storageAccountLongTermBackups
    backupVaultName: backupVaultName
    longTermBackupRetentionPeriod: storageAccountLongTermBackupRetentionPeriod
  }
}

// Optional Azure Files-based Storage Account for use as volume mounts in Container Apps (leveraging NFS)
param fileStorageAccountName string = ''
param fileStorageAccountSku string = 'Premium_LRS'
param fileStorageAccountFileShares array = []
module fileStorage './file-storage/file-storage.bicep' = {
  name: 'file-storage-account'
  dependsOn: [virtualNetwork]
  params: {
    storageAccountName: fileStorageAccountName
    storageAccountSku: fileStorageAccountSku
    fileShares: map(fileStorageAccountFileShares, (fileShare => {
      name: fileShare.name
      maxSizeGB: fileShare.maxSizeGB
    }))
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
  }
}

// Database
param databaseServerName string
param databaseAdminUsername string = 'adminuser'
param databasePasswordSecretName string = 'databasePassword'
param databaseSkuName string = 'Standard_B1ms'
param databaseSkuTier string = 'Burstable'
param databaseStorageSizeGB int = 20
param databaseName string = 'pimcore'
param databaseBackupRetentionDays int = 7 //deprecated in favor of renamed param below
param databaseShortTermBackupRetentionDays int = databaseBackupRetentionDays
param databaseGeoRedundantBackup bool = false
param databaseLongTermBackups bool = false
// param databaseLongTermBackupRetentionPeriod string = 'P365D'
param databaseBackupsStorageAccountName string = ''
param databaseBackupsStorageAccountSku string = 'Standard_LRS'
param databaseBackupsStorageAccountKind string = 'StorageV2'
param databaseBackupsStorageAccountContainerName string = 'database'
module database 'database/database.bicep' = {
  name: 'database'
  dependsOn: [virtualNetwork, backupVault]
  params: {
    location: location
    administratorLogin: databaseAdminUsername
    administratorPassword: keyVault.getSecret(databasePasswordSecretName)
    databaseName: databaseName
    serverName: databaseServerName
    skuName: databaseSkuName
    skuTier: databaseSkuTier
    storageSizeGB: databaseStorageSizeGB
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkPrivateEndpointsSubnetName: virtualNetworkPrivateEndpointsSubnetName
    shortTermBackupRetentionDays: databaseBackupRetentionDays
    geoRedundantBackup: databaseGeoRedundantBackup
    privateDnsZoneForDatabaseId: privateDnsZones.outputs.zoneIdForDatabase
    longTermBackups: databaseLongTermBackups
    databaseBackupsStorageAccountName: databaseBackupsStorageAccountName
    databaseBackupsStorageAccountContainerName: databaseBackupsStorageAccountContainerName
    databaseBackupsStorageAccountKind: databaseBackupsStorageAccountKind
    databaseBackupsStorageAccountSku: databaseBackupsStorageAccountSku
  }
}

param logAnalyticsWorkspaceName string = '${resourceGroupName}-log-analytics'
module logAnalyticsWorkspace 'log-analytics-workspace/log-analytics-workspace.bicep' = {
  name: 'log-analytics-workspace'
  params: {
    name: logAnalyticsWorkspaceName
  }
}

// Container Apps
param containerAppsEnvironmentName string
param containerAppsEnvironmentUseWorkloadProfiles bool = false
// Init Container App Job
// TODO for now, this is optional, but will eventually be a mandatory part of Container App infrastructure
param provisionInit bool = false
param initContainerAppJobName string = ''
param initContainerAppJobImageName string = ''
param initContainerAppJobCpuCores string = '0.5'
param initContainerAppJobMemory string = '1Gi'
param initContainerAppJobReplicaTimeoutSeconds int = 600
param initContainerAppJobRunPimcoreInstall bool = false
param pimcoreAdminPasswordSecretName string = 'pimcore-admin-password'
// PHP ("web") Container App 
param phpContainerAppExternal bool = true
param phpContainerAppName string
param phpContainerAppImageName string
param phpContainerAppUseProbes bool = false
param phpContainerAppCustomDomains array = []
param phpContainerAppCpuCores string = '0.5'
param phpContainerAppMemory string = '1Gi'
param phpContainerAppMinReplicas int = 1
param phpContainerAppMaxReplicas int = 1
param phpContainerAppIpSecurityRestrictions array = []
// Optional scaling rules
param phpContainerAppProvisionCronScaleRule bool = false
param phpContainerAppCronScaleRuleDesiredReplicas int = 1
param phpContainerAppCronScaleRuleStartSchedule string = '0 7 * * *'
param phpContainerAppCronScaleRuleEndSchedule string = '0 18 * * *'
param phpContainerAppCronScaleRuleTimezone string = 'Etc/UTC'
// Supervisord Container App
param supervisordContainerAppName string
param supervisordContainerAppImageName string
param supervisordContainerAppCpuCores string = '0.25'
param supervisordContainerAppMemory string = '0.5Gi'
// Redis Container App
param redisContainerAppName string
param redisContainerAppCpuCores string = '0.25'
param redisContainerAppMemory string = '0.5Gi'
param redisContainerAppMaxMemorySetting string = '256mb'
// Symfony/Pimcore runtime variables
@allowed(['0', '1'])
param appDebug string
param appEnv string
@allowed(['0', '1'])
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisSessionDb string
param additionalEnvVars array = []
// TODO no need for this to be an object anymore, it could be an array
param additionalSecrets object = {}
param additionalVolumesAndMounts array = []
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  dependsOn: [virtualNetwork, containerRegistry, logAnalyticsWorkspace, storageAccount, fileStorage, database, portalEngineStorageAccount]
  params: {
    location: location
    additionalEnvVars: additionalEnvVars
    additionalSecrets: additionalSecrets.array
    additionalVolumesAndMounts: additionalVolumesAndMounts
    appDebug: appDebug
    appEnv: appEnv
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppsEnvironmentUseWorkloadProfiles: containerAppsEnvironmentUseWorkloadProfiles
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    containerRegistryName: containerRegistryName
    keyVaultName: keyVaultName
    databaseName: databaseName
    databasePasswordSecretNameInKeyVault: databasePasswordSecretName
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    provisionInit: provisionInit
    initContainerAppJobName: initContainerAppJobName
    initContainerAppJobImageName: initContainerAppJobImageName
    initContainerAppJobCpuCores: initContainerAppJobCpuCores
    initContainerAppJobMemory: initContainerAppJobMemory
    initContainerAppJobReplicaTimeoutSeconds: initContainerAppJobReplicaTimeoutSeconds
    initContainerAppJobRunPimcoreInstall: initContainerAppJobRunPimcoreInstall
    pimcoreAdminPasswordSecretName: pimcoreAdminPasswordSecretName
    phpContainerAppName: phpContainerAppName
    phpContainerAppCustomDomains: phpContainerAppCustomDomains
    phpContainerAppImageName: phpContainerAppImageName
    phpContainerAppCpuCores: phpContainerAppCpuCores
    phpContainerAppMemory: phpContainerAppMemory
    phpContainerAppExternal: phpContainerAppExternal
    phpContainerAppUseProbes: phpContainerAppUseProbes
    phpContainerAppMinReplicas: phpContainerAppMinReplicas
    phpContainerAppMaxReplicas: phpContainerAppMaxReplicas
    phpContainerAppIpSecurityRestrictions: phpContainerAppIpSecurityRestrictions
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisContainerAppName: redisContainerAppName
    redisDb: redisDb
    redisSessionDb: redisSessionDb
    redisContainerAppCpuCores: redisContainerAppCpuCores
    redisContainerAppMemory: redisContainerAppMemory
    redisContainerAppMaxMemorySetting: redisContainerAppMaxMemorySetting
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    supervisordContainerAppName: supervisordContainerAppName
    supervisordContainerAppImageName: supervisordContainerAppImageName
    supervisordContainerAppCpuCores: supervisordContainerAppCpuCores
    supervisordContainerAppMemory: supervisordContainerAppMemory
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName

    // Optional scaling rules
    phpContainerAppProvisionCronScaleRule: phpContainerAppProvisionCronScaleRule
    phpContainerAppCronScaleRuleDesiredReplicas: phpContainerAppCronScaleRuleDesiredReplicas
    phpContainerAppCronScaleRuleStartSchedule: phpContainerAppCronScaleRuleStartSchedule
    phpContainerAppCronScaleRuleEndSchedule: phpContainerAppCronScaleRuleEndSchedule
    phpContainerAppCronScaleRuleTimezone: phpContainerAppCronScaleRuleTimezone

    // Optional Portal Engine provisioning
    provisionForPortalEngine: provisionForPortalEngine
    portalEngineStorageAccountName: portalEngineStorageAccountName
    portalEngineStorageAccountDownloadsContainerName: portalEngineStorageAccountDownloadsContainerName
    portalEngineStorageAccountPublicBuildFileShareName: portalEngineStorageAccountPublicBuildFileShareName
    portalEnginePublicBuildStorageMountName: portalEngineStorageAccountPublicBuildStorageMountName

    // Optional n8n Container App (see more configuration below)
    provisionN8N: provisionN8N
    n8nContainerAppName: n8nContainerAppName
    n8nContainerAppCpuCores: n8nContainerAppCpuCores
    n8nContainerAppMemory: n8nContainerAppMemory
    n8nContainerAppMaxReplicas: n8nContainerAppMaxReplicas
    n8nContainerAppMinReplicas: n8nContainerAppMinReplicas
    n8nContainerAppCustomDomains: n8nContainerAppCustomDomains
    n8nContainerAppsEnvironmentStorageMountName: n8nContainerAppStorageMountName
    n8nDatabaseServerName: n8nDatabaseServerName
    n8nDatabaseName: n8nDatabaseName
    n8nDatabaseAdminUser: n8nDatabaseAdminUser
    n8nDatabaseAdminPasswordSecretName: n8nDatabaseAdminPasswordKeyVaultSecretName
    n8nStorageAccountName: n8nDataStorageAccountName
    n8nStorageAccountFileShareName: n8nDataStorageAccountFileShareName
    n8nContainerAppVolumeName: n8nContainerAppVolumeName
    n8nContainerAppProvisionCronScaleRule: n8nContainerAppProvisionCronScaleRule
    n8nContainerAppCronScaleRuleDesiredReplicas: n8nContainerAppCronScaleRuleDesiredReplicas
    n8nContainerAppCronScaleRuleEndSchedule: n8nContainerAppCronScaleRuleEndSchedule
    n8nContainerAppCronScaleRuleStartSchedule: n8nContainerAppCronScaleRuleStartSchedule
    n8nContainerAppCronScaleRuleTimezone: n8nContainerAppCronScaleRuleTimezone
  }
}

// Optional Portal Engine provisioning
param provisionForPortalEngine bool = false
param portalEngineStorageAccountName string = ''
param portalEngineStorageAccountAccessTier string = 'Hot'
param portalEngineStorageAccountKind string = 'StorageV2'
param portalEngineStorageAccountSku string = 'Standard_LRS'
param portalEngineStorageAccountDownloadsContainerName string = 'downloads'
param portalEngineStorageAccountPublicBuildFileShareName string = 'public-build'
param portalEngineStorageAccountPublicBuildFileShareAccessTier string = 'Hot'
param portalEngineStorageAccountPublicBuildStorageMountName string = 'portal-engine-public-build'
module portalEngineStorageAccount './portal-engine/portal-engine-storage-account.bicep' = if (provisionForPortalEngine) {
  name: 'portal-engine-storage-account'
  params: {
    storageAccountName: portalEngineStorageAccountName
    accessTier: portalEngineStorageAccountAccessTier
    kind: portalEngineStorageAccountKind
    sku: portalEngineStorageAccountSku
    downloadsContainerName: portalEngineStorageAccountDownloadsContainerName
    publicBuildFileShareName: portalEngineStorageAccountPublicBuildFileShareName
    publicBuildFileShareAccessTier: n8nDataStorageAccountFileShareAccessTier
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkName: virtualNetworkName
    virtualNetworkContainerAppsSubnetName: virtualNetworkContainerAppsSubnetName
  }
}

// Optional Virtual Machine for running side services
param provisionServicesVM bool = false
param servicesVmName string = ''
param servicesVmSubnetName string = 'services-vm'
param servicesVmSubnetAddressSpace string = '10.0.3.0/29'
param servicesVmAdminUsername string = 'azureuser'
param servicesVmPublicKeyKeyVaultSecretName string = 'services-vm-public-key'
param servicesVmSize string = 'Standard_B2s'
param servicesVmUbuntuOSVersion string = 'Ubuntu-2204'
param servicesVmFirewallIpsForSsh array = []
module servicesVm './services-virtual-machine/services-virtual-machine.bicep' = if (provisionServicesVM) {
  name: 'services-virtual-machine'
  dependsOn: [virtualNetwork]
  params: {
    name: servicesVmName
    adminPublicSshKey: keyVault.getSecret(servicesVmPublicKeyKeyVaultSecretName)
    adminUsername: servicesVmAdminUsername
    size: servicesVmSize
    ubuntuOSVersion: servicesVmUbuntuOSVersion
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: servicesVmSubnetName
    firewallIpsForSsh: !empty(localIpAddress) ? concat([localIpAddress], servicesVmFirewallIpsForSsh) : servicesVmFirewallIpsForSsh
  }
}

// Optional n8n provisioning
param provisionN8N bool = false
param n8nContainerAppName string = ''
param n8nContainerAppCpuCores string = '0.25'
param n8nContainerAppMemory string = '0.5Gi'
param n8nContainerAppCustomDomains array = []
param n8nContainerAppMinReplicas int = 1
param n8nContainerAppMaxReplicas int = 1
param n8nContainerAppProvisionCronScaleRule bool = false 
param n8nContainerAppCronScaleRuleDesiredReplicas int = 1
param n8nContainerAppCronScaleRuleTimezone string = 'Etc/UTC'
param n8nContainerAppCronScaleRuleStartSchedule string = '0 7 * * *'
param n8nContainerAppCronScaleRuleEndSchedule string = '0 18 * * *'
param n8nContainerAppStorageMountName string = 'n8n-data'
param n8nContainerAppVolumeName string = 'n8n-data'
param n8nDataStorageAccountName string = ''
param n8nDataStorageAccountAccessTier string = 'Hot'
param n8nDataStorageAccountKind string = 'StorageV2'
param n8nDataStorageAccountSku string = 'Standard_LRS'
param n8nDataStorageAccountFileShareName string = 'n8n-data'
param n8nDataStorageAccountFileShareAccessTier string = 'Hot'
param n8nDatabaseServerName string = ''
param n8nDatabaseName string = 'n8n'
param n8nDatabaseAdminUser string = 'adminuser'
param n8nDatabaseAdminPasswordKeyVaultSecretName string = 'n8n-db-password'
param n8nDatabaseSkuName string = 'Standard_B1ms'
param n8nDatabaseSkuTier string = 'Burstable'
param n8nDatabaseStorageSizeGB int = 32
param n8nDatabaseBackupRetentionDays int = 7
param n8nVirtualNetworkDatabaseSubnetName string = 'postgres'
param n8nVirtualNetworkDatabaseSubnetAddressSpace string = '10.0.4.0/28'
module n8n './n8n/n8n.bicep' = if (provisionN8N) {
  name: 'n8n'
  dependsOn: [virtualNetwork]
  params: {
    // Note that the n8n Container App is provisioned above as part of the containerApps module
    databaseAdminPassword: keyVault.getSecret(n8nDatabaseAdminPasswordKeyVaultSecretName)
    databaseAdminUser: n8nDatabaseAdminUser
    databaseServerName: n8nDatabaseServerName
    databaseName: n8nDatabaseName
    databaseSkuName: n8nDatabaseSkuName
    databaseSkuTier: n8nDatabaseSkuTier
    databaseStorageSizeGB: n8nDatabaseStorageSizeGB
    databaseBackupRetentionDays: n8nDatabaseBackupRetentionDays
    storageAccountName: n8nDataStorageAccountName
    storageAccountKind: n8nDataStorageAccountKind
    storageAccountSku: n8nDataStorageAccountSku
    storageAccountAccessTier: n8nDataStorageAccountAccessTier
    storageAccountFileShareName: n8nDataStorageAccountFileShareName
    storageAccountFileShareAccessTier: n8nDataStorageAccountFileShareAccessTier
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkContainerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkDatabaseSubnetName: n8nVirtualNetworkDatabaseSubnetName
  }
}

// We use a single parameters.json file for multiple Bicep files and scripts, but Bicep
// will complain if we use it on a file that doesn't actually use all of the parameters.
// Therefore, we declare the extra params here.  If https://github.com/Azure/bicep/issues/5771 
// is ever fixed, these can be removed.
param subscriptionId string = ''
param resourceGroupName string = ''
param tenantId string = ''
param servicePrincipalName string = ''
param containerRegistrySku string = ''
param keyVaultGenerateRandomSecrets bool = false
param localIpAddress string = ''
param provisionServicePrincipal bool = true
// DEPRECATED parameters
param databasePublicNetworkAccess bool = false
param waitForKeyVaultManualIntervention bool = false
