#!/bin/bash

set -e

./login.sh

cd virtual-network
if [ "$VIRTUAL_NETWORK_RESOURCE_GROUP" == "$RESOURCE_GROUP" ]
then
    ./virtual-network.sh
else
    echo Virtual network is defined to be in resource group $VIRTUAL_NETWORK_RESOURCE_GROUP and will be assumed to be existing, so skipping deployment of virtual network
fi
cd ..

cd container-registry
./container-registry.sh
cd ..

cd database
./database.sh
cd ..

cd storage-account
./storage-account.sh
cd ..

cd container-apps
./container-apps.sh
cd ../

echo Done!