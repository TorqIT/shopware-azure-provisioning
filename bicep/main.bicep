param location string = resourceGroup().location

param containerRegistryName string

// Key Vault (assumed to have been created prior to this)
param keyVaultName string
param keyVaultResourceGroupName string = resourceGroup().name
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

// Virtual Network
param virtualNetworkName string
param virtualNetworkAddressSpace string = '10.0.0.0/16'
// If set to a value other than the Resource Group used for the rest of the resources, the VNet will be assumed to already exist
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkContainerAppsSubnetName string = 'pimcore-container-apps'
param virtualNetworkContainerAppsSubnetAddressSpace string = '10.0.0.0/23'
param virtualNetworkDatabaseSubnetName string = 'pimcore-database'
param virtualNetworkDatabaseSubnetAddressSpace string = '10.0.2.0/28'
// As both Storage Accounts are primarily accessed by the Container Apps, we simply place their Private Endpoints in the same
// subnet by default. Some clients prefer to place the Endpoints in their own Resource Group. 
param virtualNetworkPrivateEndpointsSubnetName string = virtualNetworkContainerAppsSubnetName
module virtualNetwork 'virtual-network/virtual-network.bicep' = if (virtualNetworkResourceGroupName == resourceGroup().name) {
  name: 'virtual-network'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    containerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    containerAppsSubnetAddressSpace:  virtualNetworkContainerAppsSubnetAddressSpace
    databaseSubnetAddressSpace: virtualNetworkDatabaseSubnetAddressSpace
    databaseSubnetName: virtualNetworkDatabaseSubnetName
  }
}

