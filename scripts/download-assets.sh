#!/bin/bash

# Usage: ./download-assets.sh <path to parameters.json file> <destination path>
# If you run this from within a container, you can copy the results to your host OS by exiting the container and running `docker cp -r <container name>:<path inside container> <destination path on host OS>`

STORAGE_ACCOUNT=$(jq -r '.parameters.storageAccountName.value' $1)
CONTAINER=$(jq -r '.parameters.storageAccountAssetsContainerName.value' $1)
KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT | jq -r '.[0].value')

az storage blob directory download \
    --account-name $STORAGE_ACCOUNT \
    --account-key $KEY \
    --container $CONTAINER \
    --source-path assets \
    --destination-path $2 \
    --recursive