#!/bin/bash

set -e

DEPLOY_IMAGES_TO_CONTAINER_REGISTRY=$(jq -r '.parameters.deployImagesToContainerRegistry.value' $1)
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
SHOPWARE_INIT_IMAGE_NAME=$(jq -r '.parameters.shopwareInitImageName.value' $1)
SHOPWARE_WEB_IMAGE_NAME=$(jq -r '.parameters.shopwareWebImageName.value' $1)

if $DEPLOY_IMAGES_TO_CONTAINER_REGISTRY
then
  # Container Apps require images to actually be present in the Container Registry in order to complete provisioning,
  # so we push some "Hello World!" ones here
  echo Pushing images to Container Registry...
  docker pull nginx
  az acr login --name $CONTAINER_REGISTRY_NAME
  declare -A IMAGES=( $SHOPWARE_INIT_IMAGE_NAME $SHOPWARE_WEB_IMAGE_NAME )
  for image in "${!IMAGES[@]}"
  do
    docker tag hello-world $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
    docker push $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
  done
  docker logout
fi