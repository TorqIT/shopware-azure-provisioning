#!/bin/bash

# Deactivates all running revisions of the PHP-FPM Container App. This may be desirable when updating the Container App's secrets (see root README.md).
# Usage: ./deactivate-php-fpm-container-app-revisions.sh <path to parameters.json file>

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
PHP_FPM_CONTAINER_APP=$(jq -r '.parameters.phpFpmContainerAppName.value' $1)

REVISIONS=$(az containerapp revision list --resource-group $RESOURCE_GROUP --name $PHP_FPM_CONTAINER_APP | jq -r '.[].name')

for revision in $REVISIONS
do
    az containerapp revision deactivate \
        --resource-group $RESOURCE_GROUP \
        --name $PHP_FPM_CONTAINER_APP \
        --revision $revision
done