#!/bin/bash

set -e

echo Deploying virtual network...
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file virtual-network.bicep \
  --parameters \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    subnetName=$VIRTUAL_NETWORK_SUBNET_NAME \
    includeDatabaseInVirtualNetwork=$INCLUDE_DATABASE_IN_VIRTUAL_NETWORK
