param location string = resourceGroup().location

param containerRegistryName string

// Key Vault
param keyVaultName string
// If set to a value other than the Resource Group used for the rest of the resources, the Key Vault will be assumed to already exist in that Resource Group
param keyVaultResourceGroupName string = resourceGroup().name
module keyVaultModule './key-vault/key-vault.bicep' = if (keyVaultResourceGroupName == resourceGroup().name) {
  name: 'key-vault'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    name: keyVaultName
    localIpAddress: localIpAddress
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

// Virtual Network
param virtualNetworkName string
param virtualNetworkAddressSpace string = '10.0.0.0/16'
// If set to a value other than the Resource Group used for the rest of the resources, the VNet will be assumed to already exist in that Resource Group
param virtualNetworkResourceGroupName string = resourceGroup().name
param virtualNetworkDefaultSubnetName string = 'default'
param virtualNetworkDefaultSubnetAddressSpace string = '10.0.0.0/24'
param virtualNetworkContainerAppsSubnetName string = 'container-apps'
param virtualNetworkContainerAppsSubnetAddressSpace string = '10.0.2.0/23'
param virtualNetworkDatabaseSubnetName string = 'database'
param virtualNetworkDatabaseSubnetAddressSpace string = '10.0.4.0/28'
// Optional provisioning of NAT Gateway for static outbound IP address for Container Apps Environment
param provisionStaticOutboundIp bool = false
param natGatewayName string = '${resourceGroupName}-nat-gateway'
param natGatewayPublicIpName string = '${containerAppsEnvironmentName}-outbound-ip'
param natGatewayPublicIpSku string = 'Standard'
module virtualNetwork 'virtual-network/virtual-network.bicep' = if (virtualNetworkResourceGroupName == resourceGroup().name) {
  name: 'virtual-network'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    defaultSubnetName: virtualNetworkDefaultSubnetName
    defaultSubnetAddressSpace: virtualNetworkDefaultSubnetAddressSpace
    containerAppsSubnetName: virtualNetworkContainerAppsSubnetName
    containerAppsSubnetAddressSpace:  virtualNetworkContainerAppsSubnetAddressSpace
    databaseSubnetAddressSpace: virtualNetworkDatabaseSubnetAddressSpace
    databaseSubnetName: virtualNetworkDatabaseSubnetName
    // Optional NAT Gateway provisioning for static outbound IP
    provisionStaticOutboundIp: provisionStaticOutboundIp
    natGatewayName: natGatewayName
    natGatewayPublicIpName: natGatewayPublicIpName
    natGatewayPublicIpSku: natGatewayPublicIpSku
    // Optional services VM provisioning (see configuration below)
    provisionServicesVM: provisionServicesVM
    servicesVmSubnetName: servicesVmSubnetName
    servicesVmSubnetAddressSpace: servicesVmSubnetAddressSpace
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
    firewallIps: concat([localIpAddress], storageAccountFirewallIps)
    virtualNetworkName: virtualNetworkName
    virtualNetworkPrivateEndpointSubnetName: virtualNetworkDefaultSubnetName
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
    backupRetentionDays: databaseBackupRetentionDays
    geoRedundantBackup: databaseGeoRedundantBackup
    longTermBackups: databaseLongTermBackups
    backupVaultName: backupVaultName
    privateDnsZoneForDatabaseId: privateDnsZones.outputs.zoneIdForDatabase
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
module containerApps 'container-apps/container-apps.bicep' = {
  name: 'container-apps'
  dependsOn: [virtualNetwork, containerRegistry, logAnalyticsWorkspace, storageAccount, database]
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
    shopwareInitContainerAppJobReplicaTimeoutSeconds: shopwareInitContainerAppJobReplicaTimeoutSeconds
    shopwareWebContainerAppName: shopwareWebContainerAppName
    shopwareWebContainerAppCustomDomains: shopwareWebContainerAppCustomDomains
    shopwareWebImageName: shopwareWebImageName
    shopwareWebContainerAppCpuCores: shopwareWebContainerAppCpuCores
    shopwareWebContainerAppMemory: shopwareWebContainerAppMemory
    shopwareWebContainerAppExternal: shopwareWebContainerAppExternal
    shopwareWebContainerAppMinReplicas: shopwareWebContainerAppMinReplicas
    shopwareWebContainerAppMaxReplicas: shopwareWebContainerAppMaxReplicas
    shopwareWebContainerAppInternalPort: shopwareWebContainerAppInternalPort
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
    databaseServerName: databaseServerName
    databaseUser: databaseAdminUsername
    databasePassword: keyVault.getSecret(databaseAdminPasswordSecretName)
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
param servicesVmSubnetAddressSpace string = '10.0.5.0/29'
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
param additionalSecrets object = {}
param containerRegistrySku string = ''
param waitForKeyVaultManualIntervention bool = false
param localIpAddress string = ''
param provisionServicePrincipal bool = true
