#!/bin/bash

# Connects to the most recent revision of the supervisord Container App.
# Usage: ./connect-to-supervisord.sh <parameters.json file>
# Note that Azure has a fairly aggressive session timeout, so if you plan to execute any long-running commands within the container, you should run it with nohup or tmux to prevent it from exiting prematurely when your session is disconnected.

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
SUPERVISORD_CONTAINER_APP=$(jq -r '.parameters.supervisordContainerAppName.value' $1)

az containerapp exec --resource-group $RESOURCE_GROUP --name $SUPERVISORD_CONTAINER_APP --command bash