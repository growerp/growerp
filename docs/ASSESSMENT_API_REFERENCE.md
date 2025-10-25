# GrowERP Assessment & Landing Page APIs - Complete Reference

## Overview

This document provides comprehensive API reference for the Assessment and Landing Page systems in GrowERP. All APIs support dual-ID lookup (system-wide unique IDs and tenant-unique pseudoIds) and enforce multi-tenant isolation.

## Base URL

```
http://localhost:8080/api/growerp
```

## Authentication

Most administrative operations require authentication via JWT token:

```
Authorization: Bearer <jwt_token>
```

Public operations (viewing published pages, submitting assessments) do not require authentication.

---

## Assessment APIs

### 1. Get Assessment

Retrieve a single assessment by ID or pseudoId.

**Endpoint:** `GET /assessment/get`

**Authentication:** Required (admin operations), Optional (public view)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `idOrPseudo` | string | ✓ | Assessment ID (system-wide) or pseudoId (tenant-unique, prefix with `pseudo_`) |
| `ownerPartyId` | string | ✓ | Owner party ID for authorization |

**Request Example:**

```bash
curl -X GET "http://localhost:8080/api/growerp/assessment/get" \
  -H "Authorization: Bearer <token>" \
  -d 'idOrPseudo=assessment_123&ownerPartyId=company_1'
```

**Response (Success - 200):**

```json
{
  "assessment": {
    "assessmentId": "assessment_123",
    "pseudoId": "prod_readiness_2024",
    "ownerPartyId": "company_1",
    "assessmentName": "Product Readiness Assessment",
    "description": "Comprehensive assessment of product readiness",
    "status": "ACTIVE",
    "createdDate": "2024-10-20T10:30:00Z",
    "lastModifiedDate": "2024-10-24T14:15:00Z"
  }
}
```

**Response (Not Found - 404):**

```json
{
  "error": "Assessment not found",
  "code": "NOT_FOUND"
}
```

---

### 2. List Assessments

Get paginated list of assessments for a tenant.

**Endpoint:** `GET /assessment/list`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ownerPartyId` | string | - | Owner party ID (required) |
| `status` | string | - | Filter by status: ACTIVE, INACTIVE, DRAFT |
| `pageNumber` | integer | 1 | Page number (1-based) |
| `pageSize` | integer | 20 | Results per page |

**Request Example:**

```bash
curl -X GET "http://localhost:8080/api/growerp/assessment/list" \
  -H "Authorization: Bearer <token>" \
  -d 'ownerPartyId=company_1&status=ACTIVE&pageNumber=1&pageSize=20'
```

**Response (Success - 200):**

```json
{
  "assessments": [
    {
      "assessmentId": "assessment_123",
      "pseudoId": "prod_readiness",
      "assessmentName": "Product Readiness",
      "status": "ACTIVE",
      "createdDate": "2024-10-20T10:30:00Z"
    },
    {
      "assessmentId": "assessment_124",
      "pseudoId": "market_fit",
      "assessmentName": "Market Fit",
      "status": "DRAFT",
      "createdDate": "2024-10-21T11:00:00Z"
    }
  ],
  "totalCount": 2,
  "pageCount": 1,
  "pageNumber": 1,
  "pageSize": 20
}
```

---

### 3. Create Assessment

Create a new assessment.

**Endpoint:** `POST /assessment/create`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentName` | string | ✓ | Name of assessment |
| `description` | string | | Assessment description/instructions |
| `status` | string | | Status: ACTIVE, INACTIVE, DRAFT (default: ACTIVE) |
| `ownerPartyId` | string | ✓ | Owner party ID |

**Request Example:**

```bash
curl -X POST "http://localhost:8080/api/growerp/assessment/create" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "assessmentName": "Sales Readiness",
    "description": "Assess team sales readiness",
    "status": "ACTIVE",
    "ownerPartyId": "company_1"
  }'
```

**Response (Success - 201):**

```json
{
  "assessmentId": "assessment_125",
  "pseudoId": "sales_readiness_2024",
  "message": "Assessment created successfully"
}
```

---

### 4. Update Assessment

Update assessment details.

**Endpoint:** `PUT /assessment/update`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentId` | string | ✓ | Assessment ID to update |
| `assessmentName` | string | | New name |
| `description` | string | | New description |
| `status` | string | | New status: ACTIVE, INACTIVE, DRAFT |
| `ownerPartyId` | string | ✓ | Owner party ID for authorization |

**Request Example:**

```bash
curl -X PUT "http://localhost:8080/api/growerp/assessment/update" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "assessmentId": "assessment_125",
    "assessmentName": "Updated Sales Readiness",
    "status": "INACTIVE",
    "ownerPartyId": "company_1"
  }'