param privateDnsZonesSubscriptionId string = subscription().id
param privateDnsZonesResourceGroupName string = resourceGroup().name
param privateDnsZoneForDatabaseName string = '${databaseServerName}.private.mysql.database.azure.com'
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
param storageAccountBackupVaultName string = '${storageAccountName}-backup-vault'
param storageAccountLongTermBackups bool = true
module storageAccount 'storage-account/storage-account.bicep' = {
  name: 'storage-account'
  dependsOn: [virtualNetwork, privateDnsZones]
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
    backupVaultName: storageAccountBackupVaultName
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
param databaseBackupRetentionDays int = 7
param databaseGeoRedundantBackup bool = false
param databaseBackupsStorageAccountName string = '${databaseServerName}-backups-storage-account'
param databaseBackupsStorageAccountContainerName string = 'database-backups'
param databaseBackupsStorageAccountSku string = 'Standard_LRS'
param databaseBackupsStorageAccountPrivateEndpointName string = '${databaseBackupsStorageAccountName}-private-endpoint'
param databaseBackupsStorageAccountPrivateEndpointNicName string = ''
param databaseLongTermBackups bool = true
module database 'database/database.bicep' = {
  name: 'database'
  dependsOn: [virtualNetwork, privateDnsZones]
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
    virtualNetworkDatabaseSubnetName: virtualNetworkDatabaseSubnetName
    virtualNetworkStorageAccountPrivateEndpointSubnetName: virtualNetworkPrivateEndpointsSubnetName
    backupRetentionDays: databaseBackupRetentionDays
    geoRedundantBackup: databaseGeoRedundantBackup
    longTermBackups: databaseLongTermBackups
    databaseBackupsStorageAccountName: databaseBackupsStorageAccountName
    databaseBackupStorageAccountContainerName: databaseBackupsStorageAccountContainerName
    databaseBackupsStorageAccountSku: databaseBackupsStorageAccountSku
    databaseBackupsStorageAccountPrivateEndpointName: databaseBackupsStorageAccountPrivateEndpointName
    databaseBackupsStorageAccountPrivateEndpointNicName: databaseBackupsStorageAccountPrivateEndpointNicName
    privateDnsZoneForDatabaseId: privateDnsZones.outputs.zoneIdForDatabase
    privateDnsZoneForStorageAccountsId: privateDnsZones.outputs.zoneIdForStorageAccounts
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
// TODO for now, this is optional, but will eventually be a mandatory part of Container App infrastructure
param provisionInit bool = false
param initContainerAppJobName string = ''
param initImageName string = ''
param initCpuCores string = '0.5'
param initMemory string = '1Gi'
param initContainerAppJobRunPimcoreInstall bool = false
param pimcoreAdminPasswordSecretName string = 'pimcore-admin-password'
param phpFpmContainerAppExternal bool = true
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool = false
param phpFpmContainerAppCustomDomains array = []
param phpFpmCpuCores string = '1.0'
param phpFpmMemory string = '2Gi'
param phpFpmScaleToZero bool = false
param phpFpmMaxReplicas int = 1
param supervisordContainerAppName string
param supervisordImageName string
param supervisordCpuCores string = '0.25'
param supervisordMemory string = '250Mi'
param redisContainerAppName string
param redisImageName string
param redisCpuCores string = '0.25'
param redisMemory string = '1Gi'
@allowed(['0', '1'])
param appDebug string
param appEnv string
@allowed(['0', '1'])
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisSessionDb string
param additionalEnvVars array = []
param provisionElasticsearch bool = false
param elasticsearchContainerAppName string = ''
param elasticsearchCpuCores string = ''
param elasticsearchMemory string = ''
param elasticsearchNodeName string = ''
param provisionOpenSearch bool = false
param openSearchContainerAppName string = ''
param openSearchCpuCores string = ''
param openSearchMemory string = ''
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  dependsOn: [virtualNetwork, containerRegistry, storageAccount, database, logAnalyticsWorkspace]
  params: {
    location: location
    additionalEnvVars: additionalEnvVars
    appDebug: appDebug
    appEnv: appEnv
    containerAppsEnvironmentName: containerAppsEnvironmentName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    containerRegistryName: containerRegistryName
    databaseName: databaseName
    databasePassword: keyVault.getSecret(databasePasswordSecretName)
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    provisionInit: provisionInit
    initContainerAppJobName: initContainerAppJobName
    initContainerAppJobImageName: initImageName
    initContainerAppJobCpuCores: initCpuCores
    initContainerAppJobMemory: initMemory
    initContainerAppJobRunPimcoreInstall: initContainerAppJobRunPimcoreInstall
    pimcoreAdminPassword: provisionInit ? keyVault.getSecret(pimcoreAdminPasswordSecretName) : ''
    phpFpmContainerAppName: phpFpmContainerAppName
    phpFpmContainerAppCustomDomains: phpFpmContainerAppCustomDomains
    phpFpmImageName: phpFpmImageName
    phpFpmCpuCores: phpFpmCpuCores
    phpFpmMemory: phpFpmMemory
    phpFpmContainerAppExternal: phpFpmContainerAppExternal
    phpFpmContainerAppUseProbes: phpFpmContainerAppUseProbes
    phpFpmScaleToZero: phpFpmScaleToZero
    phpFpmMaxReplicas: phpFpmMaxReplicas
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisContainerAppName: redisContainerAppName
    redisDb: redisDb
    redisImageName: redisImageName
    redisSessionDb: redisSessionDb
    redisCpuCores: redisCpuCores
    redisMemory: redisMemory
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    databaseLongTermBackups: databaseLongTermBackups
    databaseBackupsStorageAccountName: databaseBackupsStorageAccountName
    databaseBackupsStorageAccountContainerName: databaseBackupsStorageAccountContainerName
    supervisordContainerAppName: supervisordContainerAppName
    supervisordImageName: supervisordImageName
    supervisordCpuCores: supervisordCpuCores
    supervisordMemory: supervisordMemory
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
    provisionElasticsearch: provisionElasticsearch
    elasticsearchContainerAppName: elasticsearchContainerAppName
    elasticsearchCpuCores: elasticsearchCpuCores
    elasticsearchMemory: elasticsearchMemory
    elasticsearchNodeName: elasticsearchNodeName
    provisionOpenSearch: provisionOpenSearch
    openSearchContainerAppName: openSearchContainerAppName
    openSearchCpuCores: openSearchCpuCores
    openSearchMemory: openSearchMemory
  }
}

// We use a single parameters.json file for multiple Bicep files and scripts, but Bicep
// will complain if we use it on a file that doesn't actually use all of the parameters.
// Therefore, we declare the extra params here.  If https://github.com/Azure/bicep/issues/5771 
// is ever fixed, these can be removed.
param subscriptionId string = ''
param resourceGroupName string = ''
param tenantName string = ''
param servicePrincipalName string = ''
param deployImagesToContainerRegistry bool = false
param additionalSecrets object = {}
param containerRegistrySku string = ''
param waitForKeyVaultManualIntervention bool = false
