param location string = resourceGroup().location

param containerRegistryName string

// Key Vault (assumed to have been created prior to this)
param keyVaultName string
resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: keyVaultName
}

// Virtual Network
param virtualNetworkName string
param virtualNetworkAddressSpace string
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkContainerAppsSubnetName string = 'container-apps-subnet'
param virtualNetworkContainerAppsSubnetAddressSpace string
param virtualNetworkDatabaseSubnetName string = 'database-subnet'
param virtualNetworkDatabaseSubnetAddressSpace string
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

// Storage Account
param storageAccountName string
param storageAccountSku string = 'Standard_LRS'
param storageAccountKind string = 'StorageV2'
param storageAccountAccessTier string = 'Hot'
param storageAccountContainerName string
param storageAccountAssetsContainerName string
param storageAccountCdnAccess bool = false
param storageAccountBackupRetentionDays int = 7
module storageAccount 'storage-account/storage-account.bicep' = {
  name: 'storage-account'
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: storageAccountContainerName
    assetsContainerName: storageAccountAssetsContainerName
    accessTier: storageAccountAccessTier
    kind: storageAccountKind
    sku: storageAccountSku
    cdnAssetAccess: storageAccountCdnAccess
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
    backupRetentionDays: storageAccountBackupRetentionDays
  }
}

// Database
param databaseServerName string
param databaseAdminUsername string = 'adminuser'
param databasePasswordSecretName string
param databaseSkuName string = 'Standard_B1ms'
param databaseSkuTier string = 'Burstable'
param databaseStorageSizeGB int = 20
param databaseName string = 'pimcore'
@description('Number of days to keep point-in-time backups of the database. Valid values are 1 through 35')
param databaseBackupRetentionDays int = 7
param databaseGeoRedundantBackup bool = false
module database 'database/database.bicep' = {
  name: 'database'
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
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
    virtualNetworkSubnetName: virtualNetworkDatabaseSubnetName
    backupRetentionDays: databaseBackupRetentionDays
    geoRedundantBackup: databaseGeoRedundantBackup
  }
}

// Container Apps
param containerAppsEnvironmentName string
param phpFpmContainerAppExternal bool = true
param phpFpmContainerAppName string
param phpFpmImageName string
param phpFpmContainerAppUseProbes bool = false
param supervisordContainerAppName string
param supervisordImageName string
param redisContainerAppName string
param redisImageName string
@allowed(['0', '1'])
param appDebug string = '0'
param appEnv string = 'dev'
@allowed(['0', '1'])
param pimcoreDev string = '1'
param pimcoreEnvironment string = 'dev'
param redisDb string = '12'
param redisSessionDb string = '14'
param additionalEnvVars array = []
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    location: location
    additionalEnvVars: additionalEnvVars
    appDebug: appDebug
    appEnv: appEnv
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    databaseName: databaseName
    databasePassword: keyVault.getSecret(databasePasswordSecretName)
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    phpFpmContainerAppName: phpFpmContainerAppName
    phpFpmImageName: phpFpmImageName
    pimcoreDev: pimcoreDev
    pimcoreEnvironment: pimcoreEnvironment
    redisContainerAppName: redisContainerAppName
    redisDb: redisDb
    redisImageName: redisImageName
    redisSessionDb: redisSessionDb
    storageAccountAssetsContainerName: storageAccountAssetsContainerName
    storageAccountContainerName: storageAccountContainerName
    storageAccountName: storageAccountName
    supervisordContainerAppName: supervisordContainerAppName
    supervisordImageName: supervisordImageName
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    phpFpmContainerAppExternal: phpFpmContainerAppExternal
    phpFpmContainerAppUseProbes: phpFpmContainerAppUseProbes
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
param deployImagesToContainerRegistry bool = false
param additionalSecrets object = {}
param containerRegistrySku string = ''
