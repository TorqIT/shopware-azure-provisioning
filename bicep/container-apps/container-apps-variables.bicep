param appEnv string
param appUrl string
param appInstallCurrency string
param appInstallLocale string
param appSalesChannelName string
param appInstallCategoryId string
param databaseUrlSecretName string
param additionalVars array

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
]

output envVars array = concat(defaultEnvVars, additionalVars)
