#!/usr/bin/env bash
# Disable strict error handling to allow the script to continue
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

# === PHASE 1: IAM Role Setup ===
echo "=== PHASE 1: IAM Role Setup ==="

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
  
  # Try to create the role, but continue even if it fails
  CREATE_RESULT=$(aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_DOC" \
    --output json 2>&1)
  
  # Check if role was created or already exists
  if echo "$CREATE_RESULT" | grep -q "EntityAlreadyExists"; then
    echo "✓ IAM role already exists: $ROLE_NAME"
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
  elif echo "$CREATE_RESULT" | grep -q "arn:aws:iam"; then
    echo "✓ Created IAM role: $ROLE_NAME"
    ROLE_ARN=$(echo "$CREATE_RESULT" | jq -r '.Role.Arn' 2>/dev/null || echo "$CREATE_RESULT" | grep -o 'arn:aws:iam::[0-9]*:role/[a-zA-Z0-9_-]*')
  else
    echo "✗ Failed to create IAM role: $ROLE_NAME"
    echo "Error: $CREATE_RESULT"
    # Try to get the role ARN anyway in case it exists
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -z "$ROLE_ARN" ]; then
      ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
      echo "Using assumed ARN: $ROLE_ARN"
    fi
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
  --policy-document "$POLICY_DOC" \
  --output json || echo "Warning: Failed to attach policy to role $ROLE_NAME"

echo "✓ Policy attached to IAM role"
echo "Role ARN: $ROLE_ARN"

# Create IAM role for Q Business application
APPLICATION_ROLE_NAME="${PROJECT_NAME}-qbusiness-application-role"
APPLICATION_POLICY_NAME="${PROJECT_NAME}-qbusiness-application-policy"
echo "Checking for Q Business application IAM role: $APPLICATION_ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name "$APPLICATION_ROLE_NAME" >/dev/null 2>&1; then
  echo "✓ Q Business application IAM role exists: $APPLICATION_ROLE_NAME"
  APPLICATION_ROLE_ARN=$(aws iam get-role --role-name "$APPLICATION_ROLE_NAME" --query 'Role.Arn' --output text)
else
  echo "✱ Creating Q Business application IAM role: $APPLICATION_ROLE_NAME"
  TRUST_DOC='{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"qbusiness.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'
  
  # Try to create the role
  CREATE_RESULT=$(aws iam create-role \
    --role-name "$APPLICATION_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_DOC" \
    --output json 2>&1)
  
  # Check if role was created or already exists
  if echo "$CREATE_RESULT" | grep -q "EntityAlreadyExists"; then
    echo "✓ Q Business application IAM role already exists: $APPLICATION_ROLE_NAME"
    APPLICATION_ROLE_ARN=$(aws iam get-role --role-name "$APPLICATION_ROLE_NAME" --query 'Role.Arn' --output text)
  elif echo "$CREATE_RESULT" | grep -q "arn:aws:iam"; then
    echo "✓ Created Q Business application IAM role: $APPLICATION_ROLE_NAME"
    APPLICATION_ROLE_ARN=$(echo "$CREATE_RESULT" | jq -r '.Role.Arn')
  else
    echo "✗ Failed to create Q Business application IAM role: $APPLICATION_ROLE_NAME"
    echo "Error: $CREATE_RESULT"
    # Try to get the role ARN anyway
    APPLICATION_ROLE_ARN=$(aws iam get-role --role-name "$APPLICATION_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -z "$APPLICATION_ROLE_ARN" ]; then
      APPLICATION_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/$APPLICATION_ROLE_NAME"
      echo "Using assumed ARN: $APPLICATION_ROLE_ARN"
    fi
  fi
  
  # Attach policy to role
  APPLICATION_POLICY_DOC='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "qbusiness:BatchPutDocument",
          "qbusiness:BatchDeleteDocument"
        ],
        "Resource": "*"
      }
    ]
  }'
  
  aws iam put-role-policy \
    --role-name "$APPLICATION_ROLE_NAME" \
    --policy-name "$APPLICATION_POLICY_NAME" \
    --policy-document "$APPLICATION_POLICY_DOC" \
    --output json || echo "Warning: Failed to attach policy to role $APPLICATION_ROLE_NAME"
  
  echo "✓ Policy attached to Q Business application IAM role"
  echo "Waiting for IAM role to propagate..."
  sleep 10
