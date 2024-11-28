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
param virtualNetworkContainerAppsSubnetName string = 'container-apps'
param virtualNetworkContainerAppsSubnetAddressSpace string = '10.0.0.0/23'
param virtualNetworkDatabaseSubnetName string = 'database'
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
  }
}

// Key Vault
param keyVaultName string
// If set to a value other than the Resource Group used for the rest of the resources, the Key Vault will be assumed to already exist in that Resource Group
param keyVaultResourceGroupName string = resourceGroup().name
module keyVaultModule './key-vault/key-vault.bicep' = if (keyVaultResourceGroupName == resourceGroup().name) {
  name: 'key-vault'
  dependsOn: [virtualNetwork]
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    name: keyVaultName
    localIpAddress: localIpAddress
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkName: virtualNetworkName
    virtualNetworkContainerAppsSubnetName: virtualNetworkContainerAppsSubnetName
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
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
param storageAccountLongTermBackupRetentionPeriod string = 'P365D'
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
    firewallIps: concat([localIpAddress], storageAccountFirewallIps)
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

// Database
param databaseServerName string
param databaseAdminUsername string = 'adminuser'
param databaseAdminPasswordSecretName string = 'database-admin-password'
param databaseSkuName string = 'Standard_B1ms'
param databaseSkuTier string = 'Burstable'
param databaseStorageSizeGB int = 20
param databaseName string = 'pimcore'
param databaseBackupRetentionDays int = 7 //deprecated in favor of renamed param below
param databaseShortTermBackupRetentionDays int = databaseBackupRetentionDays
param databaseGeoRedundantBackup bool = false
param databaseLongTermBackups bool = true
param databaseLongTermBackupRetentionPeriod string = 'P365D'
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
    shortTermBackupRetentionDays: databaseBackupRetentionDays
    geoRedundantBackup: databaseGeoRedundantBackup
    backupVaultName: backupVaultName
    longTermBackups: databaseLongTermBackups
    longTermBackupRetentionPeriod: databaseLongTermBackupRetentionPeriod
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
param containerAppsEnvironmentUseWorkloadProfiles bool = false
// Deprecated param names (starting with "shopware")
param shopwareInitContainerAppJobName string = ''
param shopwareInitImageName string
param shopwareInitContainerAppJobCpuCores string = '0.5'
param shopwareInitContainerAppJobMemory string = '1Gi'
param shopwareInitContainerAppJobReplicaTimeoutSeconds int = 600
param shopwareWebContainerAppExternal bool = true
param shopwareWebContainerAppName string
param shopwareWebImageName string
param shopwareWebContainerAppCustomDomains array = []
param shopwareWebContainerAppCpuCores string = '1.0'
param shopwareWebContainerAppMemory string = '2Gi'
param shopwareWebContainerAppMinReplicas int = 1
param shopwareWebContainerAppMaxReplicas int = 1
param shopwareWebContainerAppInternalPort int = 80
// Preferred param names
param initContainerAppJobName string = shopwareInitContainerAppJobName
param initContainerAppJobImageName string = shopwareInitImageName
param initContainerAppJobCpuCores string = shopwareInitContainerAppJobCpuCores
param initContainerAppJobMemory string = shopwareInitContainerAppJobMemory
param initContainerAppJobReplicaTimeoutSeconds int = shopwareInitContainerAppJobReplicaTimeoutSeconds
param phpContainerAppExternal bool = shopwareWebContainerAppExternal
param phpContainerAppName string = shopwareWebContainerAppName
param phpContainerAppImageName string = shopwareWebImageName
param phpContainerAppCustomDomains array = shopwareWebContainerAppCustomDomains
param phpContainerAppCpuCores string = shopwareWebContainerAppCpuCores
param phpContainerAppMemory string = shopwareWebContainerAppMemory
param phpContainerAppMinReplicas int = shopwareWebContainerAppMinReplicas
param phpContainerAppMaxReplicas int = shopwareWebContainerAppMaxReplicas
param phpContainerAppIpSecurityRestrictions array = []
param phpContainerAppInternalPort int = shopwareWebContainerAppInternalPort
// Optional scale rules
param phpContainerAppProvisionCronScaleRule bool = false
param phpContainerAppCronScaleRuleDesiredReplicas int = 0
param phpContainerAppCronScaleRuleStartSchedule string = ''
param phpContainerAppCronScaleRuleEndSchedule string = ''
param phpContainerAppCronScaleRuleTimezone string = ''
param supervisordContainerAppName string 
param supervisordContainerAppImageName string
param supervisordContainerAppCpuCores string = '0.25'
param supervisordContainerAppMemory string = '0.5Gi'
@allowed(['dev', 'prod'])
param appEnv string
param appUrl string
param appSecretSecretName string = 'app-secret'
param appInstallCategoryId string = ''
param appInstallCurrency string = 'CAD'
param appInstallLocale string = 'en-CA'
param appSalesChannelName string = 'Storefront'
param enableOpensearch bool = false
// By default assume that Opensearch is provisioned on the Services VM (below) on port 9200
param opensearchUrl string = 'services-vm:9200'
param additionalEnvVars array = []
// TODO no need for this to be an object anymore, it could be an array
param additionalSecrets object = {}
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  dependsOn: [virtualNetwork, containerRegistry, logAnalyticsWorkspace, storageAccount, database]
  params: {
    location: location
    additionalEnvVars: additionalEnvVars
    additionalSecrets: additionalSecrets.array
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerAppsEnvironmentUseWorkloadProfiles: containerAppsEnvironmentUseWorkloadProfiles
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    containerRegistryName: containerRegistryName
    initContainerAppJobName: initContainerAppJobName
    initContainerAppJobImageName: initContainerAppJobImageName
    initContainerAppJobCpuCores: initContainerAppJobCpuCores
    initContainerAppJobMemory: initContainerAppJobMemory
    initContainerAppJobReplicaTimeoutSeconds: initContainerAppJobReplicaTimeoutSeconds
    phpContainerAppName: phpContainerAppName
    phpContainerAppCustomDomains: phpContainerAppCustomDomains
    phpContainerAppImageName: phpContainerAppImageName
    phpContainerAppCpuCores: phpContainerAppCpuCores
    phpContainerAppMemory: phpContainerAppMemory
    phpContainerAppExternal: phpContainerAppExternal
    phpContainerAppMinReplicas: phpContainerAppMinReplicas
    phpContainerAppMaxReplicas: phpContainerAppMaxReplicas
    phpContainerAppIpSecurityRestrictions: phpContainerAppIpSecurityRestrictions
    phpContainerAppInternalPort: phpContainerAppInternalPort
    phpContainerAppProvisionCronScaleRule: phpContainerAppProvisionCronScaleRule
    phpContainerAppCronScaleRuleDesiredReplicas: phpContainerAppCronScaleRuleDesiredReplicas
    phpContainerAppCronScaleRuleStartSchedule: phpContainerAppCronScaleRuleStartSchedule
    phpContainerAppCronScaleRuleEndSchedule: phpContainerAppCronScaleRuleEndSchedule
    phpContainerAppCronScaleRuleTimezone: phpContainerAppCronScaleRuleTimezone
    supervisordContainerAppName: supervisordContainerAppName
    supervisordContainerAppImageName: supervisordContainerAppImageName
    supervisordContainerAppCpuCores: supervisordContainerAppCpuCores
    supervisordContainerAppMemory: supervisordContainerAppMemory
    appEnv: appEnv
    appUrl: appUrl
    appSecret: keyVault.getSecret(appSecretSecretName)
    appInstallCategoryId: appInstallCategoryId
    appInstallCurrency: appInstallCurrency
    appInstallLocale: appInstallLocale
    appSalesChannelName: appSalesChannelName
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkContainerAppsSubnetName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
    keyVaultName: keyVaultName
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    databasePasswordSecretNameInKeyVault: databaseAdminPasswordSecretName
    databaseName: databaseName
    storageAccountName: storageAccountName
    storageAccountPublicContainerName: storageAccountPublicContainerName
    enableOpensearch: enableOpensearch
    opensearchUrl: opensearchUrl
  }
}

// Optional Virtual Machine for running side services (e.g. Opensearch)
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
    firewallIpsForSsh: concat([localIpAddress], servicesVmFirewallIpsForSsh)
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
param waitForKeyVaultManualIntervention bool = false
param localIpAddress string = ''
param provisionServicePrincipal bool = true
