#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)

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