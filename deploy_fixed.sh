#!/usr/bin/env bash
# Disable strict error handling to prevent script from exiting on expected errors
set +e

# Get project parameters
read -rp "Enter project name [default: disability-rights-texas]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-disability-rights-texas}

read -rp "Enter CloudFormation stack name [default: ${PROJECT_NAME}-api-stack]: " STACK_NAME
STACK_NAME=${STACK_NAME:-${PROJECT_NAME}-api-stack}

read -rp "Enter Amplify app name [default: DisabilityRightsTexas]: " AMPLIFY_APP_NAME
AMPLIFY_APP_NAME=${AMPLIFY_APP_NAME:-DisabilityRightsTexas}

read -rp "Enter Amplify branch name [default: main]: " AMPLIFY_BRANCH_NAME
AMPLIFY_BRANCH_NAME=${AMPLIFY_BRANCH_NAME:-main}

# Get AWS region
read -rp "Enter AWS region [default: us-west-2]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-west-2}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
echo "Detected AWS Account ID: $AWS_ACCOUNT_ID"

# Get action
read -rp "Enter action [deploy/destroy]: " ACTION
ACTION=$(printf '%s' "$ACTION" | tr '[:upper:]' '[:lower:]')

# Create IAM role for CodeBuild
ROLE_NAME="${PROJECT_NAME}-codebuild-service-role"
POLICY_NAME="${PROJECT_NAME}-deployment-policy"
echo "Checking for IAM role: $ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "✓ IAM role exists: $ROLE_NAME"
  ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
else
  echo "✱ Creating IAM role: $ROLE_NAME"
  TRUST_DOC='{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"codebuild.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'
  
  # Try to create the role
  CREATE_RESULT=$(aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_DOC" 2>&1)
  
  # Check if role was created or already exists
  if echo "$CREATE_RESULT" | grep -q "EntityAlreadyExists"; then
    echo "✓ IAM role already exists: $ROLE_NAME"
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
  elif echo "$CREATE_RESULT" | grep -q "arn:aws:iam"; then
    echo "✓ Created IAM role: $ROLE_NAME"
    ROLE_ARN=$(echo "$CREATE_RESULT" | grep -o 'arn:aws:iam::[0-9]*:role/[a-zA-Z0-9_-]*')
  else
    echo "✗ Failed to create IAM role: $ROLE_NAME"
    echo "Error: $CREATE_RESULT"
    exit 1
  fi
fi

# Attach policy to role
POLICY_DOC='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "apigateway:*",
        "lambda:*",
        "iam:*",
        "amplify:*",
        "s3:*",
        "codebuild:*",
        "logs:*",
        "codeconnections:*",
        "codestar-connections:*",
        "qbusiness:*"
      ],
      "Resource": "*"
    }
  ]
}'

echo "Attaching policy to IAM role..."
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document "$POLICY_DOC"

echo "✓ Policy attached to IAM role"
echo "Role ARN: $ROLE_ARN"

# Continue with the rest of the script
echo "=== PHASE 3: Q Business Application Setup ==="

# Check for existing Q Business application
EXISTING_APP_ID=$(aws qbusiness list-applications --region "$AWS_REGION" --query 'applications[?displayName==`DisabilityRightsTexas`].applicationId' --output text)
if [ -n "$EXISTING_APP_ID" ] && [ "$EXISTING_APP_ID" != "None" ]; then
  echo "✓ Found existing Q Business Application: $EXISTING_APP_ID"
  APPLICATION_ID="$EXISTING_APP_ID"
  
  # Get existing index ID
  EXISTING_INDEX_ID=$(aws qbusiness list-indices --application-id "$APPLICATION_ID" --region "$AWS_REGION" --query 'indices[?displayName==`DisabilityRightsIndex`].indexId' --output text)
  if [ -n "$EXISTING_INDEX_ID" ] && [ "$EXISTING_INDEX_ID" != "None" ]; then
    echo "✓ Found existing Index: $EXISTING_INDEX_ID"
    INDEX_ID="$EXISTING_INDEX_ID"
  fi
else
  echo "Creating Q Business application..."
  
  # 1. Create the application
  APP_RESPONSE=$(aws qbusiness create-application \
    --display-name "DisabilityRightsTexas" \
    --identity-type "ANONYMOUS" \
    --region "$AWS_REGION" \
    --output json 2>&1)
  
  APPLICATION_ID=$(echo "$APP_RESPONSE" | jq -r '.applicationId')
  echo "✓ Created Q Business Application: $APPLICATION_ID"
  
  echo "Waiting for application to be active..."
  while true; do
    STATUS=$(aws qbusiness get-application --application-id "$APPLICATION_ID" --region "$AWS_REGION" --query 'status' --output text)
    if [ "$STATUS" = "ACTIVE" ]; then
      echo "Application is ACTIVE. Waiting extra 10 seconds for full readiness..."
      sleep 10
      break
    fi
    echo "Status: $STATUS, waiting..."
    sleep 10
  done
