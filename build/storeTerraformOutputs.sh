#!/bin/bash
COGNITO_USER_POOL_ID=$(terraform output --json | jq -r '.cognito_user_pool_id.value')
COGNITO_USER_POOL_CLIENT_ID=$(terraform output --json | jq -r '.cognito_user_pool_client_id.value')
COGNITO_IDENTITY_POOL_ID=$(terraform output --json | jq -r '.cognito_identity_pool_id.value')

aws ssm put-parameter --name "/amplify/d3m9wu6rhd9z99/main/COGNITO_USER_POOL_ID" --value $COGNITO_USER_POOL_ID --type String --overwrite
aws ssm put-parameter --name "/amplify/d3m9wu6rhd9z99/main/COGNITO_USER_POOL_CLIENT_ID" --value $COGNITO_USER_POOL_CLIENT_ID --type String --overwrite
aws ssm put-parameter --name "/amplify/d3m9wu6rhd9z99/main/COGNITO_IDENTITY_POOL_ID" --value $COGNITO_IDENTITY_POOL_ID --type String --overwrite