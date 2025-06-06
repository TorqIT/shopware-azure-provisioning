#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
LOCATION=$(jq -r '.parameters.location.value' $1)

if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
  echo "Deploying Resource Group..."
  az deployment sub create \
    --location $LOCATION \
    --name $RESOURCE_GROUP-$(date +%s) \
    --template-file ./bicep/resource-group/resource-group.bicep \
    --parameters \
      name=$RESOURCE_GROUP \
      location=$LOCATION
fi

# Provisioning the Key Vault as a first step allows us to deploy some necessary secrets to it before 
# provisioning the other resources
# TODO this may be possible with deployment scripts?
. ./provisioning-scripts/provision-key-vault.sh $1

# Because we need to run some non-Bicep scripts after deploying the Container Registry (but before
# deploying the other resources), we create the Container Registry separately here before running the
# main Bicep file.
# TODO this may be possible with deployment scripts?
. ./provisioning-scripts/provision-container-registry.sh $1
. ./provisioning-scripts/push-container-registry-images.sh $1
. ./provisioning-scripts/purge-container-registry-task.sh $1

echo "Provisioning the Azure environment..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/main.bicep \
  --parameters @$1 \
  --parameters fullProvision=true

PROVISION_SERVICE_PRINCIPAL=$(jq -r '.parameters.provisionServicePrincipal.value' $1) #alternative operator (//) does not work here because "false" makes it always execute
if [ "${PROVISION_SERVICE_PRINCIPAL}" = "null" ] || [ "${PROVISION_SERVICE_PRINCIPAL}" = true ]
then
  SERVICE_PRINCIPAL_NAME=$(jq -r '.parameters.servicePrincipalName.value' $1)
  SERVICE_PRINCIPAL_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].{spID:id}" --output tsv)
  if [ -z $SERVICE_PRINCIPAL_ID ]
  then
    echo "Creating service principal $SERVICE_PRINCIPAL_NAME..."
    az ad sp create-for-rbac --display-name $SERVICE_PRINCIPAL_NAME
    echo "IMPORTANT: Note the appId and password returned above!"
    SERVICE_PRINCIPAL_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].{spID:id}" --output tsv)
  fi

  DATABASE_LONG_TERM_BACKUPS=$(jq -r '.parameters.databaseLongTermBackups.value // empty' $1)
  DATABASE_BACKUPS_STORAGE_ACCOUNT_NAME=$(jq -r '.parameters.databaseBackupsStorageAccountName.value // empty' $1)
  echo "Assigning roles for service principal..."
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file ./bicep/service-principal/service-principal-roles.bicep \
    --parameters \
      servicePrincipalId=$SERVICE_PRINCIPAL_ID \
      containerRegistryName=$CONTAINER_REGISTRY_NAME \
      databaseLongTermBackups=$DATABASE_LONG_TERM_BACKUPS \
      databaseBackupsStorageAccountName=$DATABASE_BACKUPS_STORAGE_ACCOUNT_NAME \
      keyVaultName=$KEY_VAULT_NAME \
      keyVaultResourceGroupName=$KEY_VAULT_RESOURCE_GROUP_NAME
fi

echo "Done!"