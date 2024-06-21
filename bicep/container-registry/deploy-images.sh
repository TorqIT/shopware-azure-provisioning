#!/bin/bash

set -e

DEPLOY_IMAGES_TO_CONTAINER_REGISTRY=$(jq -r '.parameters.deployImagesToContainerRegistry.value' $1)
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
SHOPWARE_IMAGE_NAME=$(jq -r '.parameters.shopwareImageName.value' $1)

if $DEPLOY_IMAGES_TO_CONTAINER_REGISTRY
then
  # Container Apps require images to actually be present in the Container Registry in order to complete provisioning,
  # therefore we tag and push them here. Note that this assumes the images are already built and available, and depends
  # on the local image names being defined as environment variables (see README).
  echo Pushing images to Container Registry...
  az acr login --name $CONTAINER_REGISTRY_NAME
  docker tag $LOCAL_SHOPWARE_IMAGE $CONTAINER_REGISTRY_NAME.azurecr.io/$SHOPWARE_IMAGE_NAME:latest
  docker push $CONTAINER_REGISTRY_NAME.azurecr.io/$SHOPWARE_IMAGE_NAME:latest
  docker logout
fi