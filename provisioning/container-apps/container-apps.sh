#!/bin/bash

set -e

# Container Apps require images to actually be present in the Container Registry in order to complete provisioning,
# therefore we tag and push them here. Note that this assumes the images are already built and available, and depends
# on the image names being defined as environment variables (see README).
echo Pushing images to Container Registry...
docker login --username $SERVICE_PRINCIPAL_ID --password $SERVICE_PRINCIPAL_PASSWORD $CONTAINER_REGISTRY_NAME.azurecr.io
declare -A IMAGES=( [$LOCAL_PHP_FPM_IMAGE]=$PHP_FPM_IMAGE_NAME [$LOCAL_SUPERVISORD_IMAGE]=$SUPERVISORD_IMAGE_NAME [$LOCAL_REDIS_IMAGE]=$REDIS_IMAGE_NAME )
for image in "${!IMAGES[@]}"
do
  docker tag $image $CONTAINER_REGISTRY_NAME.azurecr.io/${IMAGES[$image]}:latest
  docker push $CONTAINER_REGISTRY_NAME.azurecr.io/${IMAGES[$image]}:latest
done
docker logout $CONTAINER_REGISTRY_NAME.azurecr.io

echo Deploying Container Apps...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file container-apps.bicep \
  --parameters \
    containerAppsEnvironmentName=$CONTAINER_APPS_ENVIRONMENT_NAME \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_SUBNET_NAME \
    containerRegistryName=$CONTAINER_REGISTRY_NAME \
    databaseServerName=$DATABASE_SERVER_NAME \
    isDatabaseIncludedInVirtualNetwork=$INCLUDE_DATABASE_IN_VIRTUAL_NETWORK \
    storageAccountName=$STORAGE_ACCOUNT_NAME \
    storageAccountContainerName=$STORAGE_ACCOUNT_CONTAINER_NAME \
    phpFpmContainerAppName=$PHP_FPM_CONTAINER_APP_NAME \
    phpFpmImageName=$PHP_FPM_IMAGE_NAME \
    supervisordContainerAppName=$SUPERVISORD_CONTAINER_APP_NAME \
    supervisordImageName=$SUPERVISORD_IMAGE_NAME \
    redisContainerAppName=$REDIS_CONTAINER_APP_NAME \
    redisImageName=$REDIS_IMAGE_NAME \
    certRenewalContainerAppName=$CERT_RENEWAL_CONTAINER_APP_NAME \
    certRenewalImageName=$CERT_RENEWAL_IMAGE_NAME \
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

# TCP transport is not yet supported for Container Apps through Bicep, so we use the CLI command for the
# Redis container
echo Deploying Redis Container App...
CONTAINER_REGISTRY_PASSWORD=$(az acr credential show \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --query passwords[0].value | tr -d '"')
az containerapp create \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_CONTAINER_APP_NAME \
  --environment $CONTAINER_APPS_ENVIRONMENT_NAME \
  --cpu 0.5 \
  --memory 1.0 \
  --registry-server $CONTAINER_REGISTRY_NAME.azurecr.io \
  --registry-username $CONTAINER_REGISTRY_NAME \
  --registry-password $CONTAINER_REGISTRY_PASSWORD \
  --image $CONTAINER_REGISTRY_NAME.azurecr.io/$REDIS_IMAGE_NAME:latest \
  --ingress internal \
    --target-port 6379 \
    --exposed-port 6379 \
    --transport tcp \
  --max-replicas 1 \
  --min-replicas 1