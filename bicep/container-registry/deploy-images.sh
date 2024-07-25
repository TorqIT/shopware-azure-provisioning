#!/bin/bash

set -e

CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
INIT_IMAGE_NAME=$(jq -r '.parameters.initImageName.value // empty' $1)
PHP_FPM_IMAGE_NAME=$(jq -r '.parameters.phpFpmImageName.value' $1)
SUPERVISORD_IMAGE_NAME=$(jq -r '.parameters.supervisordImageName.value' $1)
REDIS_IMAGE_NAME=$(jq -r '.parameters.redisImageName.value' $1)

$IMAGES=( $PHP_FPM_IMAGE_NAME $SUPERVISORD_IMAGE_NAME $REDIS_IMAGE_NAME )
if [ ! -z $INIT_IMAGE_NAME ];
then
  $IMAGES+=($INIT_IMAGE_NAME)
fi

EXISTING_REPOSITORIES=$(az acr repository list --name $CONTAINER_REGISTRY_NAME)

if [ ${#EXISTING_REPOSITORIES[@]} -eq 0 ];
then
  # Container Apps require images to actually be present in the Container Registry in order to complete provisioning,
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
fi