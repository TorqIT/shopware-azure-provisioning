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
param virtualNetworkContainerAppsSubnetName string = 'container-apps'
param virtualNetworkContainerAppsSubnetAddressSpace string = '10.0.0.0/23'
param virtualNetworkDatabaseSubnetName string = 'database'
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

// Backup Vault
param backupVaultName string = ''
module backupVault 'backup-vault/backup-vault.bicep' = if (databaseLongTermBackups/* || storageAccountLongTermBackups*/) {
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
param storageAccountPublicContainerName string = 'public'
param storageAccountPrivateContainerName string = 'private'
param storageAccountFirewallIps array = []
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
    publicContainerName: storageAccountPublicContainerName
    privateContainerName: storageAccountPrivateContainerName
    accessTier: storageAccountAccessTier
    kind: storageAccountKind
    sku: storageAccountSku
    firewallIps: storageAccountFirewallIps
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
param databaseAdminPasswordSecretName string = 'database-admin-password'
param databaseSkuName string = 'Standard_B1ms'
param databaseSkuTier string = 'Burstable'
param databaseStorageSizeGB int = 20
param databaseName string = 'shopware'
param databaseBackupRetentionDays int = 7
param databaseGeoRedundantBackup bool = false
param databaseLongTermBackups bool = true
module database 'database/database.bicep' = {
  name: 'database'
  dependsOn: [virtualNetwork, privateDnsZones, backupVault]
  params: {
    location: location
    administratorLogin: databaseAdminUsername
    administratorPassword: keyVault.getSecret(databaseAdminPasswordSecretName)
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
param shopwareInitContainerAppJobName string = ''
param shopwareInitImageName string
param shopwareInitContainerAppJobCpuCores string = '0.5'
param shopwareInitContainerAppJobMemory string = '1Gi'
param shopwareWebContainerAppExternal bool = true
param shopwareWebContainerAppName string
param shopwareWebImageName string
param shopwareWebContainerAppCustomDomains array = []
param shopwareWebContainerAppCpuCores string = '1.0'
param shopwareWebContainerAppMemory string = '2Gi'
param shopwareWebContainerAppMinReplicas int = 1
param shopwareWebContainerAppMaxReplicas int = 1
@allowed(['dev', 'prod'])
param appEnv string
param appUrl string
param additionalEnvVars array = []
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  dependsOn: [virtualNetwork, containerRegistry, storageAccount, database, logAnalyticsWorkspace]
  params: {
    location: location
    additionalEnvVars: additionalEnvVars
    containerAppsEnvironmentName: containerAppsEnvironmentName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    containerRegistryName: containerRegistryName
    shopwareInitContainerAppJobName: shopwareInitContainerAppJobName
    shopwareInitImageName: shopwareInitImageName
    shopwareInitContainerAppJobCpuCores: shopwareInitContainerAppJobCpuCores
    shopwareInitContainerAppJobMemory: shopwareInitContainerAppJobMemory
    shopwareWebContainerAppName: shopwareWebContainerAppName
    shopwareWebContainerAppCustomDomains: shopwareWebContainerAppCustomDomains
    shopwareWebImageName: shopwareWebImageName
    shopwareWebContainerAppCpuCores: shopwareWebContainerAppCpuCores
    shopwareWebContainerAppMemory: shopwareWebContainerAppMemory
    shopwareWebContainerAppExternal: shopwareWebContainerAppExternal
    shopwareWebContainerAppMinReplicas: shopwareWebContainerAppMinReplicas
    shopwareWebContainerAppMaxReplicas: shopwareWebContainerAppMaxReplicas
    appEnv: appEnv
    appUrl: appUrl
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
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