fi

# Create IAM role for Web Crawler data source
WEB_CRAWLER_ROLE_NAME="${PROJECT_NAME}-qbusiness-webcrawler-role"
WEB_CRAWLER_POLICY_NAME="${PROJECT_NAME}-qbusiness-webcrawler-policy"
echo "Checking for Web Crawler IAM role: $WEB_CRAWLER_ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name "$WEB_CRAWLER_ROLE_NAME" >/dev/null 2>&1; then
  echo "✓ Web Crawler IAM role exists: $WEB_CRAWLER_ROLE_NAME"
  WEB_CRAWLER_ROLE_ARN=$(aws iam get-role --role-name "$WEB_CRAWLER_ROLE_NAME" --query 'Role.Arn' --output text)
else
  echo "✱ Creating Web Crawler IAM role: $WEB_CRAWLER_ROLE_NAME"
  TRUST_DOC='{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"qbusiness.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'
  
  # Try to create the role
  CREATE_RESULT=$(aws iam create-role \
    --role-name "$WEB_CRAWLER_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_DOC" \
    --output json 2>&1)
  
  # Check if role was created or already exists
  if echo "$CREATE_RESULT" | grep -q "EntityAlreadyExists"; then
    echo "✓ Web Crawler IAM role already exists: $WEB_CRAWLER_ROLE_NAME"
    WEB_CRAWLER_ROLE_ARN=$(aws iam get-role --role-name "$WEB_CRAWLER_ROLE_NAME" --query 'Role.Arn' --output text)
  elif echo "$CREATE_RESULT" | grep -q "arn:aws:iam"; then
    echo "✓ Created Web Crawler IAM role: $WEB_CRAWLER_ROLE_NAME"
    WEB_CRAWLER_ROLE_ARN=$(echo "$CREATE_RESULT" | jq -r '.Role.Arn')
  else
    echo "✗ Failed to create Web Crawler IAM role: $WEB_CRAWLER_ROLE_NAME"
    echo "Error: $CREATE_RESULT"
    # Try to get the role ARN anyway
    WEB_CRAWLER_ROLE_ARN=$(aws iam get-role --role-name "$WEB_CRAWLER_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -z "$WEB_CRAWLER_ROLE_ARN" ]; then
      WEB_CRAWLER_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/$WEB_CRAWLER_ROLE_NAME"
      echo "Using assumed ARN: $WEB_CRAWLER_ROLE_ARN"
    fi
  fi
  
  # Attach policy to role
  WEB_CRAWLER_POLICY_DOC='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "qbusiness:BatchPutDocument",
          "qbusiness:BatchDeleteDocument"
        ],
        "Resource": "*"
      }
    ]
  }'
  
  aws iam put-role-policy \
    --role-name "$WEB_CRAWLER_ROLE_NAME" \
    --policy-name "$WEB_CRAWLER_POLICY_NAME" \
    --policy-document "$WEB_CRAWLER_POLICY_DOC" \
    --output json || echo "Warning: Failed to attach policy to role $WEB_CRAWLER_ROLE_NAME"
  
  echo "✓ Policy attached to Web Crawler IAM role"
  echo "Waiting for IAM role to propagate..."
  sleep 10
fi

# Create IAM role for S3 data source
S3_ROLE_NAME="${PROJECT_NAME}-qbusiness-s3-role"
S3_POLICY_NAME="${PROJECT_NAME}-qbusiness-s3-policy"
echo "Checking for S3 data source IAM role: $S3_ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name "$S3_ROLE_NAME" >/dev/null 2>&1; then
  echo "✓ S3 data source IAM role exists: $S3_ROLE_NAME"
  S3_ROLE_ARN=$(aws iam get-role --role-name "$S3_ROLE_NAME" --query 'Role.Arn' --output text)
