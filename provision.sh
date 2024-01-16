#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)

KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)
KEY_VAULT_RESOURCE_GROUP_NAME=$(jq -r '.parameters.keyVaultResourceGroupName.value' $1)
echo "Deploying Key Vault..."
az deployment group create \
  --resource-group $KEY_VAULT_RESOURCE_GROUP_NAME \
  --template-file ./bicep/key-vault/key-vault.bicep \
  --parameters \
    name=$KEY_VAULT_NAME \
    localIpAddress=$(curl ipinfo.io/ip)

WAIT_FOR_KEY_VAULT_MANUAL_INTERVENTION=$(jq -r '.parameters.waitForKeyVaultManualIntervention.value' $1)
if [ "${WAIT_FOR_KEY_VAULT_MANUAL_INTERVENTION:-false}" = true ]; then
  read -p "Use the Azure Portal to update the Key Vault's access policies (e.g. give yourself the ability to add secrets), and to add any keys/secrets needed for the rest of the resources (e.g. a database password). Then, press Enter to continue... "
fi

# Because we need to run some non-Bicep scripts after deploying the Container Registry (but before
# deploying the other resources), we create the Container Registry separately here before running the
# main Bicep file.
echo "Deploying Container Registry..."
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value' $1)
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/container-registry/container-registry.bicep \
  --parameters \
    containerRegistryName=$CONTAINER_REGISTRY_NAME \
    sku=$CONTAINER_REGISTRY_SKU
./bicep/container-registry/deploy-images.sh $1
./bicep/container-registry/purge-container-registry-task.sh $1

echo "Provisioning the rest of the Azure environment..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/main.bicep \
  --parameters @$1

./bicep/container-apps/apply-container-apps-secrets.sh $1

echo "Done!"