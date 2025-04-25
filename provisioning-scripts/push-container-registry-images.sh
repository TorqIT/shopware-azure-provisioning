#!/bin/bash

# Container Apps require images to actually be present in the Container Registry in order to be fully provisioned,
# therefore we tag and push some dummy Hello World ones in this script.

set -e

CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
CONTAINER_REGISTRY_SKU=$(jq -r '.parameters.containerRegistrySku.value // empty' $1)
INIT_IMAGE_NAME=$(jq -r '.parameters.initContainerAppJobImageName.value // "init"' $1)
PHP_IMAGE_NAME=$(jq -r '.parameters.phpContainerAppImageName.value // "php"' $1)
SUPERVISORD_IMAGE_NAME=$(jq -r '.parameters.supervisordContainerAppImageName.value // "supervisord"' $1)

IMAGES=($PHP_IMAGE_NAME $SUPERVISORD_IMAGE_NAME $INIT_IMAGE_NAME)

if [ "$CONTAINER_REGISTRY_SKU" == "Premium" ]; then
  echo Adding temporary network rule to the Container Registry firewall...
  az acr network-rule add -n $CONTAINER_REGISTRY_NAME --ip-address $(curl ipinfo.io/ip)
  # Sleep 30 seconds to allow network rule to propagate
  sleep 30
fi

echo "Checking if Container registry has necessary repositories..."
EXISTING_REPOSITORIES=$(az acr repository list --name $CONTAINER_REGISTRY_NAME --output tsv)

if [ -z "$EXISTING_REPOSITORIES" ];
then
  echo Pushing Hello World images to Container Registry...
  docker pull hello-world
  az acr login --name $CONTAINER_REGISTRY_NAME
  for image in "${IMAGES[@]}"
  do
    docker tag hello-world:latest $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
    docker push $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
  done
  docker logout $CONTAINER_REGISTRY_NAME
else
  echo "Container Registry repositories already exist ($EXISTING_REPOSITORIES), so no need to push anything!"
fi

if [ "$CONTAINER_REGISTRY_SKU" == "Premium" ]; then
  echo Removing temporary network rule from the Container Registry firewall...
  az acr network-rule remove -n $CONTAINER_REGISTRY_NAME --ip-address $(curl ipinfo.io/ip)
fi