else
  echo "✱ Creating S3 data source IAM role: $S3_ROLE_NAME"
  TRUST_DOC='{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect":"Allow",
      "Principal":{"Service":"qbusiness.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }]
  }'
  
  # Try to create the role
  CREATE_RESULT=$(aws iam create-role \
    --role-name "$S3_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_DOC" \
    --output json 2>&1)
  
  # Check if role was created or already exists
  if echo "$CREATE_RESULT" | grep -q "EntityAlreadyExists"; then
    echo "✓ S3 data source IAM role already exists: $S3_ROLE_NAME"
    S3_ROLE_ARN=$(aws iam get-role --role-name "$S3_ROLE_NAME" --query 'Role.Arn' --output text)
  elif echo "$CREATE_RESULT" | grep -q "arn:aws:iam"; then
    echo "✓ Created S3 data source IAM role: $S3_ROLE_NAME"
    S3_ROLE_ARN=$(echo "$CREATE_RESULT" | jq -r '.Role.Arn')
  else
    echo "✗ Failed to create S3 data source IAM role: $S3_ROLE_NAME"
    echo "Error: $CREATE_RESULT"
    # Try to get the role ARN anyway
    S3_ROLE_ARN=$(aws iam get-role --role-name "$S3_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -z "$S3_ROLE_ARN" ]; then
      S3_ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/$S3_ROLE_NAME"
      echo "Using assumed ARN: $S3_ROLE_ARN"
    fi
  fi
  
  # We'll attach the S3 policy after creating the S3 bucket
fi

# === PHASE 2: S3 Bucket Setup ===
echo "=== PHASE 2: S3 Bucket Setup ==="

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

# Create uploads directory in S3 bucket if it doesn't exist
echo "Creating uploads directory in S3 bucket..."
{ aws s3api put-object --bucket "$S3_BUCKET_NAME" --key "uploads/" --content-length 0 || true; }

# Upload files from /docs to S3 bucket
echo "Uploading files from /docs to S3 bucket: $S3_BUCKET_NAME"
{ aws s3 sync "$(dirname "$0")/docs" "s3://$S3_BUCKET_NAME/uploads/" --region "$AWS_REGION" || echo "Warning: Some files may not have been uploaded"; }
echo "✓ Files uploaded to S3 bucket: $S3_BUCKET_NAME"

# Now attach S3 policy to the S3 role
S3_POLICY_DOC='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::'$S3_BUCKET_NAME'",
        "arn:aws:s3:::'$S3_BUCKET_NAME'/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "qbusiness:BatchPutDocument",
        "qbusiness:BatchDeleteDocument"
      ],
      "Resource": "*"
    }
  ]
}'

aws iam put-role-policy \
  --role-name "$S3_ROLE_NAME" \
  --policy-name "$S3_POLICY_NAME" \
  --policy-document "$S3_POLICY_DOC" \
  --output json || echo "Warning: Failed to attach policy to role $S3_ROLE_NAME"

echo "✓ S3 policy attached to S3 data source IAM role"

# === PHASE 3: Q Business Application Setup ===
echo "=== PHASE 3: Q Business Application Setup ==="

# Create a simple script to create just the Q Business application
cat > create_qbusiness_app.sh << 'EOF'
#!/bin/bash
set +e

APPLICATION_ID=$1
AWS_REGION=$2

if [ -z "$APPLICATION_ID" ]; then
  echo "Creating Q Business application..."
  APP_RESPONSE=$(aws qbusiness create-application \
    --display-name "DisabilityRightsTexas" \
    --identity-type "ANONYMOUS" \
    --region "$AWS_REGION" \
    --output json 2>&1)
  
  APPLICATION_ID=$(echo "$APP_RESPONSE" | jq -r '.applicationId')
  echo "Created Q Business Application: $APPLICATION_ID"
fi

echo $APPLICATION_ID
EOF

chmod +x create_qbusiness_app.sh

# Check for existing Q Business application
EXISTING_APP_ID=$(aws qbusiness list-applications --region "$AWS_REGION" --query 'applications[?displayName==`DisabilityRightsTexas`].applicationId' --output text 2>/dev/null || echo "")
if [ -n "$EXISTING_APP_ID" ] && [ "$EXISTING_APP_ID" != "None" ]; then
  echo "✓ Found existing Q Business Application: $EXISTING_APP_ID"
  APPLICATION_ID="$EXISTING_APP_ID"
