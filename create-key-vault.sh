#!/bin/bash

set -e

RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
LOCATION=$(jq -r '.parameters.location.value' $1)
KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)

echo "Creating Key Vault..."
az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --name $KEY_VAULT_NAME \
  --enabled-for-template-deployment true

echo "Adding network rule to allow this machine's IP..."
localIP=$(curl ipinfo.io/ip)
az keyvault network-rule add \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --ip-address $localIP

echo "Successfully provisioned Key Vault"