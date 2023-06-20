#!/bin/bash

TENANT_NAME=$(jq -r '.parameters.tenantName.value' $1)

echo Logging in to Azure tenant $TENANT_NAME with service principal $2...
az login --tenant $TENANT_NAME --service-pricinpal -u $2 -p $3