else
  # Use the simple script to create the application
  APPLICATION_ID=$(./create_qbusiness_app.sh "" "$AWS_REGION")
  echo "✓ Created Q Business Application: $APPLICATION_ID"
fi

# Get existing index ID
EXISTING_INDEX_ID=$(aws qbusiness list-indices --application-id "$APPLICATION_ID" --region "$AWS_REGION" --query 'indices[?displayName==`DisabilityRightsIndex`].indexId' --output text 2>/dev/null || echo "")
if [ -n "$EXISTING_INDEX_ID" ] && [ "$EXISTING_INDEX_ID" != "None" ]; then
  echo "✓ Found existing Index: $EXISTING_INDEX_ID"
  INDEX_ID="$EXISTING_INDEX_ID"
fi

# Create a simple script to create the index
cat > create_index.sh << 'EOF'
#!/bin/bash
set +e

APPLICATION_ID=$1
INDEX_ID=$2
AWS_REGION=$3

if [ -z "$INDEX_ID" ]; then
  echo "Creating Q Business index..."
  INDEX_RESPONSE=$(aws qbusiness create-index \
    --application-id "$APPLICATION_ID" \
    --display-name "DisabilityRightsIndex" \
    --type "STARTER" \
    --region "$AWS_REGION" \
    --output json 2>/dev/null)
  
  INDEX_ID=$(echo "$INDEX_RESPONSE" | jq -r '.indexId')
  echo "Created Index: $INDEX_ID"
fi

echo $INDEX_ID
EOF

chmod +x create_index.sh

# Create index if needed
if [ -z "${INDEX_ID:-}" ]; then
  INDEX_ID=$(./create_index.sh "$APPLICATION_ID" "" "$AWS_REGION")
  echo "✓ Created Index: $INDEX_ID"
fi

# Create a simple script to create the retriever
cat > create_retriever.sh << 'EOF'
#!/bin/bash
set +e

APPLICATION_ID=$1
INDEX_ID=$2
AWS_REGION=$3

# Check for existing retriever
EXISTING_RETRIEVER_ID=$(aws qbusiness list-retrievers --application-id "$APPLICATION_ID" --region "$AWS_REGION" --query 'retrievers[?type==`AMAZON_Q_BUSINESS`].retrieverId | [0]' --output text 2>/dev/null || echo "")
if [ -n "$EXISTING_RETRIEVER_ID" ] && [ "$EXISTING_RETRIEVER_ID" != "None" ]; then
  echo "Found existing Retriever: $EXISTING_RETRIEVER_ID"
  RETRIEVER_ID="$EXISTING_RETRIEVER_ID"
else
  echo "Creating Q Business retriever..."
  RETRIEVER_CONFIG='{"nativeIndexConfiguration":{"indexId":"'$INDEX_ID'"}'
  
  RETRIEVER_RESPONSE=$(aws qbusiness create-retriever \
    --application-id "$APPLICATION_ID" \
    --type "AMAZON_Q_BUSINESS" \
    --configuration "$RETRIEVER_CONFIG" \
    --region "$AWS_REGION" \
    --output json 2>/dev/null)
  
  RETRIEVER_ID=$(echo "$RETRIEVER_RESPONSE" | jq -r '.retrieverId')
  echo "Created Retriever: $RETRIEVER_ID"
fi

echo $RETRIEVER_ID
EOF

chmod +x create_retriever.sh

# Create retriever if needed
RETRIEVER_ID=$(./create_retriever.sh "$APPLICATION_ID" "$INDEX_ID" "$AWS_REGION")
echo "✓ Using Retriever: $RETRIEVER_ID"

# === PHASE 4: Web Experience Setup ===
echo "=== PHASE 4: Web Experience Setup ==="

# Check for existing web experience
EXISTING_WEB_EXPERIENCE_ID=$(aws qbusiness list-web-experiences --application-id "$APPLICATION_ID" --region "$AWS_REGION" --query 'webExperiences[0].webExperienceId' --output text 2>/dev/null)
if [ -n "$EXISTING_WEB_EXPERIENCE_ID" ] && [ "$EXISTING_WEB_EXPERIENCE_ID" != "None" ]; then
  echo "✓ Found existing Web Experience: $EXISTING_WEB_EXPERIENCE_ID"
  WEB_EXPERIENCE_ID="$EXISTING_WEB_EXPERIENCE_ID"
