#!/bin/bash

TENANT_NAME=$(jq -r '.parameters.tenantName.value' $1)
SUBSCRIPTION_ID=$(jq -r '.parameters.subscriptionId.value' $1)

echo Logging in to Azure tenant $TENANT_NAME...
az login --tenant $TENANT_NAME
az account set --subscription $SUBSCRIPTION_ID