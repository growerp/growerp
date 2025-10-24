# Landing Page Admin Guide & API Reference

**Version:** 1.0  
**Audience:** Developers, System Administrators, Marketing Teams

---

## Part 1: Admin Dashboard Guide

### 1.1 Dashboard Overview

The admin dashboard provides complete control over landing pages, assessments, and leads. Access via:
- **URL:** `https://app.growerp.com/admin/landing-pages`
- **Permission:** Company Admin or Marketing Manager role required

### Dashboard Main View

```
┌────────────────────────────────────────────────────────────────────┐
│ GrowERP Admin → Landing Pages                            [+ New]   │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│ Tabs: [All Landing Pages] [My Leads] [Performance] [Settings]     │
│                                                                    │
│ Search: [_________________]  Filter: [Status ▼] [Date Range ▼]   │
│                                                                    │
├────────────────────────────────────────────────────────────────────┤
│  Landing Page               Status    Leads   Date Created         │
├────────────────────────────────────────────────────────────────────┤
│  ERP Readiness Quiz        Published  1,234   Oct 15, 2025        │
│  [Preview] [Edit] [...menu]                                       │
│                                                                    │
│  Sleep Optimization Test   Published    456   Oct 10, 2025        │
│  [Preview] [Edit] [...menu]                                       │
│                                                                    │
│  Beta: New Process LP       Draft       12    Oct 20, 2025        │
│  [Preview] [Edit] [...menu]                                       │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### 1.2 Creating a New Landing Page

**Step 1: Click [+ New Landing Page]**

```
┌─────────────────────────────────────────────────────────────┐
│ Create New Landing Page                              [×]     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Basic Information                                           │
│ ├─ Title*                                                 │
│ │  [ERP Readiness Assessment            ]                 │
│ │                                                         │
│ ├─ URL Slug*                                              │
│ │  [erp-readiness-assessment           ]  ← auto-filled   │
│ │                                                         │
│ ├─ Hook Type*                                             │
│ │  ○ Frustration Hook (Problem-focused)                  │
│ │    "Tired of Spreadsheet Management?"                  │
│ │                                                         │
│ │  ○ Results Hook (Solution-focused)                     │
│ │    "Ready to Transform Your Business?"                 │
│ │                                                         │
│ └─ Privacy Policy URL                                     │
│    [https://example.com/privacy          ]                │
│                                                             │
│ [Continue] [Cancel]                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Step 2: Configure Landing Page Content**

```
┌─────────────────────────────────────────────────────────────┐
│ Edit: ERP Readiness Assessment                      [×]     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ [ Hero Section ]                                            │
│                                                             │
│ Headline*                                                   │
│ [Is Your Business Ready for Modern ERP?                ]   │
│                                                             │
│ Subheading*                                                 │
│ [Answer 15 quick questions to discover your ERP     ]     │
│ [readiness and get personalized recommendations     ]     │
│                                                             │
│ [ Value Proposition ]                                       │
│                                                             │
│ Area 1: Title*                                              │
│ [Operational Efficiency                              ]     │
│ Description: [Streamline workflows...               ]     │
│ Image: [Upload] [https://cdn.example.com/img1.jpg   ]     │
│                                                             │
│ Area 2: Title*                                              │
│ [Financial Visibility                                ]     │
│ Description: [Real-time reporting...                ]     │
│ Image: [Upload]                                             │
│                                                             │
│ Area 3: Title*                                              │
│ [Team Collaboration                                 ]     │
│ Description: [Break down data silos...              ]     │
│ Image: [Upload]                                             │
│                                                             │
│ [ Credibility Section ]                                     │
│                                                             │
│ Creator Bio*                                                │
│ [Lorem ipsum...                                     ] (500) │
│                                                             │
│ Background/Experience*                                      │
│ [10+ years in ERP implementation...                 ] (500) │
│                                                             │
│ Supporting Statistics (3 maximum)                            │
│ [+] "85% of businesses report 30% cost reduction"        │
│ [+] "Average ROI achieved in 18 months"                   │
│                                                             │
│ Creator Photo: [Upload]                                     │
│                                                             │
│ [ Primary CTA ]                                             │
│                                                             │
│ Button Text: [Start the Quiz                         ]     │
│ Estimated Time: [3 minutes                          ]     │
│ Cost: [Free                                          ]     │
│ Value Promise: [Get immediate recommendations       ]     │
│                                                             │
│ [Save Draft] [Preview] [Publish]                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Step 3: Build Assessment**

```
┌─────────────────────────────────────────────────────────────┐
│ Assessment Builder                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ [ Step 1: Contact Information ]                            │
│                                                             │
│ Question 1: Name (Mandatory)                               │
│ Type: Text Input                                            │
│ [Edit] [Delete]                                             │
│                                                             │
│ Question 2: Email Address (Mandatory)                      │
│ Type: Email Input                                           │
│ [Edit] [Delete]                                             │
│                                                             │
│ Question 3: Phone Number (Optional)                        │
│ Type: Phone Input                                           │
│ [Edit] [Delete]                                             │
│                                                             │
│ ────────────────────────────────────────────────           │
│                                                             │
│ [ Step 2: Best Practices (10 Questions) ]                  │
│                                                             │
│ [+] Add Question                                            │
│                                                             │
│ Question 1: "Do you automate inter-departmental...?"       │
│ Type: Yes/No                                                │
│ Answer Weights: Yes=10 | No=0                              │
│ [Edit] [Delete]                                             │
│                                                             │
│ Question 2: "Do all employees rely on..."                  │
│ Type: Yes/No                                                │
│ Answer Weights: Yes=10 | No=0                              │
│ [Edit] [Delete]                                             │
│                                                             │
│ [... 8 more questions ...]                                 │
│                                                             │
│ ────────────────────────────────────────────────           │
│                                                             │
│ [ Step 3: Qualification (Big Five) ]                       │
│                                                             │
│ Question 1: "Growth Stage" (Mandatory)                     │
│ Type: Multiple Choice                                       │
│ Options:                                                    │
│   ○ Rapidly scaling startup (0-50M)                        │
│   ○ Established mid-market (50-500M)                       │
│   ○ Large enterprise (500M+)                               │
│   ○ Non-profit/government                                  │
│ [Edit] [Delete]                                             │
│                                                             │
│ Question 2: "Desired Outcome" (Mandatory)                  │
│ Question 3: "Primary Obstacle" (Mandatory)                 │
│ Question 4: "Solution Preference" (Mandatory)              │
│ Question 5: "Anything Else?" (Optional)                    │
│                                                             │
│ [Save Assessment] [Preview Test]                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Step 4: Configure Scoring & Insights**

```
┌─────────────────────────────────────────────────────────────┐
│ Scoring & Insights Configuration                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ [ Scoring Thresholds ]                                      │
│                                                             │
│ Total Questions in Scoring: 10 (Best Practices)            │
│                                                             │
│ Status: COLD                                                │
│ ├─ Score Range: [0] to [40] points                         │
│ ├─ CTA Type: Learning Resources                            │
│ ├─ CTA Button: [View Learning Resources]                   │
│ └─ CTA Link: [https://example.com/learn/erp]               │
│                                                             │
│ Status: WARM                                                │
│ ├─ Score Range: [41] to [70] points                        │
│ ├─ CTA Type: Group Presentation                            │
│ ├─ CTA Button: [Register for Webinar]                      │
│ └─ CTA Link: [https://events.example.com/webinar]          │
│                                                             │
│ Status: HOT                                                 │
│ ├─ Score Range: [71] to [100] points                       │
│ ├─ CTA Type: Consultation                                  │
│ ├─ CTA Button: [Schedule Consultation]                     │
│ └─ CTA Link: [https://calendly.com/demo]                   │
│                                                             │
│ [ Insights Mapping ]                                        │
│                                                             │
│ Insight 1:                                                  │
│ [Focus on centralizing customer data across...     ] (200) │
│                                                             │
│ Insight 2:                                                  │
│ [Real-time reporting will transform your...       ] (200) │
│                                                             │
│ Insight 3 (Conditional):                                    │
│ IF Question 4 = "No" THEN:                                 │
│ [Ensure inventory visibility is top priority...   ] (200) │
│ ELSE:                                                       │
│ [Continue optimizing your inventory systems...    ] (200) │
│                                                             │
│ [Save Configuration]                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Landing Page Management

#### Viewing All Landing Pages

```
Filters Available:
├─ Status: Draft | Published | Archived
├─ Created By: [User dropdown]
├─ Date Range: [From] [To]
└─ Search: By title or slug

Sorting:
├─ By Leads (High to Low)
├─ By Date (Newest First)
├─ By Status
└─ By Title (A-Z)
```

#### Preview Landing Page

Click **[Preview]** to see public rendering:

```
┌──────────────────────────────────┐
│     Landing Page Preview         │
├──────────────────────────────────┤
│                                  │
│  Is Your Business Ready?         │  ← Headline
│  for Modern ERP?                 │
│                                  │
│  Answer 15 quick questions to    │  ← Subheading
│  discover your readiness...      │
│                                  │
│  Operational Efficiency ✓        │  ← Value Areas
│  Financial Visibility ✓          │
│  Team Collaboration ✓            │
│                                  │
│  [Credibility Blurb with image]  │
│                                  │
│  ┌──────────────────────────┐    │
│  │ START THE QUIZ           │    │  ← CTA
│  │ 3 minutes • Free • Get   │    │
│  │ Immediate Recommendations│    │
│  └──────────────────────────┘    │
│                                  │
│  [Privacy Policy]                │  ← Friction Minimizer
│                                  │
└──────────────────────────────────┘

✓ Desktop View    ✓ Mobile View    [← Back]
```

#### Publish Landing Page

```
┌─────────────────────────────────────────┐
│ Publish Landing Page                    │
├─────────────────────────────────────────┤
│                                         │
│ Are you ready to publish?               │
│                                         │
│ Status: Draft → Published               │
│                                         │
│ Public URL will be:                     │
│ https://landing.growerp.com/            │
│   /your-company/erp-readiness-quiz      │
│                                         │
│ Leads captured: 0                       │
│                                         │
│ Share this URL via:                     │
│ - Email campaign                        │
│ - Social media                          │
│ - Your website                          │
│ - Ads (Google, Facebook)                │
│                                         │
│ ☐ I've tested the assessment           │
│ ☐ I've verified the CTA links          │
│ ☐ Privacy policy is configured         │
│                                         │
│ [Cancel] [Publish]                      │
│                                         │
└─────────────────────────────────────────┘
```

### 1.4 Leads Management Dashboard

#### Leads Overview Tab

```
┌──────────────────────────────────────────────────────────┐
│ Assessment Leads                                         │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ METRICS                                                  │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐           │
│ │  Total     │ │  This Month │ │  Avg Score │           │
│ │   1,234    │ │     156     │ │   62%      │           │
│ └────────────┘ └────────────┘ └────────────┘           │
│                                                          │
│ DISTRIBUTION                                             │
│ ┌─────────────────────────────────────┐               │
│ │ HOT (71-100)      240 (20%)  [████░░]                │
│ │ WARM (41-70)      433 (35%)  [███████░]              │
│ │ COLD (0-40)       561 (45%)  [█████████░]            │
│ └─────────────────────────────────────┘               │
│                                                          │
│ BY LANDING PAGE                                          │
│ Landing Page 1: 450 leads                               │
│ Landing Page 2: 320 leads                               │
│ Landing Page 3: 464 leads                               │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

#### Leads List Tab

```
Filters:
├─ Status: [All ▼]  [HOT] [WARM] [COLD]
├─ Landing Page: [All ▼]
├─ Date Range: [From] [To]
├─ Score: [Min] to [Max]
└─ Search: [_________________]

Table Headers: [Sortable]
├─ Name
├─ Email
├─ Score
├─ Status
├─ Landing Page
├─ Submitted
└─ Actions

┌───────────────────────────────────────────────┐
│ Name      Email           Score  Status  Date │
├───────────────────────────────────────────────┤
│ John Doe  john@...        85%    HOT     22 Oct
│ [View] [Export] [Status ▼]                   │
│                                              │
│ Jane Smith jane@...       52%    WARM    21 Oct
│ [View] [Export] [Status ▼]                   │
│                                              │
│ Bob Jones bob@...         28%    COLD    20 Oct
│ [View] [Export] [Status ▼]                   │
│                                              │
│ ← [1] [2] [3] [4] →                         │
└───────────────────────────────────────────────┘
```

#### View Lead Details

```
┌─────────────────────────────────────┐
│ Lead Details: John Doe              │
├─────────────────────────────────────┤
│                                     │
│ CONTACT INFORMATION                 │
│ Name: John Doe                      │
│ Email: john@example.com             │
│ Phone: +1 (555) 123-4567           │
│ Location: San Francisco, CA         │
│                                     │
│ ASSESSMENT RESULTS                  │
│ Score: 85%                          │
│ Status: HOT                         │
│ Landing Page: ERP Readiness Quiz    │
│ Submitted: Oct 22, 2025 @ 2:34 PM   │
│                                     │
│ INSIGHTS                            │
│ ✓ Focus on centralizing customer   │
│   data across all systems           │
│                                     │
│ ✓ Real-time reporting will         │
│   transform your business decisions │
│                                     │
│ ✓ Mobile access is critical for    │
│   team efficiency                   │
│                                     │
│ QUALIFICATION DETAILS               │
│ Growth Stage: Mid-market            │
│ Desired Outcome: Reduce costs 15%   │
│ Primary Obstacle: Internal          │
│   resistance to change              │
│ Solution Preference: Vendor-        │
│   managed implementation            │
│ Additional Notes: "Urgent timeline" │
│                                     │
│ NEXT STEPS                          │
│ Recommended: 1:1 Consultation       │
│ Status: Not Yet Contacted           │
│ [Update Status ▼]                   │
│ Last Updated: -                     │
│                                     │
│ ACTIONS                             │
│ [Send Email] [Add Note] [Export]    │
│ [Delete Lead] [Back]                │
│                                     │
└─────────────────────────────────────┘
```

---

## Part 2: REST API Reference (Dual-ID Support)

### Base URL
```
Production:  https://api.growerp.com/v1
Development: http://localhost:8080/api/v1
```

### Authentication
All admin endpoints require Bearer token in header:
```
Authorization: Bearer {jwt_token}
```

Public endpoints do not require authentication.

### Dual-ID Strategy
- All endpoints support BOTH `entityId` (system-wide) and `pseudoId` (tenant-unique)
- Use whichever is more convenient: `/page/{pageId}` OR `/page/{pseudoId}`
- Backend logic tries exact match first, then falls back to pseudoId lookup
- Admin UI always displays `pseudoId` for user convenience

---

### Public Endpoints (No Auth, Dual-ID Support)

#### 1. GET `/page/{pageId|pseudoId}` OR `/page/{pageId|pseudoId}`

Retrieve page configuration for public display. Supports both ID types.

**Parameters:**
- `pageId` or `pseudoId` (path, required): Page identifier (either type works)

**Examples:**
```
GET /page/p_page_20251023_001          (using system ID)
GET /page/page_product_readiness       (using pseudo ID)
```

**Response:** `200 OK`
```json
{
  "data": {
    "pageId": "p_page_20251023_001",
    "pseudoId": "page_product_readiness",
    "companyPartyId": "comp_acme",
    "title": "Product Readiness Assessment",
    "hookType": "results",
    "headline": "Discover Your Readiness Level",
    "subheading": "Answer our survey to get insights...",
    "sections": [
      {
        "sectionId": "sec_001",
        "pseudoId": "s_section_1",
        "title": "Current State",
        "description": "Tell us about your business",
        "imageUrl": "https://cdn.example.com/current.jpg",
        "sequenceNum": 1
      }
    ],
    "credibility": {
      "credibilityId": "cred_001",
      "pseudoId": "cred_company_info",
      "creatorBio": "10+ years of industry experience...",
      "backgroundText": "Helped 500+ organizations...",
      "supportingStatistics": [
        "95% customer satisfaction",
        "Average ROI: 18 months"
      ],
      "creatorImageUrl": "https://cdn.example.com/creator.jpg"
    },
    "primaryCTA": {
      "ctaId": "cta_001",
      "pseudoId": "cta_primary",
      "buttonText": "Start Survey",
      "estimatedTime": "5 minutes",
      "cost": "Free",
      "valuePromise": "Get personalized insights"
    },
    "privacyPolicyUrl": "https://example.com/privacy"
  }
}
```

**Error Responses:**
- `404 Not Found`: Page does not exist
- `410 Gone`: Page has been archived

---

#### 2. GET `/page/{pageId|pseudoId}/survey` 

Retrieve survey questions for a page. Supports both ID types.

**Parameters:**
- `pageId` or `pseudoId` (path, required): Page identifier

**Examples:**
```
GET /page/p_page_20251023_001/survey
GET /page/page_product_readiness/survey
```

**Response:** `200 OK`
```json
{
  "data": {
    "surveyId": "s_survey_20251023_001",
    "pseudoId": "survey_product_q2025",
    "pageId": "p_page_20251023_001",
    "maxScore": 100,
    "questions": [
      {
        "questionId": "q_q001_20251023",
        "pseudoId": "q_001",
        "type": "info",
        "question": "What is your company name?",
        "fieldType": "text",
        "mandatory": true,
        "sequenceNum": 1
      },
      {
        "questionId": "q_q002_20251023",
        "pseudoId": "q_002",
        "type": "info",
        "question": "What is your email?",
        "fieldType": "email",
        "mandatory": true,
        "sequenceNum": 2
      },
      {
        "questionId": "q_q003_20251023",
        "pseudoId": "q_003",
        "type": "survey",
        "question": "Do you have automated processes?",
        "options": [
          {"text": "Yes", "value": "yes", "weight": 10},
          {"text": "No", "value": "no", "weight": 0}
        ],
        "mandatory": true,
        "sequenceNum": 3
      }
    ]
  }
}
```

---

#### 3. POST `/survey/submit`

Submit completed survey and generate results. Supports both ID types.

**Request Body:**
```json
{
  "pageId": "p_page_20251023_001",    // OR use "pseudoId"
  "infoAnswers": {
    "q_001": "John Doe",
    "q_002": "john@example.com",
    "q_003": "Acme Corp"
  },
  "surveyAnswers": {
    "q_004": "Yes",
    "q_005": "No",
    // ... more answers
  },
  "qualificationAnswers": {
    "q_015": "Growing rapidly",
    "q_016": "Improve efficiency"
    // ... more answers
  }
}
    "q9": "Yes - Data-driven forecasting",
    "q10": "Yes - Automated compliance",
    "q11": "No - Limited mobile access",
    "q12": "Yes - Real-time KPI tracking",
    "q13": "Yes - Synchronized data"
  },
  "qualificationAnswers": {
    "q14": "Established mid-market firm (50-500M revenue)",
    "q15": "Reduce operational costs by 15%+",
    "q16": "Uncertainty about total cost/ROI",
    "q17": "Modular SaaS solution our internal team can mostly manage (Medium Budget)",
    "q18": "We need rapid deployment within 6 months"
  }
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "assessmentResultId": "result_001",
    "score": 75,
    "status": "Warm",
    "insights": [
      "Focus on centralizing your customer data across all departments to eliminate silos",
      "Real-time reporting will transform your financial decision-making capabilities",
      "Implement mobile-first access to improve team efficiency and remote work capability"
    ],
    "nextStepType": "presentation",
    "nextStepCTA": {
      "title": "Join Our Group Presentation",
      "description": "Learn how our modular SaaS approach scales with your business growth",
      "buttonText": "Register for Webinar",
      "link": "https://events.example.com/modular-saas-webinar"
    },
    "qualificationSummary": {
      "growthStage": "Established mid-market firm",
      "desiredOutcome": "Reduce operational costs by 15%+",
      "primaryObstacle": "Uncertainty about total cost/ROI",
      "solutionPreference": "Modular SaaS",
      "additionalNotes": "We need rapid deployment within 6 months"
    }
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid or missing fields
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email format is invalid",
    "field": "contactInfo.email",
    "statusCode": 400
  }
}
```

- `409 Conflict`: Duplicate lead (email already submitted)
```json
{
  "error": {
    "code": "DUPLICATE_LEAD",
    "message": "This email has already submitted an assessment for this landing page",
    "existingLeadId": "result_002",
    "statusCode": 409
  }
}
```

- `422 Unprocessable Entity`: Business logic error
```json
{
  "error": {
    "code": "INVALID_ASSESSMENT",
    "message": "This landing page does not have an active assessment",
    "statusCode": 422
  }
}
```

---

### Admin Endpoints (Requires Auth)

#### 4. GET `/admin/landing-pages`

List all landing pages for authenticated company.

**Query Parameters:**
- `page` (optional): Page number, default 0
- `pageSize` (optional): Items per page, default 20
- `status` (optional): Filter by status (draft, published, archived)
- `search` (optional): Search by title or slug
- `sortBy` (optional): Sort field (title, createdAt, leads, score)
- `sortOrder` (optional): asc or desc

**Response:** `200 OK`
```json
{
  "data": {
    "items": [
      {
        "pseudoId": "lp_001",
        "title": "ERP Readiness Assessment",
        "slug": "erp-readiness-assessment",
        "status": "published",
        "leads": {
          "total": 1234,
          "thisMonth": 156,
          "status": {
            "cold": 561,
            "warm": 433,
            "hot": 240
          }
        },
        "createdAt": "2025-10-15T10:30:00Z",
        "updatedAt": "2025-10-23T14:22:00Z",
        "createdBy": {
          "userPartyId": "user_001",
          "name": "Marketing Manager"
        },
        "publicUrl": "https://landing.growerp.com/company-slug/erp-readiness-assessment"
      }
    ],
    "pagination": {
      "page": 0,
      "pageSize": 20,
      "total": 45,
      "totalPages": 3
    }
  }
}
```

---

#### 5. POST `/admin/landing-pages`

Create a new landing page.

**Request Body:**
```json
{
  "title": "ERP Readiness Assessment",
  "hookType": "frustration",
  "headline": "Is Your Business Ready for Modern ERP?",
  "subheading": "Answer 15 quick questions to discover your ERP readiness...",
  "privacyPolicyUrl": "https://example.com/privacy",
  "valueAreas": [
    {
      "title": "Operational Efficiency",
      "description": "Streamline workflows...",
      "imageUrl": "https://cdn.example.com/op.jpg"
    },
    {
      "title": "Financial Visibility",
      "description": "Real-time reporting...",
      "imageUrl": "https://cdn.example.com/fin.jpg"
    },
    {
      "title": "Team Collaboration",
      "description": "Break down silos...",
      "imageUrl": "https://cdn.example.com/collab.jpg"
    }
  ],
  "credibility": {
    "creatorBio": "10+ years of ERP experience...",
    "backgroundText": "I've helped 500+ companies...",
    "creatorImageUrl": "https://cdn.example.com/creator.jpg",
    "supportingStatistics": [
      "85% see 30% cost reduction",
      "18 month average ROI",
      "92% satisfaction rating"
    ]
  },
  "primaryCTA": {
    "buttonText": "Start the Quiz",
    "estimatedTime": "3 minutes",
    "cost": "Free",
    "valuePromise": "Get immediate recommendations"
  }
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "pseudoId": "lp_002",
    "title": "ERP Readiness Assessment",
    "slug": "erp-readiness-assessment-1",
    "status": "draft",
    "createdAt": "2025-10-23T16:45:00Z"
  }
}
```

---

#### 6. PUT `/admin/landing-pages/{pseudoId}`

Update an existing landing page.

**Parameters:**
- `pseudoId` (path, required): Landing page ID

**Request Body:** Same structure as POST (partial updates supported)

**Response:** `200 OK`
```json
{
  "data": {
    "pseudoId": "lp_001",
    "title": "ERP Readiness Assessment - Updated",
    "updatedAt": "2025-10-23T17:00:00Z"
  }
}
```

---

#### 7. DELETE `/admin/landing-pages/{pseudoId}`

Delete/archive a landing page.

**Parameters:**
- `pseudoId` (path, required): Landing page ID
- `archive` (query, optional): If true, archive instead of delete, default true

**Response:** `204 No Content` or `200 OK`
```json
{
  "message": "Landing page archived successfully"
}
```

---

#### 8. GET `/admin/assessment-leads`

List assessment leads with filtering.

**Query Parameters:**
- `landingPageId` (optional): Filter by landing page
- `status` (optional): cold, warm, hot
- `score` (optional): min-max format, e.g., "60-80"
- `fromDate` (optional): ISO date string
- `toDate` (optional): ISO date string
- `page` (optional): Page number
- `pageSize` (optional): Items per page
- `search` (optional): Search by name or email
- `sortBy` (optional): name, score, date, status
- `sortOrder` (optional): asc or desc

**Response:** `200 OK`
```json
{
  "data": {
    "items": [
      {
        "assessmentResultId": "result_001",
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+1 (555) 123-4567",
        "location": "San Francisco, CA",
        "score": 85,
        "status": "Hot",
        "landingPageId": "lp_001",
        "landingPageTitle": "ERP Readiness Assessment",
        "submittedAt": "2025-10-22T14:30:00Z",
        "insights": [
          "Focus on centralizing customer data",
          "Real-time reporting benefits",
          "Mobile access improvements"
        ],
        "nextStepType": "consultation",
        "growthStage": "Mid-market",
        "desiredOutcome": "Reduce costs 15%+",
        "opportunityId": "opp_001",
        "opportunityStatus": "new_lead"
      }
    ],
    "pagination": {
      "page": 0,
      "pageSize": 20,
      "total": 1234,
      "totalPages": 62
    }
  }
}
```

---

#### 9. GET `/admin/assessment-leads/{resultId}`

Get single lead details.

**Response:** `200 OK`
```json
{
  "data": {
    "assessmentResultId": "result_001",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1 (555) 123-4567",
    "location": "San Francisco, CA",
    "score": 85,
    "status": "Hot",
    "landingPageId": "lp_001",
    "submittedAt": "2025-10-22T14:30:00Z",
    "allAnswers": {
      "bestPractices": {
        "q4": "Yes - We have workflow automation",
        "q5": "No - Data silos across departments",
        // ... 8 more answers
      },
      "qualification": {
        "q13": "Established mid-market firm",
        "q14": "Reduce operational costs",
        // ... 3 more answers
      }
    },
    "insights": [
      "Focus on centralizing customer data across all systems",
      "Real-time reporting will transform business decisions",
      "Mobile access is critical for team efficiency"
    ],
    "nextStepType": "consultation",
    "nextStepCTA": {
      "title": "Schedule 1:1 Consultation",
      "link": "https://calendly.com/demo"
    },
    "opportunityId": "opp_001",
    "opportunityStatus": "new_lead",
    "notes": [
      {
        "createdAt": "2025-10-23T09:15:00Z",
        "createdBy": "sales_user",
        "text": "Called - very interested, schedule follow-up"
      }
    ]
  }
}
```

---

#### 10. PUT `/admin/assessment-leads/{resultId}/opportunity-status`

Update the lead's opportunity status.

**Request Body:**
```json
{
  "status": "contacted",
  "notes": "Left voicemail, waiting for callback"
}
```

**Allowed Statuses:**
- `new_lead`: Initial state
- `contacted`: Sales reached out
- `qualified`: Determined to be qualified
- `in_discussion`: Active negotiation
- `won`: Converted to customer
- `lost`: No longer interested
- `archived`: Hidden from list

**Response:** `200 OK`
```json
{
  "data": {
    "resultId": "result_001",
    "opportunityStatus": "contacted"
  }
}
```

---

#### 11. POST `/admin/assessment-leads/export`

Export leads as CSV or JSON.

**Request Body:**
```json
{
  "format": "csv",
  "filters": {
    "landingPageId": "lp_001",
    "status": "hot",
    "fromDate": "2025-10-01",
    "toDate": "2025-10-31"
  },
  "fields": [
    "name", "email", "phone", "score", "status", 
    "landingPageTitle", "growthStage", "desiredOutcome",
    "submittedAt"
  ]
}
```

**Response:** `200 OK`
```
Content-Type: text/csv
Content-Disposition: attachment; filename="leads-export-2025-10-23.csv"

Name,Email,Phone,Score,Status,Landing Page,Growth Stage,Desired Outcome,Submitted
John Doe,john@example.com,+1 (555) 123-4567,85,Hot,ERP Readiness,Mid-market,Reduce costs,2025-10-22 14:30
...
```

---

## Error Codes Reference

| Code | HTTP | Meaning | Solution |
|------|------|---------|----------|
| `VALIDATION_ERROR` | 400 | Invalid input data | Check required fields and formats |
| `AUTHENTICATION_FAILED` | 401 | Missing/invalid token | Provide valid JWT token |
| `PERMISSION_DENIED` | 403 | User lacks permission | Use admin account |
| `NOT_FOUND` | 404 | Resource doesn't exist | Verify ID |
| `DUPLICATE_LEAD` | 409 | Duplicate email submission | User already submitted |
| `INVALID_ASSESSMENT` | 422 | Assessment logic error | Check assessment configuration |
| `RATE_LIMITED` | 429 | Too many requests | Wait before retrying |
| `SERVER_ERROR` | 500 | Internal server error | Contact support |

---

**Document Version:** 1.0  
**Last Updated:** October 23, 2025
