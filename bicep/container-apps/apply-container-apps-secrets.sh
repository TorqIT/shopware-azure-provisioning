#!/bin/bash

set -e

resourceGroup=$(jq -r '.parameters.resourceGroupName.value' $1)
keyVaultName=$(jq -r '.parameters.keyVaultName.value' $1)
phpFpmContainerAppName=$(jq -r '.parameters.phpContainerAppName.value' $1)
supervisordContainerAppName=$(jq -r '.parameters.supervisordContainerAppName.value' $1)
initContainerAppJobName=$(jq -r '.parameters.initContainerAppJobName.value // empty' $1)

jq -rc '.parameters.additionalSecrets.value.array[]' $1 | while IFS='' read secret;
do
  secretName=$(echo "$secret" | jq -r '.secretNameInKeyVault')
  secretEnvVarName=$(echo "$secret" | jq -r '.secretEnvVarNameInContainerApp')
  secretRef=$(echo "$secret" | jq -r '.secretRefInContainerApp')

  echo "Getting secret $secretName from Key Vault $keyVaultName..."
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName | jq -r '.value')

  echo "Setting secret $secretRef in Container App $phpFpmContainerAppName..."
  az containerapp secret set --resource-group $resourceGroup --name $phpFpmContainerAppName --secrets $secretRef=$secretValue
  echo "Setting environment variable $secretEnvVarName to reference $secretRef in $phpFpmContainerAppName..."
  az containerapp update --resource-group $resourceGroup --name $phpFpmContainerAppName --set-env-vars "$secretEnvVarName=secretref:$secretRef"

  echo "Setting secret $secretRef in Container App $supervisordContainerAppName..."
  az containerapp secret set --resource-group $resourceGroup --name $supervisordContainerAppName --secrets $secretRef=$secretValue
  echo "Setting environment variable $secretEnvVarName to reference $secretRef in $supervisordContainerAppName..."
  az containerapp update --resource-group $resourceGroup --name $supervisordContainerAppName --set-env-vars "$secretEnvVarName=secretref:$secretRef"

  if [ ! -z "${initContainerAppJobName}" ];
  then
    echo "Setting secret $secretRef in Container App Job $initContainerAppJobName..."
    az containerapp job secret set --resource-group $resourceGroup --name $initContainerAppJobName --secrets $secretRef=$secretValue
    echo "Setting environment variable $secretEnvVarName to reference $secretRef in $initContainerAppJobName..."
    az containerapp job update --resource-group $resourceGroup --name $initContainerAppJobName --set-env-vars "$secretEnvVarName=secretref:$secretRef"
  fi
done

