param appEnv string
param appDebug string
param appUrl string
param appSecretSecretRefName string
param appInstallCurrency string
param appInstallCreateCAD bool
param appSalesChannelName string
param appSalesChannelId string
param appSalesChannelCurrencyId string
param appSalesChannelCountryIso string
param appSalesChannelSnippetsetId string
param azureCdnUrl string

param enableOpensearch bool
param opensearchUrl string

param storageAccountName string
param storageAccountPublicContainerName string
param storageAccountPrivateContainerName string
param storageAccountKeySecretRefName string

param databaseServerName string
param databaseServerVersion string
param databaseName string
param databaseUser string
param databaseUrlSecretRefName string

param additionalVars array

var defaultEnvVars = [
  {
    name: 'APP_ENV'
    value: appEnv
  }
  {
    name: 'APP_DEBUG'
    value: appDebug
  }
  {
    name: 'APP_URL'
    value: appUrl
  }
  {
    name: 'APP_SECRET'
    secretRef: appSecretSecretRefName
  }
  {
    name: 'APP_INSTALL_CURRENCY'
    value: appInstallCurrency
  }
  {
    name: 'APP_INSTALL_CREATE_CAD'
    value: string(appInstallCreateCAD)
  }
  {
    name: 'APP_SALESCHANNEL_NAME'
    value: appSalesChannelName
  }
  {
    name: 'APP_SALESCHANNEL_ID'
    value: appSalesChannelId
  }
  {
    name: 'APP_SALESCHANNEL_CURRENCY_ID'
    value: appSalesChannelCurrencyId
  }
  {
    name: 'APP_SALESCHANNEL_COUNTRY_ISO'
    value: appSalesChannelCountryIso
  }
  {
    name: 'APP_SALESCHANNEL_SNIPPETSET_ID'
    value: appSalesChannelSnippetsetId
  }
  {
    name: 'DATABASE_URL'
    secretRef: databaseUrlSecretRefName
  }
  {
    name: 'DATABASE_HOST'
    value: '${databaseServerName}.mysql.database.azure.com'
  }
  {
    name: 'DATABASE_PORT'
    value: '3306'
  }
  {
    name: 'DATABASE_USER'
    value: databaseUser
  }
  {
    name: 'DATABASE_NAME'
    value: databaseName
  }
  // TODO DATABASE_SSL_CA does not seem to function properly to connect to the database securely so currently connecting insecurely
  // {
  //   name: 'DATABASE_SSL_CA'
  //   value: '/var/www/html/database/DigiCertGlobalRootG2.crt.pem'
  // }
  // {
  //   name: 'DATABASE_SSL_DONT_VERIFY_SERVER_CERT'
  //   value: '1'
  // }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_PUBLIC_CONTAINER'
    value: storageAccountPublicContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_PRIVATE_CONTAINER'
    value: storageAccountPrivateContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: storageAccountKeySecretRefName
  }
  {
    name: 'DATABASE_SERVER_VERSION'
    value: databaseServerVersion
  }
  {
    name: 'AZURE_CDN_URL'
    value: azureCdnUrl
  }
  // TODO unsure how necessary the following values are
  {
    name: 'SHOPWARE_SKIP_WEBINSTALLER'
    value: 'true'
  }
  {
    name: 'BLUE_GREEN_DEPLOYMENT'
    value: '0'
  }
  {
    name: 'LOCK_DSN'
    value: 'flock'
  }
  {
    name: 'SHOPWARE_HTTP_CACHE_ENABLED'
    value: '1'
  }
  {
    name: 'SHOPWARE_HTTP_DEFAULT_TTL'
    value: '7200'
  }
]

var opensearchVars = enableOpensearch ? [
  {
    name: 'SHOPWARE_ES_ENABLED'
    value: '1'
  }
  {
    name: 'OPENSEARCH_URL'
    value: opensearchUrl
  }
  {
    name: 'SHOPWARE_ES_INDEXING_ENABLED'
    value: '1'
  }
  {
    name: 'SHOPWARE_ES_INDEX_PREFIX'
    value: 'sw'
  }
  {
    name: 'SHOPWARE_ES_THROW_EXCEPTION'
    value: '1'
  }
  {
    name: 'ADMIN_OPENSEARCH_URL'
    value: opensearchUrl
  }
  {
    name: 'SHOPWARE_ADMIN_ES_ENABLED'
    value: '1'
  }
  {
    name: 'SHOPWARE_ADMIN_ES_REFRESH_INDICES'
    value: '1'
  }
  {
    name: 'SHOPWARE_ADMIN_ES_INDEX_PREFIX'
    value: 'sw-admin'
  }
]: []

output envVars array = concat(defaultEnvVars, opensearchVars, additionalVars)