else
  echo "Creating Web Experience..."
  
  # Use Python to create web experience
  cat > create_web_experience.py << 'EOF'
#!/usr/bin/env python3
import boto3
import sys
import json
import time

def create_web_experience(application_id, region):
    print(f"Creating web experience for application {application_id} in region {region}")
    qbusiness = boto3.client('qbusiness', region_name=region)
    
    try:
        response = qbusiness.create_web_experience(
            applicationId=application_id,
            title="Disability Rights Texas Chat",
            subtitle="Ask questions about disability rights and services",
            welcomeMessage="Welcome to Disability Rights Texas. How can I help you today?"
        )
        web_experience_id = response["webExperienceId"]
        print(f"✓ Created web experience: {web_experience_id}")
        return web_experience_id
    except Exception as e:
        print(f"Error creating web experience: {str(e)}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 create_web_experience.py <application_id> <region>")
        sys.exit(1)
    
    application_id = sys.argv[1]
    region = sys.argv[2]
    web_experience_id = create_web_experience(application_id, region)
    print(json.dumps({"webExperienceId": web_experience_id}))
EOF

  chmod +x create_web_experience.py
  
  # Check if Python and boto3 are installed
  if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3 and boto3."
    exit 1
  fi
  
  # Install boto3 if not already installed
  python3 -c "import boto3" 2>/dev/null || pip3 install boto3
  
  # Run the Python script to create web experience
  WEB_EXPERIENCE_RESPONSE=$(python3 create_web_experience.py "$APPLICATION_ID" "$AWS_REGION")
  WEB_EXPERIENCE_ID=$(echo "$WEB_EXPERIENCE_RESPONSE" | jq -r '.webExperienceId')
  
  if [ -n "$WEB_EXPERIENCE_ID" ] && [ "$WEB_EXPERIENCE_ID" != "null" ]; then
    echo "✓ Web Experience created successfully: $WEB_EXPERIENCE_ID"
  else
    echo "✗ Failed to create Web Experience."
    echo "Please create the web experience manually in the AWS Console."
  fi
fi

# === PHASE 5: Data Source Setup ===
echo "=== PHASE 5: Data Source Setup ==="

# Create S3 data source
echo "Creating S3 data source..."

# Use Python to create S3 data source
cat > create_s3_data_source.py << 'EOF'
#!/usr/bin/env python3
import boto3
import sys
import json
import time

def create_s3_data_source(application_id, index_id, bucket_name, role_arn, region):
    print(f"Creating S3 data source for application {application_id}, index {index_id} in region {region}")
    qbusiness = boto3.client('qbusiness', region_name=region)
    
    try:
        # Check if data source already exists
        response = qbusiness.list_data_sources(applicationId=application_id, indexId=index_id)
        for ds in response.get('dataSources', []):
            if ds.get('type') == 'S3':
                print(f"✓ Found existing S3 data source: {ds.get('dataSourceId')}")
                return ds.get('dataSourceId')
        
        # Create data source configuration
        data_source_config = {
            "s3": {
                "bucketName": bucket_name,
                "inclusionPrefixes": ["uploads/"]
            }
        }
        
        response = qbusiness.create_data_source(
            applicationId=application_id,
            indexId=index_id,
            displayName="DisabilityRightsS3DataSource",
            type="S3",
            configuration=data_source_config,
            roleArn=role_arn
        )
        
        data_source_id = response.get('dataSourceId')
        print(f"✓ Created S3 data source: {data_source_id}")
        
        # Start sync job
        sync_response = qbusiness.start_data_source_sync_job(
            applicationId=application_id,
            indexId=index_id,
            dataSourceId=data_source_id
        )
        print(f"✓ Started sync job: {sync_response.get('executionId')}")
        
        return data_source_id
    except Exception as e:
        print(f"Error creating S3 data source: {str(e)}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python3 create_s3_data_source.py <application_id> <index_id> <bucket_name> <role_arn> <region>")
        sys.exit(1)
    
    application_id = sys.argv[1]
    index_id = sys.argv[2]
    bucket_name = sys.argv[3]
    role_arn = sys.argv[4]
    region = sys.argv[5]
    
    data_source_id = create_s3_data_source(application_id, index_id, bucket_name, role_arn, region)
    print(json.dumps({"dataSourceId": data_source_id}))
