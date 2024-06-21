#!/bin/bash

set -e

echo Setting up scheduled task to purge all but the latest 10 containers...

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
CONTAINER_REGISTRY_NAME=$(jq -r '.parameters.containerRegistryName.value' $1)
SHOPWARE_IMAGE_NAME=$(jq -r '.parameters.shopwareImageName.value' $1)

CONTAINER_REGISTRY_REPOSITORIES=($SHOPWARE_IMAGE_NAME)

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