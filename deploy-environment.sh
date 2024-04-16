#!/bin/bash

. ./shared/functions.sh
check_required_variables "RESOURCEGROUP_NAME" "ACR_NAME"
check_azure_cli_logged_in

az deployment group create \
    --resource-group $RESOURCEGROUP_NAME \
    --template-file ./environment.bicep \
    --parameters acrName=$ACR_NAME