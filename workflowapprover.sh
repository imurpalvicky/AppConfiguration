#!/bin/bash

# Variables (update these as needed)
GITHUB_TOKEN="your_github_token"  # Personal Access Token with repo and workflow scope
REPO_OWNER="your_repo_owner"      # GitHub organization or username
REPO_NAME="your_repo_name"        # Repository name
WORKFLOW_RUN_ID="$1"              # Workflow run ID passed as an argument
ENVIRONMENT_NAME="$2"             # Environment name (e.g., 'production')

# Check if the required arguments are provided
if [ -z "$WORKFLOW_RUN_ID" ] || [ -z "$ENVIRONMENT_NAME" ]; then
  echo "Usage: $0 <workflow_run_id> <environment_name>"
  exit 1
fi

# Step 1: Get the deployment history for the specific environment
DEPLOYMENT_ID=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$WORKFLOW_RUN_ID/deployments" | \
     jq -r ".[] | select(.environment == \"$ENVIRONMENT_NAME\") | .id")

# Step 2: Fetch the approvals for the specific environment deployment
if [ -n "$DEPLOYMENT_ID" ]; then
  curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$WORKFLOW_RUN_ID/approvals" | \
       jq -r ".[] | select(.environment.name == \"$ENVIRONMENT_NAME\") | .user.login"
else
  echo "No deployments found for the specified environment: $ENVIRONMENT_NAME"
fi