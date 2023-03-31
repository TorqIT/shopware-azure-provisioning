param appDebug string
param appEnv string
param storageAccountName string
param storageAccountContainerName string
param storageAccountAssetsContainerName string
param databaseServerName string
param databaseName string
param databaseUser string
param pimcoreDev string
param pimcoreEnvironment string
param redisDb string
param redisHost string
param redisSessionDb string
param additionalVars array

resource database 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' existing = {
  name: databaseServerName
}

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
    name: 'AZURE_STORAGE_ACCOUNT_ASSETS_CONTAINER'
    value: storageAccountAssetsContainerName
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_KEY'
    secretRef: 'storage-account-key'
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT_NAME'
    value: storageAccountName
  }
  {
    name: 'DATABASE_HOST'
    value: database.properties.fullyQualifiedDomainName 
  }
  {
    name: 'DATABASE_NAME'
    value: databaseName
  }
  {
    name: 'DATABASE_PASSWORD'
    secretRef: 'database-password'
  }
  {
    name: 'DATABASE_USER'
    value: databaseUser
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

output envVars array = concat(defaultEnvVars, additionalVars)
