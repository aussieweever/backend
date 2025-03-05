#!/bin/bash

app_create_output=$(az ad app create \
  --display-name "nick-ubris-backend-api" \
  --identifier-uris "api://nick-ubris-backend-api" \
  --required-resource-accesses ./scripts/api-permissions.json)

# Extract the app ID from the output
app_id=$(echo $app_create_output | jq -r '.appId')

az ad app update \
  --id $app_id \
  --set api.oauth2Permissions=./scripts/api-scopes.json