fi

# Create index if needed
if [ -z "${INDEX_ID:-}" ]; then
  echo "Creating Q Business index..."
  INDEX_RESPONSE=$(aws qbusiness create-index \
    --application-id "$APPLICATION_ID" \
    --display-name "DisabilityRightsIndex" \
    --type "STARTER" \
    --region "$AWS_REGION" \
    --output json)
  
  INDEX_ID=$(echo "$INDEX_RESPONSE" | jq -r '.indexId')
  echo "✓ Created Index: $INDEX_ID"
  
  echo "Waiting for index to be active..."
  while true; do
    STATUS=$(aws qbusiness get-index --application-id "$APPLICATION_ID" --index-id "$INDEX_ID" --region "$AWS_REGION" --query 'status' --output text)
    if [ "$STATUS" = "ACTIVE" ]; then
      echo "Index is ACTIVE"
      break
    fi
    echo "Index status: $STATUS, waiting..."
    sleep 15
  done
fi

echo "=== PHASE 4: Web Experience Setup ==="

# Check for existing web experience
EXISTING_WEB_EXPERIENCE_ID=$(aws qbusiness list-web-experiences --application-id "$APPLICATION_ID" --region "$AWS_REGION" --query 'webExperiences[0].id' --output text 2>/dev/null)
if [ -n "$EXISTING_WEB_EXPERIENCE_ID" ] && [ "$EXISTING_WEB_EXPERIENCE_ID" != "None" ]; then
  echo "✓ Found existing Web Experience: $EXISTING_WEB_EXPERIENCE_ID"
  WEB_EXPERIENCE_ID="$EXISTING_WEB_EXPERIENCE_ID"
else
  echo "Creating Web Experience..."
  
  # Create web experience with correct parameters
  # Check the available parameters for create-web-experience
  WEB_EXPERIENCE_RESPONSE=$(aws qbusiness create-web-experience \
    --application-id "$APPLICATION_ID" \
    --name "DisabilityRightsWeb" \
    --region "$AWS_REGION" \
    --output json 2>&1)
  
  if echo "$WEB_EXPERIENCE_RESPONSE" | grep -q "id"; then
    WEB_EXPERIENCE_ID=$(echo "$WEB_EXPERIENCE_RESPONSE" | jq -r '.id')
    echo "✓ Created Web Experience: $WEB_EXPERIENCE_ID"
  else
    echo "✗ Failed to create Web Experience. Error: $WEB_EXPERIENCE_RESPONSE"
    echo "You may need to create the web experience manually in the AWS Console."
  fi
fi

