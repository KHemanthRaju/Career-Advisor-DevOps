# Disability Rights Texas - Amazon Q Business Integration
## Deployment Guide

This document outlines the steps to deploy both the backend and frontend components of the Disability Rights Texas Amazon Q Business integration.

## Backend Deployment

### 1. Set up Amazon Q Business

1. Go to the AWS console and search for "Amazon Q Business"
2. Set up an account for the lite version of Amazon Q Business
3. Create a new application:
   - Click "Create application"
   - Enter an application name
   - Select "Anonymous Mode"
   - Click "Create"

### 2. Configure Data Sources

1. After application creation, navigate to "Data sources" in the left sidebar
2. Add an index:
   - Click "Add an Index"
   - Provide an index name
   - Select "Starter package"
   - Click "Add an Index"

3. Upload documents to S3:
   - Go to S3 service
   - Create or select a bucket
   - Upload DRTx documents to the bucket

4. Add S3 as a data source:
   - Return to Amazon Q Business
   - Click "Add data source"
   - Select "Amazon S3" and click the + symbol
   - Enter a data source name
   - For IAM Role, select "Recommended option"
   - In sync scope, browse S3 and select your bucket
   - Set sync run schedule to "Run On Demand"
   - Click "Add data source"
   - Click "Sync now"

5. Add web crawler data source:
   - Click "Add data source"
   - Select "Web crawler" and provide a name
   - Enter source URL: "https://disabilityrightstx.org/en/home/"
   - Choose recommended IAM role
   - Set to sync domains with subdomains only
   - Set crawl depth to 3
   - Enable "Crawl index files and attachments"
   - Set sync frequency to "Run on Demand"
   - Click "Add data source" and sync (this takes 25-30 minutes)

6. Optional: Configure logging
   - Go to "Admin Controls and guardrails" in left sidebar
   - Set up log delivery to CloudWatch logs if needed

### 3. Deploy CloudFormation Stack

1. In the template.json file, replace the application_id placeholder with your Amazon Q Business application ID
2. Upload the template.json file to CloudFormation to create the backend APIs

## Frontend Deployment

### 1. Prerequisites

1. Install Node.js and npm:
   - Download from https://nodejs.org
   - Verify installation with:
     ```
     node -v
     npm -v
     ```

### 2. Local Setup

1. Navigate to the frontend directory:
   ```
   cd frontend
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Configure environment variables:
   - Create a `.env` file with the following variables:
     ```
     # API Configuration
     REACT_APP_BASE_API_ENDPOINT={ApiEndpoint}
     REACT_APP_API_ENDPOINT={ChatEndpoint}
     REACT_APP_FEEDBACK_ENDPOINT={FeedbackEndpoint}
     REACT_APP_AWS_REGION=us-west-2
     REACT_APP_LAMBDA_FUNCTION={ChatLambdaFunction}
     REACT_APP_LAMBDA_FEEDBACK_FUNCTION={FeedbackLambdaFunction}
     REACT_APP_APPLICATION_ID={Q_Business_application_id}
     REACT_APP_DEFAULT_LANGUAGE=EN
     ```
   - Replace placeholders with values from CloudFormation stack outputs

4. Initialize Amplify (follow Amplify documentation)

5. Test locally:
   ```
   npm start
   ```

### 3. Production Deployment with AWS Amplify

1. Build the application:
   ```
   npm run build
   ```

2. Create deployment package:
   ```
   cd build
   zip -r nj-ai-app-build.zip ./*
   ```

3. Deploy to AWS Amplify:
   - Open AWS Amplify Console
   - Click "Create new app"
   - Select "Deploy without Git" and click next
   - Enter an application name
   - Upload the build zip file
   - Click "Deploy"

4. Access your deployed application using the URL provided by Amplify

## Troubleshooting

- If data sources fail to sync, check IAM permissions
- For frontend connection issues, verify environment variables are correctly set
- Check CloudWatch logs for backend errors