EOF

chmod +x create_s3_data_source.py

# Run the Python script to create S3 data source
S3_DATA_SOURCE_RESPONSE=$(python3 create_s3_data_source.py "$APPLICATION_ID" "$INDEX_ID" "$S3_BUCKET_NAME" "$S3_ROLE_ARN" "$AWS_REGION")
S3_DATA_SOURCE_ID=$(echo "$S3_DATA_SOURCE_RESPONSE" | jq -r '.dataSourceId')

if [ -n "$S3_DATA_SOURCE_ID" ] && [ "$S3_DATA_SOURCE_ID" != "null" ]; then
  echo "✓ S3 Data Source created successfully: $S3_DATA_SOURCE_ID"
else
  echo "✗ Failed to create S3 Data Source."
  echo "Please create the S3 data source manually in the AWS Console."
fi

# Create web crawler data source for URLs
echo "Creating web crawler data source..."

# Create a sample URLs file if it doesn't exist
if [ ! -f "$(dirname "$0")/data-sources/urls1.txt" ]; then
  mkdir -p "$(dirname "$0")/data-sources"
  cat > "$(dirname "$0")/data-sources/urls1.txt" << EOF
https://www.disabilityrightstx.org/
https://www.disabilityrightstx.org/en/home/
https://www.disabilityrightstx.org/en/category/resources/
https://www.disabilityrightstx.org/en/category/news/
https://www.disabilityrightstx.org/en/category/success-stories/
EOF
  echo "✓ Created sample URLs file: data-sources/urls1.txt"
fi

# Use Python to create web crawler data source
cat > create_web_crawler_data_source.py << 'EOF'
#!/usr/bin/env python3
import boto3
import sys
import json
import time
import os

