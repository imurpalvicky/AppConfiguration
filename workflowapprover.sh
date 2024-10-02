#!/bin/bash

# Variables (update these as needed)
GITHUB_TOKEN="your_github_token"  # Personal Access Token with repo and workflow scope
REPO_OWNER="your_repo_owner"      # GitHub organization or username
REPO_NAME="your_repo_name"        # Repository name
WORKFLOW_RUN_ID="$1"              # Workflow run ID passed as an argument

# Check if the required argument is provided
if [ -z "$WORKFLOW_RUN_ID" ]; then
  echo "Usage: $0 <workflow_run_id>"
  exit 1
fi

# Step 1: Get the workflow run details
workflow_run_response=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$WORKFLOW_RUN_ID")

# Check if the workflow run exists
if [ "$(echo "$workflow_run_response" | jq -r '.id')" == "null" ]; then
  echo "Workflow run ID '$WORKFLOW_RUN_ID' not found."
  exit 1
fi

# Step 2: List all environments
environments_response=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/environments")

# Step 3: Loop through each environment and get approval details
echo "Deployment approvals for workflow run ID: $WORKFLOW_RUN_ID"
echo "---------------------------------------------"

# Iterate through each environment
echo "$environments_response" | jq -c '.[]' | while read -r environment; do
  ENVIRONMENT_NAME=$(echo "$environment" | jq -r '.name')

  # Get the approval details for the environment
  approvals_response=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/environments/$ENVIRONMENT_NAME/deployment-approvals")

  # Check for approvers
  approvers=$(echo "$approvals_response" | jq -r '.[] | .user.login')

  if [ -n "$approvers" ]; then
    echo "Environment: $ENVIRONMENT_NAME"
    echo "Approvers: $approvers"
    echo "---------------------------------------------"
  else
    echo "Environment: $ENVIRONMENT_NAME"
    echo "No approvals found."
    echo "---------------------------------------------"
  fi
done