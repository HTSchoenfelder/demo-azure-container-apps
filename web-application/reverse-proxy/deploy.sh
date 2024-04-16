#!/bin/bash

. ../../shared/functions.sh
check_required_variables "RESOURCEGROUP_NAME" "ACR_NAME"
check_azure_cli_logged_in

echo "Run task"
az acr task run \
    --registry $ACR_NAME \
    --name "reverse-proxy" \
    --context "." \
    --file "Dockerfile"

taskRunId=$(get_last_successful_run_id $ACR_NAME "reverse-proxy")
echo "Task run ID: $taskRunId"

echo "Deploy container app"
az deployment group create \
    --resource-group $RESOURCEGROUP_NAME \
    --template-file ./reverse-proxy.bicep \
    --parameters taskRunId=$taskRunId \
                 acrName=$ACR_NAME
