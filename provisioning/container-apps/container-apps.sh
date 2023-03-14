#!/bin/bash

set -e

if $DEPLOY_IMAGES_TO_REGISTRY
then
  # Container Apps require images to actually be present in the Container Registry in order to complete provisioning,
  # therefore we tag and push them here. Note that this assumes the images are already built and available, and depends
  # on the image names being defined as environment variables (see README).
  # 
  # In practice, it likely makes sense to push these images on inital environment creation, but likely not on updates.
  #
  echo Pushing images to Container Registry...
  docker login --username $SERVICE_PRINCIPAL_ID --password $SERVICE_PRINCIPAL_PASSWORD $CONTAINER_REGISTRY_NAME.azurecr.io
  declare -A IMAGES=( [$LOCAL_PHP_FPM_IMAGE]=$PHP_FPM_IMAGE_NAME [$LOCAL_SUPERVISORD_IMAGE]=$SUPERVISORD_IMAGE_NAME [$LOCAL_REDIS_IMAGE]=$REDIS_IMAGE_NAME )
  for image in "${!IMAGES[@]}"
  do
    docker tag $image $CONTAINER_REGISTRY_NAME.azurecr.io/${IMAGES[$image]}:latest
    docker push $CONTAINER_REGISTRY_NAME.azurecr.io/${IMAGES[$image]}:latest
  done
  docker logout $CONTAINER_REGISTRY_NAME.azurecr.io
fi

echo Deploying Container Apps...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file container-apps.bicep \
  --parameters \
    containerAppsEnvironmentName=$CONTAINER_APPS_ENVIRONMENT_NAME \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NAME \
    containerRegistryName=$CONTAINER_REGISTRY_NAME \
    databaseServerName=$DATABASE_SERVER_NAME \
    storageAccountName=$STORAGE_ACCOUNT_NAME \
    storageAccountContainerName=$STORAGE_ACCOUNT_CONTAINER_NAME \
    storageAccountAssetsContainerName=$STORAGE_ACCOUNT_ASSETS_CONTAINER_NAME \
    phpFpmContainerAppExternal=$PHP_FPM_CONTAINER_APP_EXTERNAL \
    phpFpmContainerAppName=$PHP_FPM_CONTAINER_APP_NAME \
    phpFpmContainerAppUseProbes=$PHP_FPM_CONTAINER_APP_USE_PROBES \
    phpFpmImageName=$PHP_FPM_IMAGE_NAME \
    supervisordContainerAppName=$SUPERVISORD_CONTAINER_APP_NAME \
    supervisordImageName=$SUPERVISORD_IMAGE_NAME \
    redisContainerAppName=$REDIS_CONTAINER_APP_NAME \
    redisImageName=$REDIS_IMAGE_NAME \
    appDebug=$APP_DEBUG \
    appEnv=$APP_ENV \
    databaseName=$DATABASE_NAME \
    databasePassword=$DATABASE_ADMIN_PASSWORD \
    databaseUser=$DATABASE_ADMIN_USER \
    pimcoreDev=$PIMCORE_DEV \
    pimcoreEnvironment=$PIMCORE_ENVIRONMENT \
    redisDb=$REDIS_DB \
    redisHost=$REDIS_CONTAINER_APP_NAME \
    redisSessionDb=$REDIS_SESSION_DB