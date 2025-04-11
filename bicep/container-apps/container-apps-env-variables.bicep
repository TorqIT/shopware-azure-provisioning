param appDebug string
param appEnv string
param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string
param storageAccountKeySecretRefName string
param databaseServerName string
param databaseServerVersion string
param databaseName string
param databaseUser string
param databasePasswordSecretRefName string
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisHost string
param redisSessionDb string
param additionalEnvVars array

// Optional Portal Engine provisioning
param provisionPortalEngine bool
param portalEngineStorageAccountName string
param portalEngineStorageAccountDownloadsContainerName string
param portalEngineStorageAccountKeySecretRefName string

var defaultEnvVars = [
  {
    name: 'APP_DEBUG'
    value: appDebug
  }
  {
    name: 'APP_ENV'
    value: appEnv
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_CONTAINER'
    value: storageAccountContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_CONTAINER_ASSETS'
    value: storageAccountAssetsContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: storageAccountKeySecretRefName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'DATABASE_HOST'
    value: '${databaseServerName}.mysql.database.azure.com'
  }
  {
    name: 'DATABASE_NAME'
    value: databaseName
  }
  {
    name: 'DATABASE_USER'
    value: databaseUser
  }
  {
    name: 'DATABASE_PASSWORD'
    secretRef: databasePasswordSecretRefName
  }
  {
    name: 'DATABASE_SERVER_VERSION'
    value: databaseServerVersion
  }
  {
    name: 'PIMCORE_DEV'
    value: pimcoreDev
  }
  {
    name: 'PIMCORE_ENVIRONMENT'
    value: pimcoreEnvironment
  }
  {
    name: 'REDIS_DB'
    value: redisDb
  }
  {
    name: 'REDIS_HOST'
    value: redisHost
  }
  {
    name: 'REDIS_SESSION_DB'
    value: redisSessionDb
  }
]

var portalEngineEnvVars = provisionPortalEngine ? [
  {
    name: 'PORTAL_ENGINE_STORAGE_ACCOUNT'
    value: portalEngineStorageAccountName
  }
  {
    name: 'PORTAL_ENGINE_STORAGE_ACCOUNT_DOWNLOADS_CONTAINER'
    value: portalEngineStorageAccountDownloadsContainerName
  }
  {
    name: 'PORTAL_ENGINE_STORAGE_ACCOUNT_KEY'
    secretRef: portalEngineStorageAccountKeySecretRefName
  }
]: []

output envVars array = concat(defaultEnvVars, additionalEnvVars, portalEngineEnvVars)