# Wait for web experience to be active
if [ -n "$WEB_EXPERIENCE_ID" ]; then
  echo "Waiting for web experience to be active..."
  while true; do
    WEB_STATUS=$(aws qbusiness get-web-experience --application-id "$APPLICATION_ID" --web-experience-id "$WEB_EXPERIENCE_ID" --region "$AWS_REGION" --query 'status' --output text)
    if [ "$WEB_STATUS" = "ACTIVE" ]; then
      echo "Web experience is ACTIVE"
      break
    fi
    echo "Web experience status: $WEB_STATUS, waiting..."
    sleep 10
  done
  
  # Output the web experience URL
  WEB_EXPERIENCE_DETAILS=$(aws qbusiness get-web-experience \
    --application-id "$APPLICATION_ID" \
    --web-experience-id "$WEB_EXPERIENCE_ID" \
    --region "$AWS_REGION" \
    --output json 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    # Try different possible field names for the URL
    WEB_URL=$(echo "$WEB_EXPERIENCE_DETAILS" | jq -r '.endpoint // .url // .defaultDomain // "URL not available"')
    echo "Web Experience URL: $WEB_URL"
  else
    echo "Could not retrieve web experience URL. Check the AWS Console for details."
  fi
fi

echo "=== PHASE 5: S3 Data Source Setup ==="

# Create S3 bucket
S3_BUCKET_NAME="${PROJECT_NAME}-docs-bucket"
echo "Checking for S3 bucket: $S3_BUCKET_NAME"
if aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
  echo "✓ S3 bucket exists: $S3_BUCKET_NAME"
else
  echo "✱ Creating S3 bucket: $S3_BUCKET_NAME"
  aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
  echo "✓ S3 bucket created: $S3_BUCKET_NAME"
fi

echo "Uploading files from /docs to S3 bucket: $S3_BUCKET_NAME"
aws s3 sync "$(dirname "$0")/docs" "s3://$S3_BUCKET_NAME/" --region "$AWS_REGION"
echo "✓ Files uploaded to S3 bucket: $S3_BUCKET_NAME"

# Create a specific IAM role for Q Business data sources
QBUSINESS_ROLE_NAME="${PROJECT_NAME}-qbusiness-role"
QBUSINESS_POLICY_NAME="${PROJECT_NAME}-qbusiness-policy"

echo "Setting up IAM role for Q Business data sources: $QBUSINESS_ROLE_NAME"

# Check if the Q Business role exists
if aws iam get-role --role-name "$QBUSINESS_ROLE_NAME" >/dev/null 2>&1; then
  echo "✓ Q Business IAM role exists: $QBUSINESS_ROLE_NAME"
  QBUSINESS_ROLE_ARN=$(aws iam get-role --role-name "$QBUSINESS_ROLE_NAME" --query 'Role.Arn' --output text)
else
  echo "Creating Q Business IAM role: $QBUSINESS_ROLE_NAME"
  
  # Create trust policy for Q Business
  QBUSINESS_TRUST_DOC='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"qbusiness.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
  
  # Create the role
  QBUSINESS_ROLE_RESPONSE=$(aws iam create-role \
    --role-name "$QBUSINESS_ROLE_NAME" \
    --assume-role-policy-document "$QBUSINESS_TRUST_DOC" \
    --description "Role for Q Business to access S3 data sources" \
    --output json 2>&1)
  
  if echo "$QBUSINESS_ROLE_RESPONSE" | grep -q "EntityAlreadyExists"; then
    echo "✓ Q Business IAM role already exists: $QBUSINESS_ROLE_NAME"
    QBUSINESS_ROLE_ARN=$(aws iam get-role --role-name "$QBUSINESS_ROLE_NAME" --query 'Role.Arn' --output text)
  elif echo "$QBUSINESS_ROLE_RESPONSE" | grep -q "arn:aws:iam"; then
    QBUSINESS_ROLE_ARN=$(echo "$QBUSINESS_ROLE_RESPONSE" | jq -r '.Role.Arn')
    echo "✓ Created Q Business IAM role: $QBUSINESS_ROLE_NAME"
  else
    echo "✗ Failed to create Q Business IAM role: $QBUSINESS_ROLE_NAME"
    echo "Error: $QBUSINESS_ROLE_RESPONSE"
    exit 1
  fi
  
  # Create policy for Q Business to access S3
  QBUSINESS_POLICY_DOC='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::'$S3_BUCKET_NAME'","arn:aws:s3:::'$S3_BUCKET_NAME'/*"]}]}'
  
  # Attach policy to role
  aws iam put-role-policy \
    --role-name "$QBUSINESS_ROLE_NAME" \
    --policy-name "$QBUSINESS_POLICY_NAME" \
    --policy-document "$QBUSINESS_POLICY_DOC"
  
  echo "Waiting for Q Business IAM role to propagate..."
  sleep 30
fi

# Check for existing S3 data source
S3_DATA_SOURCE_NAME="DisabilityRightsS3DataSource"
EXISTING_DATA_SOURCE_ID=$(aws qbusiness list-data-sources --application-id "$APPLICATION_ID" --index-id "$INDEX_ID" --region "$AWS_REGION" --query 'dataSources[0].id' --output text 2>/dev/null)

if [ -n "$EXISTING_DATA_SOURCE_ID" ] && [ "$EXISTING_DATA_SOURCE_ID" != "None" ]; then
  echo "✓ Found existing S3 data source: $EXISTING_DATA_SOURCE_ID"
  S3_DATA_SOURCE_ID="$EXISTING_DATA_SOURCE_ID"
else
  echo "Adding S3 bucket as a data source to Q Business application..."
  echo "Using Q Business role ARN: $QBUSINESS_ROLE_ARN"
  # Create a simpler S3 data source configuration based on AWS documentation
  S3_DATA_SOURCE_CONFIG='{"type":"S3","dataSourceConfiguration":{"s3Configuration":{"bucketName":"'$S3_BUCKET_NAME'"}}}'
  
  # For debugging
  echo "S3 Data Source Configuration:"
  echo "$S3_DATA_SOURCE_CONFIG"

  # Try to create the data source with retries
  MAX_RETRIES=3
  RETRY_COUNT=0
  DATA_SOURCE_CREATED=false
  
  while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$DATA_SOURCE_CREATED" = "false" ]; do
    # Get the AWS CLI help for create-data-source to see the correct parameters
    echo "Getting AWS CLI help for create-data-source..."
    aws qbusiness help create-data-source > /dev/null 2>&1
    
    # Try with the correct parameter names
    S3_DATA_SOURCE_RESPONSE=$(aws qbusiness create-data-source \
      --application-id "$APPLICATION_ID" \
      --index-id "$INDEX_ID" \
      --name "$S3_DATA_SOURCE_NAME" \
      --configuration "$S3_DATA_SOURCE_CONFIG" \
      --role-arn "$QBUSINESS_ROLE_ARN" \
      --region "$AWS_REGION" \
      --output json 2>&1)
    
    if echo "$S3_DATA_SOURCE_RESPONSE" | grep -q "id"; then
      S3_DATA_SOURCE_ID=$(echo "$S3_DATA_SOURCE_RESPONSE" | jq -r '.id')
      echo "✓ S3 data source added with ID: $S3_DATA_SOURCE_ID"
      DATA_SOURCE_CREATED=true
    else
      RETRY_COUNT=$((RETRY_COUNT+1))
      echo "Failed to create data source (attempt $RETRY_COUNT/$MAX_RETRIES). Error: $S3_DATA_SOURCE_RESPONSE"
      echo "Retrying in 30 seconds..."
      sleep 30
    fi
  done
  
  if [ "$DATA_SOURCE_CREATED" = "false" ]; then
    echo "✗ Failed to create data source after $MAX_RETRIES attempts."
    echo "Please check the IAM role permissions and try again."
    echo "You can manually create the data source in the AWS Console."
  fi
fi

echo "📋 Q Business Setup Updated:"
echo "   Application ID: $APPLICATION_ID"
echo "   Index ID: $INDEX_ID"
echo "   S3 Data Source ID: $S3_DATA_SOURCE_ID"

echo "=== PHASE 6: CodeBuild Project Setup ==="

# Create CodeBuild project
CODEBUILD_PROJECT_NAME="${PROJECT_NAME}-deploy"
echo "Creating CodeBuild project: $CODEBUILD_PROJECT_NAME"
echo "Using Q Business Application ID: $APPLICATION_ID"

ENV_VARS='[
  {"name": "STACK_NAME", "value": "'$STACK_NAME'", "type": "PLAINTEXT"},
  {"name": "AWS_REGION", "value": "'$AWS_REGION'", "type": "PLAINTEXT"},
  {"name": "ACTION", "value": "'$ACTION'", "type": "PLAINTEXT"},
  {"name": "AMPLIFY_APP_NAME", "value": "'$AMPLIFY_APP_NAME'", "type": "PLAINTEXT"},
  {"name": "AMPLIFY_BRANCH_NAME", "value": "'$AMPLIFY_BRANCH_NAME'", "type": "PLAINTEXT"},
  {"name": "APPLICATION_ID", "value": "'$APPLICATION_ID'", "type": "PLAINTEXT"}
]'

