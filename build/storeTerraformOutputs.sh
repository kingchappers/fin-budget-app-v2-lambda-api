#!/bin/bash
COGNITO_USER_POOL_ID=$(terraform output --json | jq -r '.cognito_user_pool_id.value')
COGNITO_USER_POOL_CLIENT_ID=$(terraform output --json | jq -r '.cognito_user_pool_client_id.value')
COGNITO_IDENTITY_POOL_ID=$(terraform output --json | jq -r '.cognito_identity_pool_id.value')