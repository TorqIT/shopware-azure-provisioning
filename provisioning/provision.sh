#!/bin/bash

set -e

./login.sh

cd virtual-network
./virtual-network.sh
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