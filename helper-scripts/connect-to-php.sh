#!/bin/bash

# Connects to the most recent revision of the PHP Container App.
# Usage: ./connect-to-php.sh <parameters.json file>
# Note that Azure has a fairly aggressive session timeout, so if you plan to execute any long-running commands within the container, you should run it with nohup or tmux to prevent it from exiting prematurely when your session is disconnected.

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
PHP_CONTAINER_APP=$(jq -r '.parameters.phpContainerAppName.value' $1)

az containerapp exec --resource-group $RESOURCE_GROUP --name $PHP_CONTAINER_APP --command bash
