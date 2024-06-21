#!/bin/bash

set -e

export SUBSCRIPTION_ID=$(jq -r '.parameters.subscriptionId.value' $1)
export RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
export LOCATION=$(jq -r '.parameters.location.value' $1)
export SERVICE_PRINCIPAL_NAME=$(jq -r '.parameters.servicePrincipalName.value' $1)

echo Creating resource group $RESOURCE_GROUP in $LOCATION...
az group create --location $LOCATION --name $RESOURCE_GROUP

echo Creating service principal $SERVICE_PRINCIPAL_NAME...
az ad sp create-for-rbac --display-name $SERVICE_PRINCIPAL_NAME

az role assignment create \
    --assignee "{assignee}" \
    --role "{roleNameOrId}" \
    --scope "/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{providerName}/{resourceType}/{resourceSubType}/{resourceName}"