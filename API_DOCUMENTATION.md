# API Documentation

This document outlines the API endpoints available in the Disability Rights Texas Amazon Q Business integration.

## Base URL

All API endpoints are relative to the base URL:
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod/
```

## Authentication

The API currently uses anonymous access mode for Amazon Q Business integration.

## Endpoints

### Chat API

Used to send chat messages to Amazon Q Business and receive responses.

**Endpoint:** `POST /chat`

**Request Body:**
```json
{
  "message": "string",
  "conversationId": "string",
  "applicationId": "string",
  "language": "string"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| message | string | Yes | The user's message or question |
| conversationId | string | No | Unique identifier for the conversation (generated if not provided) |
| applicationId | string | Yes | Amazon Q Business application ID |
| language | string | No | Language code (default: "EN") |

**Response:**
```json
{
  "messageId": "string",
  "conversationId": "string",
  "response": "string",
  "sources": [
    {
      "title": "string",
      "url": "string"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| messageId | string | Unique identifier for the message |
| conversationId | string | Unique identifier for the conversation |
| response | string | Amazon Q Business response text |
| sources | array | List of sources used to generate the response |

**Example:**
```bash
curl -X POST https://{api-id}.execute-api.{region}.amazonaws.com/prod/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What services does Disability Rights Texas provide?",
    "applicationId": "abc123def456"
  }'
```

### Feedback API

Used to submit feedback on Amazon Q Business responses.

**Endpoint:** `POST /applications/{applicationId}/conversations/{conversationId}/messages/{messageId}/feedback`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| applicationId | string | Yes | Amazon Q Business application ID |
| conversationId | string | Yes | Conversation identifier |
| messageId | string | Yes | Message identifier |

**Request Body:**
```json
{
  "feedback": "string",
  "rating": "number"
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| feedback | string | No | Text feedback about the response |
| rating | number | Yes | Numeric rating (typically 1-5) |

**Response:**
```json
{
  "success": true,
  "message": "Feedback submitted successfully"
}
```

**Example:**
```bash
curl -X POST https://{api-id}.execute-api.{region}.amazonaws.com/prod/applications/abc123def456/conversations/conv789/messages/msg456/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "feedback": "Very helpful response"
  }'
```

## Error Responses

All endpoints may return the following error responses:

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Authentication failed |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 500 | Internal Server Error |

Error response body:
```json
{
  "message": "Error description",
  "errorCode": "string"
}
```

## Rate Limits

- Chat API: 10 requests per second
- Feedback API: 20 requests per second

## Notes

- The API integrates with Amazon Q Business in the backend
- All responses are in JSON format
- CORS is enabled for all endpoints