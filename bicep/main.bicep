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

// Backup Vault
// TODO remove once all clients are moved over to use this model - relic of previously using the Backup Vault for Storage Accounts only
param storageAccountBackupVaultName string = '${storageAccountName}-backup-vault'
param backupVaultName string = storageAccountBackupVaultName
module backupVault 'backup-vault/backup-vault.bicep' = if (databaseLongTermBackups || storageAccountLongTermBackups) {
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
module storageAccount 'storage-account/storage-account.bicep' = {
  name: 'storage-account'
  dependsOn: [virtualNetwork, privateDnsZones, backupVault]
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
param databaseLongTermBackups bool = true
module database 'database/database.bicep' = {
  name: 'database'
  dependsOn: [virtualNetwork, privateDnsZones, backupVault]
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
    backupVaultName: backupVaultName
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
param initContainerAppJobReplicaTimeoutSeconds int = 600
param initContainerAppJobRunPimcoreInstall bool = false
param pimcoreAdminPasswordSecretName string = 'pimcore-admin-password'
param phpFpmContainerAppExternal bool = true
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool = false
param phpFpmContainerAppCustomDomains array = []
param phpFpmCpuCores string = '0.5'
param phpFpmMemory string = '1Gi'
param phpFpmScaleToZero bool = false
param phpFpmMaxReplicas int = 1
param supervisordContainerAppName string
param supervisordImageName string
param supervisordCpuCores string = '0.25'
param supervisordMemory string = '0.5Gi'
param redisContainerAppName string
param redisCpuCores string = '0.25'
param redisMemory string = '0.5Gi'
@allowed(['0', '1'])
param appDebug string
param appEnv string
@allowed(['0', '1'])
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisSessionDb string
param additionalEnvVars array = []
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
    initContainerAppJobReplicaTimeoutSeconds: initContainerAppJobReplicaTimeoutSeconds
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
    redisSessionDb: redisSessionDb
    redisCpuCores: redisCpuCores
    redisMemory: redisMemory
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    supervisordContainerAppName: supervisordContainerAppName
    supervisordImageName: supervisordImageName
    supervisordCpuCores: supervisordCpuCores
    supervisordMemory: supervisordMemory
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
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
  }
}

// Optional n8n provisioning
param provisionN8N bool = false
param n8nContainerAppName string = ''
param n8nContainerAppCpuCores string = '0.25'
param n8nContainerAppMemory string = '0.5Gi'
param n8nContainerAppCustomDomains array = []
param n8nContainerAppMinReplicas int = 0
param n8nContainerAppMaxReplicas int = 1
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
  dependsOn: [containerApps]
  params: {
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppsEnvironmentStorageMountName: n8nContainerAppStorageMountName
    databaseAdminPassword: keyVault.getSecret(n8nDatabaseAdminPasswordKeyVaultSecretName)
    databaseAdminUser: n8nDatabaseAdminUser
    databaseServerName: n8nDatabaseServerName
    databaseName: n8nDatabaseName
    databaseSkuName: n8nDatabaseSkuName
    databaseSkuTier: n8nDatabaseSkuTier
    databaseStorageSizeGB: n8nDatabaseStorageSizeGB
    databaseBackupRetentionDays: n8nDatabaseBackupRetentionDays
    n8nContainerAppCpuCores: n8nContainerAppCpuCores
    n8nContainerAppCustomDomains: n8nContainerAppCustomDomains
    n8nContainerAppMaxReplicas: n8nContainerAppMaxReplicas
    n8nContainerAppMemory: n8nContainerAppMemory
    n8nContainerAppMinReplicas: n8nContainerAppMinReplicas
    n8nContainerAppName: n8nContainerAppName
    n8nContainerAppVolumeName: n8nContainerAppVolumeName
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
param tenantName string = '' //deprecated
param tenantId string = ''
param servicePrincipalName string = ''
param deployImagesToContainerRegistry bool = false //deprecated
param additionalSecrets object = {}
param containerRegistrySku string = ''
param waitForKeyVaultManualIntervention bool = false
param redisImageName string = '' //deprecated
