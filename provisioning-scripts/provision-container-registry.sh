RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value // empty' $1)

set +e
  echo "Checking for existence of Container Registry..."
  if [ "$CONTAINER_REGISTRY_SKU" == "Premium" ]; then
    echo Adding temporary network rule to the Container Registry firewall...
    az acr network-rule add -n $CONTAINER_REGISTRY_NAME --ip-address $(curl ipinfo.io/ip)
    # Sleep 30 seconds to allow network rule to propagate
    sleep 30
  fi
  az acr show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY_NAME > /dev/null 2>&1
  resultCode=$?
  if [ "$CONTAINER_REGISTRY_SKU" == "Premium" ]; then
    echo Removing temporary network rule from the Container Registry firewall...
    az acr network-rule remove -n $CONTAINER_REGISTRY_NAME --ip-address $(curl ipinfo.io/ip)
  fi
set -e

if [ $resultCode -ne 0 ]; then
  echo "Deploying Container Registry $CONTAINER_REGISTRY_NAME..."
  CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value // empty' $1)
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file ./bicep/container-registry/container-registry.bicep \
    --parameters \
      containerRegistryName=$CONTAINER_REGISTRY_NAME \
      sku=$CONTAINER_REGISTRY_SKU
else
  echo "Container Registry $CONTAINER_REGISTRY_NAME exists!"
fi