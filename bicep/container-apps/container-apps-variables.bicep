param appEnv string
param appUrl string
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
]

output envVars array = concat(defaultEnvVars, additionalVars)
