#!/bin/bash

set -e

echo Deploying storage account...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file storage-account.bicep \
  --parameters \
    storageAccountName=$STORAGE_ACCOUNT_NAME \
    sku=$STORAGE_ACCOUNT_SKU \
    kind=$STORAGE_ACCOUNT_KIND \
    accessTier=$STORAGE_ACCOUNT_ACCESS_TIER \
    containerName=$STORAGE_ACCOUNT_CONTAINER_NAME \
    assetsContainerName=$STORAGE_ACCOUNT_ASSETS_CONTAINER_NAME \
    publicAssetAccess=$STORAGE_ACCOUNT_PUBLIC_ASSET_ACCESS \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NAME
