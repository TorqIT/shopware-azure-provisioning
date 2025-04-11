#!/bin/bash

echo "Provisioning the Azure environment..."
RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file ./bicep/main.bicep \
  --parameters @$1 \
  --parameters fullProvision=false