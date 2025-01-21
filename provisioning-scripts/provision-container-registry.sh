RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)

set +e
az acr show \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME > /dev/null 2>&1
resultCode=$?
set -e

if [ $resultCode -ne 0 ]; then
  echo "Deploying Container Registry..."
  CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value // empty' $1)
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file ./bicep/container-registry/container-registry.bicep \
    --parameters \
      containerRegistryName=$CONTAINER_REGISTRY_NAME \
      sku="${CONTAINER_REGISTRY_SKU:-Basic}"
fi