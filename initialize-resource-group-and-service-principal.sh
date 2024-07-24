#!/bin/bash

set -e

SUBSCRIPTION_ID=$(jq -r '.parameters.subscriptionId.value' $1)
RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
LOCATION=$(jq -r '.parameters.location.value' $1)
SERVICE_PRINCIPAL_NAME=$(jq -r '.parameters.servicePrincipalName.value' $1)
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
INIT_CONTAINER_APP_JOB_NAME=$(jq -r '.parameters.initContainerAppJobName.value // ""' $1)
PHP_FPM_CONTAINER_APP_NAME=$(jq -r '.parameters.phpFpmContainerAppName.value' $1)
KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)

echo Creating resource group $RESOURCE_GROUP in $LOCATION...
az group create --location $LOCATION --name $RESOURCE_GROUP

echo Creating service principal $SERVICE_PRINCIPAL_NAME...
az ad sp create-for-rbac --display-name $SERVICE_PRINCIPAL_NAME

SERVICE_PRINCIPAL_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].{spID:appId}" --output tsv)

echo Assigning AcrPush role on Container Registry to service principal...
az role assignment create \
    --assignee $SERVICE_PRINCIPAL_ID \
    --role "AcrPush" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$CONTAINER_REGISTRY_NAME"

echo Assigning Contributor role on Shopware Container App to service principal...
az role assignment create \
    --assignee $SERVICE_PRINCIPAL_ID \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.App/containerapps/$PHP_FPM_CONTAINER_APP_NAME"

if [ -n "${INIT_CONTAINER_APP_JOB_NAME}" ];
then
    echo Assigning Contributor role on init Container App Job to service principal...
    az role assignment create \
        --assignee $SERVICE_PRINCIPAL_ID \
        --role "Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.App/jobs/$INIT_CONTAINER_APP_JOB_NAME"
fi

echo Assigning Key Vault Secrets User on Key Vault to service principal...
az role assignment create \
    --assignee $SERVICE_PRINCIPAL_ID \
    --role "Key Vault Secrets User" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"