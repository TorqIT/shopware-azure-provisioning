#!/bin/bash

# Used in CI/CD scenarios to provision typical changes to infrastructure, skipping atypical changes to speed things up.

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/main.bicep \
  --parameters @$1 \
  --parameters \
    fullProvision=false \
    skipDatabase=$2