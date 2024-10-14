name: "Get Approval Details for GitHub Actions Environment"
description: "Fetches approval details (user, comments, state) for a specific environment in a GitHub Actions workflow."
inputs:
  token:
    description: "GitHub token with repo permissions"
    required: true
  run_id:
    description: "ID of the workflow run"
    required: true
  environment:
    description: "The environment name to filter the approvals"
    required: true

outputs:
  approver:
    description: "The GitHub username of the approver"
  state:
    description: "The approval state (approved, rejected, etc.)"
  comment:
    description: "The comment provided by the approver"

runs:
  using: "composite"
  steps:
    - name: "Get approval details for environment"
      shell: bash
      run: |
        # Inputs
        GITHUB_TOKEN="${{ inputs.token }}"
        RUN_ID="${{ inputs.run_id }}"
        ENVIRONMENT="${{ inputs.environment }}"
        
        # Call GitHub API to fetch approval details
        APPROVAL_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
          https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${RUN_ID}/approvals)
        
        # Parse the JSON response to find approvals for the specified environment
        APPROVER=$(echo "$APPROVAL_RESPONSE" | jq -r ".approvals[] | select(.environment == \"$ENVIRONMENT\") | .user.login")
        STATE=$(echo "$APPROVAL_RESPONSE" | jq -r ".approvals[] | select(.environment == \"$ENVIRONMENT\") | .state")
        COMMENT=$(echo "$APPROVAL_RESPONSE" | jq -r ".approvals[] | select(.environment == \"$ENVIRONMENT\") | .comment")
        
        # Output results, or fail if no matching environment approval is found
        if [[ -z "$APPROVER" ]]; then
          echo "No approval found for environment: $ENVIRONMENT"
          exit 1
        else
          echo "::set-output name=approver::$APPROVER"
          echo "::set-output name=state::$STATE"
          echo "::set-output name=comment::$COMMENT"
        fi

    # Set the output for the composite action
    - run: echo "approver=${{ steps.get_approval.outputs.approver }}" >> $GITHUB_ENV
    - run: echo "state=${{ steps.get_approval.outputs.state }}" >> $GITHUB_ENV
    - run: echo "comment=${{ steps.get_approval.outputs.comment }}" >> $GITHUB_ENV