```

**Response (Success - 200):**

```json
{
  "assessmentId": "assessment_125",
  "message": "Assessment updated successfully"
}
```

---

### 5. Delete Assessment

Delete assessment and all related entities (cascade).

**Endpoint:** `DELETE /assessment/delete`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentId` | string | ✓ | Assessment ID to delete |
| `ownerPartyId` | string | ✓ | Owner party ID for authorization |

**Request Example:**

```bash
curl -X DELETE "http://localhost:8080/api/growerp/assessment/delete" \
  -H "Authorization: Bearer <token>" \
  -d 'assessmentId=assessment_125&ownerPartyId=company_1'
```

**Response (Success - 200):**

```json
{
  "message": "Assessment deleted successfully",
  "deletedCount": 47
}
```

---

### 6. Submit Assessment

Submit completed assessment with respondent information and answers.

**Endpoint:** `POST /assessment/submit`

**Authentication:** Not required (public)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentId` | string | ✓ | Assessment ID being submitted |
| `answersData` | JSON string | ✓ | Answers: `{"questionId": "optionId", ...}` |
| `respondentName` | string | ✓ | Respondent's name |
| `respondentEmail` | string | ✓ | Respondent's email |
| `respondentPhone` | string | | Respondent's phone |
| `respondentCompany` | string | | Respondent's company |
| `ownerPartyId` | string | ✓ | Assessment owner (tenant) |

**Request Example:**

```bash
curl -X POST "http://localhost:8080/api/growerp/assessment/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "assessmentId": "assessment_123",
    "answersData": "{\"question_1\": \"option_1\", \"question_2\": \"option_2\"}",
    "respondentName": "Jane Smith",
    "respondentEmail": "jane@example.com",
    "respondentPhone": "+1234567890",
    "respondentCompany": "Acme Corp",
    "ownerPartyId": "company_1"
  }'
```

**Response (Success - 201):**

```json
{
  "resultId": "result_456",
  "pseudoId": "result_jane_smith_20241024",
  "score": 75.5,
  "leadStatus": "Warm",
  "message": "Assessment submitted successfully"
}
```

---

## Scoring APIs

### 1. Get Thresholds

Retrieve scoring thresholds for an assessment.

**Endpoint:** `GET /scoring/thresholds`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentId` | string | ✓ | Assessment ID |

**Request Example:**

```bash
curl -X GET "http://localhost:8080/api/growerp/scoring/thresholds" \
  -H "Authorization: Bearer <token>" \
  -d 'assessmentId=assessment_123'
```

**Response (Success - 200):**

```json
{
  "thresholds": [
    {
      "thresholdId": "threshold_1",
      "pseudoId": "cold_leads",
      "minScore": 0,
      "maxScore": 33,
      "leadStatus": "Cold",
      "description": "Not ready to engage"
    },
    {
      "thresholdId": "threshold_2",
      "pseudoId": "warm_leads",
      "minScore": 34,
      "maxScore": 66,
      "leadStatus": "Warm",
      "description": "Some potential"
    },
    {
      "thresholdId": "threshold_3",
      "pseudoId": "hot_leads",
      "minScore": 67,
      "maxScore": 100,
      "leadStatus": "Hot",
      "description": "Ready to convert"
    }
  ]
}
```

---

### 2. Calculate Score

Calculate score from assessment answers (internal).

**Endpoint:** `POST /scoring/calculate`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentId` | string | ✓ | Assessment ID |
| `answersData` | JSON string | ✓ | Answers: `{"questionId": "optionId", ...}` |

**Response (Success - 200):**

```json
{
  "score": 72.5
}
```

---

### 3. Update Thresholds

Update scoring thresholds for assessment.

**Endpoint:** `PUT /scoring/thresholds`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `assessmentId` | string | ✓ | Assessment ID |
| `thresholds` | array | ✓ | New thresholds array |
| `ownerPartyId` | string | ✓ | Owner party ID for authorization |

**Request Example:**

```bash
curl -X PUT "http://localhost:8080/api/growerp/scoring/thresholds" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "assessmentId": "assessment_123",
    "ownerPartyId": "company_1",
    "thresholds": [
      {"minScore": 0, "maxScore": 40, "leadStatus": "Cold"},
      {"minScore": 41, "maxScore": 70, "leadStatus": "Warm"},
      {"minScore": 71, "maxScore": 100, "leadStatus": "Hot"}
    ]
  }'
