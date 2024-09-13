#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
LOCATION=$(jq -r '.parameters.location.value' $1)

if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
  echo "Deploying Resource Group..."
  az deployment sub create \
    --location $LOCATION \
    --template-file ./bicep/resource-group/resource-group.bicep \
    --parameters \
      name=$RESOURCE_GROUP \
      location=$LOCATION
fi

KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)
KEY_VAULT_RESOURCE_GROUP_NAME=$(jq -r '.parameters.keyVaultResourceGroupName.value // empty' $1)
WAIT_FOR_KEY_VAULT_MANUAL_INTERVENTION=$(jq -r '.parameters.waitForKeyVaultManualIntervention.value' $1)
if [ "${WAIT_FOR_KEY_VAULT_MANUAL_INTERVENTION:-false}" = true ] && [ "${KEY_VAULT_RESOURCE_GROUP_NAME:-$RESOURCE_GROUP}" == "${RESOURCE_GROUP}" ]
then
  echo "Deploying Key Vault..."
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file ./bicep/key-vault/key-vault.bicep \
    --parameters \
      name=$KEY_VAULT_NAME \
      localIpAddress=$(curl ipinfo.io/ip)
  read -p "Use the Azure Portal to update the Key Vault's access policies (e.g. give yourself the ability to add secrets), and to add any keys/secrets needed for the rest of the resources (e.g. a database password). Then, press Enter to continue... "
fi

# Because we need to run some non-Bicep scripts after deploying the Container Registry (but before
# deploying the other resources), we create the Container Registry separately here before running the
# main Bicep file.
echo "Deploying Container Registry..."
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value // empty' $1)
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/container-registry/container-registry.bicep \
  --parameters \
    containerRegistryName=$CONTAINER_REGISTRY_NAME \
    sku="${CONTAINER_REGISTRY_SKU:-Basic}"
./bicep/container-registry/push-images.sh $1
./bicep/container-registry/purge-container-registry-task.sh $1

echo "Provisioning the rest of the Azure environment..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/main.bicep \
  --parameters @$1

# TODO reconfigure for Shopware
#./bicep/container-apps/apply-container-apps-secrets.sh $1

PROVISION_SERVICE_PRINCIPAL=$(jq -r '.parameters.provisionServicePrincipal.value' $1) #alternative operator (//) does not work here because "false" makes it always execute
if [ "${PROVISION_SERVICE_PRINCIPAL}" != "null" ] || [ "${PROVISION_SERVICE_PRINCIPAL}" = true ]
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

  SHOPWARE_INIT_CONTAINER_APP_JOB_NAME=$(jq -r '.parameters.shopwareInitContainerAppJobName.value' $1)
  SHOPWARE_WEB_CONTAINER_APP_NAME=$(jq -r '.parameters.shopwareWebContainerAppName.value' $1)
  echo "Assigning roles for service principal..."
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file ./bicep/service-principal/service-principal-roles.bicep \
    --parameters \
      servicePrincipalId=$SERVICE_PRINCIPAL_ID \
      containerRegistryName=$CONTAINER_REGISTRY_NAME \
      shopwareInitContainerAppJobName=$SHOPWARE_INIT_CONTAINER_APP_JOB_NAME \
      shopwareWebContainerAppName=$SHOPWARE_WEB_CONTAINER_APP_NAME
fi

echo "Done!"