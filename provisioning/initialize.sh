#!/bin/bash

set -e

echo Logging into tenant $TENANT_NAME...
az login --tenant $TENANT_NAME
echo Creating resource group $RESOURCE_GROUP in $LOCATION...
az group create --location $LOCATION --name $RESOURCE_GROUP
echo Creating service principal $SERVICE_PRINCIPAL_NAME...
az ad sp create-for-rbac \
    --role Contributor \
    --scopes subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --display-name $SERVICE_PRINCIPAL_NAME
echo Logging out of Azure...
az logout