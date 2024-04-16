#!/bin/bash

check_required_variables() {
    local variables=("$@")
    MISSING_VARIABLES=()

    # Check if the variables are set and not empty
    for var_name in "${variables[@]}"; do
        # Use indirect reference to get the value of the variable
        local value=${!var_name}
        if [ -z "$value" ]; then
            MISSING_VARIABLES+=("$var_name")
        fi
    done

    # If any variables are missing, print an error and exit
    if [ ${#MISSING_VARIABLES[@]} -ne 0 ]; then
        echo "The following environment variables are not set or empty:"
        for miss in "${MISSING_VARIABLES[@]}"; do
            echo "- $miss"
        done
        echo ""        
        exit 1
    fi
}

check_azure_cli_logged_in() {
    # Check if az CLI is installed
    if ! command -v az &> /dev/null; then
        echo "Error: Azure CLI (az) is not installed."
        exit 1
    fi

    # Attempt to list the resource groups to verify the authentication
    if ! az group list &> /dev/null; then
        echo "Error: Unable to list Azure resource groups. Ensure you're properly authenticated with 'az login'."
        exit 1
    fi

    echo "Azure CLI authentication verified successfully."
}

function get_last_successful_run_id() {
    local acrName=$1
    local imageName=$2

    az acr task list-runs \
        --registry $acrName \
        --name $imageName \
        --run-status Succeeded \
        --top 1 \
        --query '[0].runId' \
        --output tsv
}