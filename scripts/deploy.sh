#!/bin/bash

# Variables
RESOURCE_GROUP="nick-urbis-test"
LOCATION="australiaeast"
STORAGE_ACCOUNT_NAME="nickurbisteststorage"
APP_SERVICE_PLAN_NAME="nick-test-plan"
FUNCTION_NAME="nick-urbis-backend"
BICEP_FILE="bicep/main.bicep"
TENENT_ID="fbe002c2-fe4e-47bd-afbc-29bb25af671e"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy Bicep template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file $BICEP_FILE \
  --parameters functionName=$FUNCTION_NAME \
               location=$LOCATION \
               storageAccountName=$STORAGE_ACCOUNT_NAME \
               appServicePlanName=$APP_SERVICE_PLAN_NAME \
               tenantId=$TENENT_ID

npm install
npm run build

func azure functionapp publish $FUNCTION_NAME

