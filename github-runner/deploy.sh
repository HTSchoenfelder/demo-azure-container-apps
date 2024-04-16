#!/bin/bash

. ../shared/functions.sh
check_required_variables "RESOURCEGROUP_NAME" "ACR_NAME" "REPO_OWNER" "REPO_NAME" "PAT_FOR_GITHUB_RUNNER"
check_azure_cli_logged_in

echo "Run task"
az acr task run \
    --registry $ACR_NAME \
    --name "github-runner" \
    --context "." \
    --file "Dockerfile"

taskRunId=$(get_last_successful_run_id $ACR_NAME "github-runner")
echo "Task run ID: $taskRunId"

echo "Deploy container app"
az deployment group create \
    --resource-group $RESOURCEGROUP_NAME \
    --template-file ./github-runner.bicep \
    --parameters taskRunId=$taskRunId \
                 acrName=$ACR_NAME \
                 repoOwner=$REPO_OWNER \
                 repoName=$REPO_NAME \
                 githubPat=$PAT_FOR_GITHUB_RUNNER
