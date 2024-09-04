param appEnv string
param appUrl string
param appSecretSecretName string
param appInstallCurrency string
param appInstallLocale string
param appSalesChannelName string
param appInstallCategoryId string
param storageAccountName string
param storageAccountPublicContainerName string
param storageAccountKeySecretName string
param databaseUrlSecretName string
param databaseServerName string
param databaseName string
param databaseUser string
param additionalVars array

resource database 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' existing = {
  name: databaseServerName
}

var defaultEnvVars = [
  {
    name: 'APP_ENV'
    value: appEnv
  }
  {
    name: 'APP_URL'
    value: appUrl
  }
  {
    name: 'APP_SECRET'
    secretRef: appSecretSecretName
  }
  {
    name: 'APP_INSTALL_CURRENCY'
    value: appInstallCurrency
  }
  {
    name: 'APP_INSTALL_LOCALE'
    value: appInstallLocale
  }
  {
    name: 'APP_SALESCHANNEL_NAME'
    value: appSalesChannelName
  }
  {
    name: 'APP_INSTALL_CATEGORY_ID'
    value: appInstallCategoryId
  }
  {
    name: 'DATABASE_URL'
    secretRef: databaseUrlSecretName
  }
  {
    name: 'DATABASE_HOST'
    value: database.properties.fullyQualifiedDomainName
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
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: storageAccountKeySecretName
  }
  {
    name: 'AZURE_CDN_URL'
    value: 'https://${storageAccountName}.blob.core.windows.net/${storageAccountPublicContainerName}'
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

output envVars array = concat(defaultEnvVars, additionalVars)
