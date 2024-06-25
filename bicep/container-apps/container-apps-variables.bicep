param appDebug string
param appEnv string
// param storageAccountName string
// param storageAccountContainerName string
// param storageAccountAssetsContainerName string
param databaseServerName string
param databaseName string
param databaseUser string
param additionalVars array
param databasePasswordSecretName string
param databaseUrlSecretName string

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
  // {
  //   name: 'AZURE_STORAGE_ACCOUNT_CONTAINER'
  //   value: storageAccountContainerName
  // }
  // {
  //   name: 'AZURE_STORAGE_ACCOUNT_CONTAINER_ASSETS'
  //   value: storageAccountAssetsContainerName
  // }
  // {
  //   name: 'AZURE_STORAGE_ACCOUNT_KEY'
  //   secretRef: 'storage-account-key'
  // }
  // {
  //   name: 'AZURE_STORAGE_ACCOUNT_NAME'
  //   value: storageAccountName
  // }
  {
    name: 'DATABASE_HOST'
    value: database.properties.fullyQualifiedDomainName 
  }
  {
    name: 'DATABASE_PORT'
    value: '3306'
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
    secretRef: databasePasswordSecretName
  }
  {
    name: 'DATABASE_URL'
    secretRef: databaseUrlSecretName
  }
  {
    name: 'DATABASE_SSL_CA'
    value: '/var/www/html/database/DigiCertGlobalRootG2.crt.pem'
  }
  {
    name: 'DATABASE_SSL_DONT_VERIFY_SERVER_CERT'
    value: '1'
  }
]

output envVars array = concat(defaultEnvVars, additionalVars)
