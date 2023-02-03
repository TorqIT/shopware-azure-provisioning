#!/bin/bash

echo Logging into Azure using service principal $SERVICE_PRINCIPAL_ID...
az login \
  --tenant $TENANT_NAME \
  --service-principal -u $SERVICE_PRINCIPAL_ID -p $SERVICE_PRINCIPAL_PASSWORD 