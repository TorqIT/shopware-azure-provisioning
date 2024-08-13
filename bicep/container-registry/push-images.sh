#!/bin/bash

set -e

CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
INIT_IMAGE_NAME=$(jq -r '.parameters.initImageName.value // empty' $1)
PHP_IMAGE_NAME=$(jq -r '.parameters.phpContainerAppImageName.value' $1)
SUPERVISORD_IMAGE_NAME=$(jq -r '.parameters.supervisordContainerAppImageName.value' $1)

IMAGES=($PHP_IMAGE_NAME $SUPERVISORD_IMAGE_NAME)
if [ ! -z $INIT_IMAGE_NAME ];
then
  IMAGES+=($INIT_IMAGE_NAME)
fi

EXISTING_REPOSITORIES=$(az acr repository list --name $CONTAINER_REGISTRY_NAME --output tsv)
if [ -z "$EXISTING_REPOSITORIES" ];
then
  # Container Apps require images to actually be present in the Container Registry,
  # therefore we tag and push some dummy Hello World ones here.
  echo Pushing Hello World images to Container Registry...
  docker pull hello-world
  az acr login --name $CONTAINER_REGISTRY_NAME
  for image in "${IMAGES[@]}"
  do
    docker tag hello-world:latest $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
    docker push $CONTAINER_REGISTRY_NAME.azurecr.io/$image:latest
  done
  docker logout
else
  echo "Container Registry repositories already exist ($EXISTING_REPOSITORIES), so no need to push anything"
fi