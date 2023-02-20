#!/bin/bash

set -e

echo Deploying database...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file database.bicep \
  --parameters \
    serverName=$DATABASE_SERVER_NAME \
    administratorLogin=$DATABASE_ADMIN_USER \
    administratorLoginPassword=$DATABASE_ADMIN_PASSWORD \
    skuName=$DATABASE_SKU_NAME \
    skuTier=$DATABASE_SKU_TIER \
    storageSizeGB=$DATABASE_STORAGE_SIZE_GB \
    databaseName=$DATABASE_NAME \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_SUBNET_NAME
