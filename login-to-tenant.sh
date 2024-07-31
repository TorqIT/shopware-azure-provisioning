#!/bin/bash

TENANT_ID=$(jq -r '.parameters.tenantId.value' $1)
SUBSCRIPTION_ID=$(jq -r '.parameters.subscriptionId.value' $1)

echo Logging in to Azure tenant $TENANT_ID...
# Disable interactive subscription selector since we set the default subscription below
az config set core.login_experience_v2=off
az login --tenant $TENANT_ID
az account set --subscription $SUBSCRIPTION_ID