```

---

## Landing Page APIs

### 1. Get Landing Page

Retrieve a published landing page (public).

**Endpoint:** `GET /landing-page/get`

**Authentication:** Not required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `idOrPseudo` | string | ✓ | Page ID or pseudoId |
| `ownerPartyId` | string | | Owner party ID (for admin) |

**Request Example:**

```bash
curl -X GET "http://localhost:8080/api/growerp/landing-page/get?idOrPseudo=product_page"
```

**Response (Success - 200):**

```json
{
  "page": {
    "pageId": "page_789",
    "pseudoId": "product_page",
    "title": "Product Launch",
    "headline": "Is Your Product Ready?",
    "subheading": "Find out with our quick assessment",
    "assessmentId": "assessment_123",
    "status": "ACTIVE"
  },
  "sections": [
    {
      "sectionId": "section_1",
      "title": "Feature Completeness",
      "description": "Does your product have all required features?"
    }
  ],
  "credibility": {
    "creatorBio": "CEO with 20 years experience",
    "backgroundText": "Founded 3 successful startups",
    "statistics": ["100+ happy customers", "50M+ users served"]
  },
  "cta": {
    "buttonText": "Start Assessment",
    "estimatedTime": "5 minutes",
    "valuePromise": "Get your personalized readiness report"
  }
}
```

---

### 2. List Landing Pages

Get paginated list of landing pages (admin).

**Endpoint:** `GET /landing-page/list`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ownerPartyId` | string | - | Owner party ID (required) |
| `status` | string | - | Filter: ACTIVE, INACTIVE, DRAFT |
| `pageNumber` | integer | 1 | Page number |
| `pageSize` | integer | 20 | Results per page |

---

### 3. Create Landing Page

Create new landing page.

**Endpoint:** `POST /landing-page/create`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | string | ✓ | Page title |
| `hookType` | string | ✓ | frustration, results, or custom |
| `headline` | string | ✓ | Main headline |
| `subheading` | string | | Optional subheading |
| `assessmentId` | string | ✓ | Associated assessment |
| `privacyPolicyUrl` | string | | Privacy policy link |
| `ownerPartyId` | string | ✓ | Owner party ID |

---

### 4. Update Landing Page

Update landing page configuration.

**Endpoint:** `PUT /landing-page/update`

**Authentication:** Required

**Parameters:** Same as Create, plus `pageId` for identification.

---

### 5. Delete Landing Page

Delete landing page (cascade).

**Endpoint:** `DELETE /landing-page/delete`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required |
|-----------|------|----------|
| `pageId` | string | ✓ |
| `ownerPartyId` | string | ✓ |

---

### 6. Publish Landing Page

Publish landing page to make public.

**Endpoint:** `POST /landing-page/publish`

**Authentication:** Required

**Parameters:**

| Parameter | Type | Required |
|-----------|------|----------|
| `pageId` | string | ✓ |
| `ownerPartyId` | string | ✓ |

**Response:**

```json
{
  "pageId": "page_789",
  "pseudoId": "product_page",
  "publicUrl": "https://growerp.com/pages/product_page"
}
```

---

## Page Sections APIs

### Create Section

**Endpoint:** `POST /page-section/create`

**Parameters:**

| Parameter | Type | Required |
|-----------|------|----------|
| `pageId` | string | ✓ |
| `sectionTitle` | string | ✓ |
| `sectionDescription` | string | |
| `sectionImageUrl` | string | |
| `ownerPartyId` | string | ✓ |

### Update Section

**Endpoint:** `PUT /page-section/update`

### Delete Section

**Endpoint:** `DELETE /page-section/delete`

### List Sections

**Endpoint:** `GET /page-section/list`

**Parameters:**

| Parameter | Type | Required |
|-----------|------|----------|
| `pageId` | string | ✓ |

---

## Credibility APIs

### Create Credibility

**Endpoint:** `POST /credibility/create`

**Parameters:**

| Parameter | Type | Required |
|-----------|------|----------|
| `pageId` | string | ✓ |
| `creatorBio` | string | ✓ |
| `backgroundText` | string | |
| `creatorImageUrl` | string | |
| `ownerPartyId` | string | ✓ |

---

## Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| NOT_FOUND | 404 | Resource not found |
| UNAUTHORIZED | 401 | Authentication required |
| FORBIDDEN | 403 | Access denied (authorization failed) |
| INVALID_INPUT | 400 | Invalid parameter |
| CONFLICT | 409 | Resource already exists |
| INTERNAL_ERROR | 500 | Server error |

---

## Rate Limiting

API calls are rate-limited to prevent abuse:

- **Authenticated users:** 1000 requests/hour
- **Public endpoints:** 100 requests/hour per IP

---

## Examples

### Complete Assessment Submission Workflow

```bash
# 1. Get assessment to display
curl -X GET "http://localhost:8080/api/growerp/assessment/get" \
  -d 'idOrPseudo=prod_readiness&ownerPartyId=company_1'

# 2. Submit completed assessment
curl -X POST "http://localhost:8080/api/growerp/assessment/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "assessmentId": "assessment_123",
    "answersData": "{\"q1\": \"opt1\", \"q2\": \"opt2\"}",
    "respondentName": "John Doe",
    "respondentEmail": "john@example.com",
    "ownerPartyId": "company_1"
  }'

# 3. Get thresholds for results display
curl -X GET "http://localhost:8080/api/growerp/scoring/thresholds" \
  -H "Authorization: Bearer <token>" \
  -d 'assessmentId=assessment_123'
```

---

## Support

For API support, contact: api-support@growerp.com
