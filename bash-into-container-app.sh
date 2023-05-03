#!/bin/bash

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
PHP_FPM_CONTAINER_APP=$(jq -r '.parameters.phpFpmContainerAppName.value' $1)

az containerapp exec --resource-group $RESOURCE_GROUP --name $PHP_FPM_CONTAINER_APP --command bash