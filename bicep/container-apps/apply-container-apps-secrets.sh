#!/bin/bash

set -e

resourceGroup=$(jq -r '.parameters.resourceGroupName.value' $1)
keyVaultName=$(jq -r '.parameters.keyVaultName.value' $1)
shopwareWebContainerAppName=$(jq -r '.parameters.shopwareWebContainerAppName.value' $1)
shopwareInitContainerAppJobName=$(jq -r '.parameters.shopwareInitContainerAppJobName.value' $1)

jq -rc '.parameters.additionalSecrets.value.array[]' $1 | while IFS='' read secret;
do
  secretName=$(echo "$secret" | jq -r '.secretNameInKeyVault')
  secretEnvVarName=$(echo "$secret" | jq -r '.secretEnvVarNameInContainerApp')
  secretRef=$(echo "$secret" | jq -r '.secretRefInContainerApp')

  echo "Getting secret $secretName from Key Vault $keyVaultName..."
  secretValue=$(az keyvault secret show --name $secretName --vault-name $keyVaultName | jq -r '.value')

  echo "Setting secret $secretRef in Container App $shopwareWebContainerAppName..."
  az containerapp secret set --resource-group $resourceGroup --name $shopwareWebContainerAppName --secrets $secretRef=$secretValue
  echo "Setting environment variable $secretEnvVarName to reference $secretRef in $shopwareWebContainerAppName..."
  az containerapp update --resource-group $resourceGroup --name $shopwareWebContainerAppName --set-env-vars "$secretEnvVarName=secretref:$secretRef"

  echo "Setting secret $secretRef in Container App Job $shopwareInitContainerAppJobName..."
  az containerapp job secret set --resource-group $resourceGroup --name $shopwareInitContainerAppJobName --secrets $secretRef=$secretValue
  echo "Setting environment variable $secretEnvVarName to reference $secretRef in $shopwareInitContainerAppJobName..."
  az containerapp job update --resource-group $resourceGroup --name $shopwareInitContainerAppJobName --set-env-vars "$secretEnvVarName=secretref:$secretRef"
done

