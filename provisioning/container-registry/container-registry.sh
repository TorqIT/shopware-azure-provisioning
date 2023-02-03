#!/bin/bash

set -e

echo Deploying container registry...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file container-registry.bicep \
  --parameters \
    containerRegistryName=$CONTAINER_REGISTRY_NAME

CONTAINER_REGISTRY_REPOSITORIES=($PHP_FPM_IMAGE_NAME $SUPERVISORD_IMAGE_NAME $REDIS_IMAGE_NAME $CERT_RENEWAL_IMAGE_NAME)

echo Setting up scheduled task to purge all but the latest 10 containers...
PURGE_CMD="acr purge "
for repository in ${CONTAINER_REGISTRY_REPOSITORIES[@]}
do
  PURGE_CMD="$PURGE_CMD --filter '$repository:.*'"
done
PURGE_CMD="$PURGE_CMD --ago 0d --keep 10 --untagged"
az acr task create \
  --resource-group $RESOURCE_GROUP \
  --name purgeTask \
  --cmd "$PURGE_CMD" \
  --schedule "0 0 * * *" \
  --registry $CONTAINER_REGISTRY_NAME \
  --context /dev/null