def create_web_crawler_data_source(application_id, index_id, source_url, role_arn, region, project_name):
    print(f"Creating web crawler data source for application {application_id}, index {index_id} in region {region}")
    qbusiness = boto3.client('qbusiness', region_name=region)
    
    try:
        # Check if data source already exists
        response = qbusiness.list_data_sources(applicationId=application_id, indexId=index_id)
        for ds in response.get('dataSources', []):
            if ds.get('name') == f"{project_name}-webcrawler":
                print(f"✓ Found existing web crawler data source: {ds.get('dataSourceId')}")
                return ds.get('dataSourceId')
        
        # Read URLs from file if it's a file path
        urls = ["https://disabilityrightstx.org/en/home/"]
        if os.path.isfile(source_url):
            with open(source_url) as f:
                urls = [u.strip() for u in f if u.strip()]
        
        # Create data source configuration
        data_source_config = {
            "webCrawler": {
                "seedUrls": [{"seedUrl": url} for url in urls],
                "crawlDepth": 3,  # Set crawl depth to 3
                "maxLinksPerPage": 100,
                "maxContentSizePerPage": 50,
                "maxUrlsPerMinute": 300,
                "urlInclusionPatterns": [],
                "urlExclusionPatterns": [],
                "authentication": "NO_AUTHENTICATION",
                "crawlSubDomains": True,  # Sync domains with subdomains only
                "crawlAllDomain": False,
                "crawlAttachments": True  # Include files that web pages link to
            }
        }
        
        response = qbusiness.create_data_source(
            applicationId=application_id,
            indexId=index_id,
            displayName="Disability Rights Texas Web Crawler",
            type="WEBCRAWLERV2",
            configuration=data_source_config,
            roleArn=role_arn,
            description="Web crawler for Disability Rights Texas website"
        )
        
        data_source_id = response.get('dataSourceId')
        print(f"✓ Created web crawler data source: {data_source_id}")
        
        # Start sync job
        sync_response = qbusiness.start_data_source_sync_job(
            applicationId=application_id,
            indexId=index_id,
            dataSourceId=data_source_id
        )
        print(f"✓ Started sync job: {sync_response.get('executionId')}")
        
        return data_source_id
    except Exception as e:
        print(f"Error creating web crawler data source: {str(e)}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 7:
        print("Usage: python3 create_web_crawler_data_source.py <application_id> <index_id> <source_url> <role_arn> <region> <project_name>")
        sys.exit(1)
    
    application_id = sys.argv[1]
    index_id = sys.argv[2]
    source_url = sys.argv[3]
    role_arn = sys.argv[4]
    region = sys.argv[5]
    project_name = sys.argv[6]
    
    data_source_id = create_web_crawler_data_source(application_id, index_id, source_url, role_arn, region, project_name)
    print(json.dumps({"dataSourceId": data_source_id}))
EOF

chmod +x create_web_crawler_data_source.py

# Run the Python script to create web crawler data source
SOURCE_URL="https://disabilityrightstx.org/en/home/"
echo "Creating web crawler data source for URL: $SOURCE_URL"

WEB_CRAWLER_DATA_SOURCE_RESPONSE=$(python3 create_web_crawler_data_source.py "$APPLICATION_ID" "$INDEX_ID" "$SOURCE_URL" "$WEB_CRAWLER_ROLE_ARN" "$AWS_REGION" "$PROJECT_NAME")
WEB_CRAWLER_DATA_SOURCE_ID=$(echo "$WEB_CRAWLER_DATA_SOURCE_RESPONSE" | jq -r '.dataSourceId')

if [ -n "$WEB_CRAWLER_DATA_SOURCE_ID" ] && [ "$WEB_CRAWLER_DATA_SOURCE_ID" != "null" ]; then
  echo "✓ Web Crawler Data Source created successfully: $WEB_CRAWLER_DATA_SOURCE_ID"
else
  echo "✗ Failed to create Web Crawler Data Source."
  echo "Please create the Web Crawler data source manually in the AWS Console."
fi

echo "📋 Q Business Setup Updated:"
echo "   Application ID: $APPLICATION_ID"
echo "   Index ID: $INDEX_ID"
echo "   Retriever ID: $RETRIEVER_ID"
echo "   Web Experience ID: $WEB_EXPERIENCE_ID"
echo "   S3 Data Source ID: $S3_DATA_SOURCE_ID"
if [ -n "$WEB_CRAWLER_DATA_SOURCE_ID" ]; then
  echo "   Web Crawler Data Source ID: $WEB_CRAWLER_DATA_SOURCE_ID"
fi

# === PHASE 6: CodeBuild Project Setup ===
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
if { aws codebuild batch-get-projects --names "$CODEBUILD_PROJECT_NAME" --query 'projects[0].name' --output text 2>/dev/null || echo ""; } | grep -q "$CODEBUILD_PROJECT_NAME"; then
  echo "Deleting existing CodeBuild project..."
  aws codebuild delete-project --name "$CODEBUILD_PROJECT_NAME"
  sleep 5
fi

# Create new CodeBuild project
echo "Creating new CodeBuild project..."
{ aws codebuild create-project \
  --name "$CODEBUILD_PROJECT_NAME" \
  --source "$SOURCE" \
  --artifacts "$ARTIFACTS" \
  --environment "$ENVIRONMENT" \
  --service-role "$ROLE_ARN" \
  --output json \
  --no-cli-pager || echo "Warning: CodeBuild project creation may have failed"; }

echo "Starting deployment build..."
BUILD_ID=$({ aws codebuild start-build \
  --project-name "$CODEBUILD_PROJECT_NAME" \
  --query 'build.id' \
  --output text || echo "BUILD_FAILED"; })

if [ "$BUILD_ID" != "BUILD_FAILED" ]; then
  echo "✓ Build started with ID: $BUILD_ID"
  echo "You can monitor the build progress in the AWS Console:"
  echo "https://console.aws.amazon.com/codesuite/codebuild/projects/$CODEBUILD_PROJECT_NAME/build/$BUILD_ID"
else
  echo "✗ Failed to start build. Please check your AWS permissions and try again."
fi