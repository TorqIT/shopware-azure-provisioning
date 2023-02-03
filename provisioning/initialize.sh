#!/bin/bash

set -e

az login --tenant $TENANT_NAME
az group create --location $LOCATION --name $RESOURCE_GROUP
az ad sp create-for-rbac --role Contributor --scopes subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP
az logout