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
    databaseName=$DATABASE_NAME \
    skuCapacity=$DATABASE_SKU_CAPACITY \
    skuName=$DATABASE_SKU_NAME \
    skuSizeMB=$DATABASE_SKU_SIZE_MB \
    skuTier=$DATABASE_SKU_TIER \
    skuFamily=$DATABASE_SKU_FAMILY \
    includeInVirtualNetwork=$INCLUDE_DATABASE_IN_VIRTUAL_NETWORK \
    virtualNetworkName=$VIRTUAL_NETWORK_NAME \
    virtualNetworkSubnetName=$VIRTUAL_NETWORK_SUBNET_NAME

echo Seeding database for Pimcore...
# Temporarily open firewall to this machine's IP
az mariadb server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DATABASE_SERVER_NAME \
  --name "SeedIP" \
  --start-ip-address $(curl ipinfo.io/ip) \
  --end-ip-address $(curl ipinfo.io/ip)
# Seed the database
mysql \
  -h $DATABASE_SERVER_NAME.mariadb.database.azure.com \
  -u $DATABASE_ADMIN_USER@$DATABASE_SERVER_NAME \
  -p$DATABASE_ADMIN_PASSWORD \
  $DATABASE_NAME \
  --ssl-ca=./BaltimoreCyberTrustRoot.crt.pem \
  < ./pimcore.sql
# Delete the temporary firewall rule
az mariadb server firewall-rule delete \
  --resource-group $RESOURCE_GROUP \
  --server-name $DATABASE_SERVER_NAME \
  --name "SeedIP" \
  --yes