ENVIRONMENT='{
  "type": "LINUX_CONTAINER",
  "image": "aws/codebuild/standard:7.0",
  "computeType": "BUILD_GENERAL1_MEDIUM",
  "environmentVariables": '$ENV_VARS'
}'

ARTIFACTS='{"type":"NO_ARTIFACTS"}'

# Get GitHub repository URL
if [ -z "${GITHUB_URL:-}" ]; then
  # Try to get the GitHub URL from git config
  GITHUB_URL=$(git config --get remote.origin.url 2>/dev/null || echo "https://github.com/aws-samples/disability-rights-texas")
  echo "Using GitHub URL: $GITHUB_URL"
fi

# Configure source for public GitHub repository
SOURCE='{
  "type": "GITHUB",
  "location": "'$GITHUB_URL'",
  "buildspec": "buildspec.yml",
  "gitCloneDepth": 1
}'

# Delete existing project if it exists
if aws codebuild batch-get-projects --names "$CODEBUILD_PROJECT_NAME" --query 'projects[0].name' --output text 2>/dev/null | grep -q "$CODEBUILD_PROJECT_NAME"; then
  echo "Deleting existing CodeBuild project..."
  aws codebuild delete-project --name "$CODEBUILD_PROJECT_NAME"
  sleep 5
fi

# Create new CodeBuild project
echo "Creating new CodeBuild project..."
aws codebuild create-project \
  --name "$CODEBUILD_PROJECT_NAME" \
  --source "$SOURCE" \
  --artifacts "$ARTIFACTS" \
  --environment "$ENVIRONMENT" \
  --service-role "$ROLE_ARN" \
  --output json \
  --no-cli-pager

echo "Starting deployment build..."
BUILD_ID=$(aws codebuild start-build \
  --project-name "$CODEBUILD_PROJECT_NAME" \
  --query 'build.id' \
  --output text)

echo "✓ Build started with ID: $BUILD_ID"
echo "You can monitor the build progress in the AWS Console:"
echo "https://console.aws.amazon.com/codesuite/codebuild/projects/$CODEBUILD_PROJECT_NAME/build/$BUILD_ID"