# DevOps Career AI - Hackathon Project

A web application showcasing **Best Use of AI Personas** through specialized DevOps career guidance, powered by Amazon Q Business.

## Hackathon Project: Best Use of AI Personas

This project demonstrates innovative AI persona implementation for DevOps career development. Each persona provides specialized expertise:

🏗️ **DevOps Architect** - Infrastructure design and cloud architecture guidance
⚙️ **DevOps Engineer** - CI/CD pipelines, automation, and deployment strategies
👨🏫 **Career Mentor** - DevOps career paths and skill development roadmaps
💻 **Technical Interviewer** - Interview preparation and hands-on scenarios

### Key Features:
- **4 Distinct AI Personas** with specialized knowledge domains
- **Context-Aware Responses** based on selected persona
- **Age-Appropriate Communication** (child/adult modes)
- **Bilingual Support** (English/Spanish)
- **Real-time Persona Switching** within conversations

## Repository Structure

```
/
├── frontend/               # React frontend application
│   ├── public/             # Public assets
│   ├── src/                # Source code
│   │   ├── Assets/         # Images and SVG files
│   │   ├── Components/     # React components
│   │   ├── services/       # API services
│   │   └── utilities/      # Helper functions and contexts
│   ├── .env                # Environment variables
│   └── package.json        # Dependencies
├── DEPLOYMENT.md           # Deployment instructions
└── template.json           # CloudFormation template for backend
```

## Features

- **AI-Powered Chat**: Utilizes Amazon Q Business to answer questions about disability rights
- **Document Knowledge Base**: Integrates with S3-stored documents and website content
- **Feedback System**: Allows users to rate responses for continuous improvement
- **Accessibility**: Built with accessibility in mind for users with disabilities

## Technology Stack

- **Frontend**: React.js
- **Backend**: AWS Lambda, API Gateway
- **AI Service**: Amazon Q Business
- **Data Sources**: S3 documents, Web crawler
- **Deployment**: AWS CloudFormation, AWS Amplify

## Getting Started

1. See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed setup instructions
2. Configure Amazon Q Business as described in the deployment guide
3. Deploy the backend using CloudFormation
4. Set up and deploy the frontend using AWS Amplify

## Development

To run the application locally:

```bash
cd frontend
npm install
# Create .env file with required environment variables
npm start
```
