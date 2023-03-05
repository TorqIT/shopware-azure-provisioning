#!/bin/bash
. ./environment.prod.sh
. ./secrets.prod.sh
./login.sh
az containerapp exec --resource-group $RESOURCE_GROUP --name $PHP_FPM_CONTAINER_APP_NAME --command bash
