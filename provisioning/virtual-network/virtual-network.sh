#!/bin/bash

set -e

echo Deploying virtual network...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file virtual-network.bicep \
  --parameters \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkAddressSpace=$VIRTUAL_NETWORK_ADDRESS_SPACE \
    containerAppsSubnetName=$VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NAME \
    containerAppsSubnetAddressSpace=$VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_ADDRESS_SPACE \
    databaseSubnetName=$VIRTUAL_NETWORK_DATABASE_SUBNET_NAME \
    databaseSubnetAddressSpace=$VIRTUAL_NETWORK_DATABASE_SUBNET_ADDRESS_SPACE
