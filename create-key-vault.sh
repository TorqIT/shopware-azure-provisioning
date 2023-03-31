#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroup.value' $1)
LOCATION=$(jq -r '.parameters.location.value' $1)
KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)

az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --name $KEY_VAULT_NAME \
  --enabled-for-template-deployment true