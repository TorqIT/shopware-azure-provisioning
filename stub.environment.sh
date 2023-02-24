#!/bin/bash

# Global parameters
export TENANT_NAME=
export TENANT_ID=
export SUBSCRIPTION_ID=
export RESOURCE_GROUP=
export LOCATION=canadacentral
export SERVICE_PRINCIPAL_NAME=

# Virtual Network
export VIRTUAL_NETWORK_NAME=
export VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NAME=container-apps
export VIRTUAL_NETWORK_ADDRESS_SPACE='11.0.0.0/16'
export VIRTUAL_NETWORK_SUBNET_ADDRESS_SPACE='11.0.0.0/23'
export VIRTUAL_NETWORK_DATABASE_SUBNET_NAME=database
export VIRTUAL_NETWORK_DATABASE_SUBNET_ADDRESS_SPACE='11.0.2.0/29'

# Database
export DATABASE_SERVER_NAME=
export DATABASE_ADMIN_USER=adminuser
export DATABASE_SKU_NAME=Standard_B1ms
export DATABASE_SKU_TIER=Burstable
export DATABASE_STORAGE_SIZE_GB=20
export DATABASE_NAME=pimcore

# Container Registry
export CONTAINER_REGISTRY_NAME=
export CONTAINER_REGISTRY_SKU=Basic
export PHP_FPM_IMAGE_NAME=pimcore-php-fpm
export SUPERVISORD_IMAGE_NAME=pimcore-supervisord
export REDIS_IMAGE_NAME=pimcore-redis

# Storage Account
export STORAGE_ACCOUNT_NAME=
export STORAGE_ACCOUNT_SKU=Standard_LRS
export STORAGE_ACCOUNT_KIND=StorageV2
export STORAGE_ACCOUNT_ACCESS_TIER=Hot
export STORAGE_ACCOUNT_CONTAINER_NAME=pimcore

# Container Apps
export CONTAINER_APPS_ENVIRONMENT_NAME=pimcore-dev
export PHP_FPM_CONTAINER_APP_NAME=pimcore-php-fpm-dev
export SUPERVISORD_CONTAINER_APP_NAME=pimcore-supervisord-dev
export REDIS_CONTAINER_APP_NAME=pimcore-redis-dev
# Environment variable values for the Container Apps. This list can be expanded if your app requires more variables - just be sure
# to also add the variables to container-apps.sh and container-apps.bicep.
export APP_DEBUG=1
export APP_ENV=dev
export PIMCORE_DEV=1
export PIMCORE_ENVIRONMENT=dev
export REDIS_DB=12
export REDIS_SESSION_DB=14
