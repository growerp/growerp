# Landing Page System: Executive Summary & Quick Start

**Version:** 1.0  
**Date:** October 23, 2025  
**Status:** Architecture & Planning Complete ✅

---

## Overview

A comprehensive multi-tenant landing page and assessment system for GrowERP that:

1. ✅ **Captures qualified leads** through a 15-question assessment
2. ✅ **Scores leads dynamically** (Cold/Warm/Hot) based on best practices answers
3. ✅ **Routes to differentiated sales funnels** based on score + budget preference
4. ✅ **Integrates with Marketing** for lead management and tracking
5. ✅ **Provides admin tools** for landing page configuration and analytics
6. ✅ **Supports multiple landing pages** per tenant with full isolation

---

## Key Features

### For End Users (Public)

```
Landing Page
├─ Hook/Headline (Frustration or Results-based)
├─ Value Proposition (3 configurable areas)
├─ Credibility Section (Creator bio + stats)
└─ Primary CTA ("Start the Quiz")
    ↓
Assessment (15 Questions in 3 Steps)
├─ Step 1: Contact Information (Name, Email, Phone)
├─ Step 2: Best Practices (10 Yes/No questions → Score)
└─ Step 3: Qualification (5 Big Five questions)
    ↓
Dynamic Results
├─ Score Reveal (75% Ready → "Warm Foundations")
├─ 3 Customized Insights
├─ Qualification Summary
└─ Thank You + Dynamic CTA
    ├─ Hot Leads: "Schedule 1:1 Consultation"
    ├─ Warm Leads: "Join Group Presentation"
    └─ Cold Leads: "Watch Learning Resources"
```

### For Admins (Authentication Required)

```
Landing Page Builder
├─ Create/Edit/Delete landing pages
├─ Configure hero section
├─ Define value areas (3 sections)
├─ Add credibility/bio
└─ Set primary CTA

Assessment Builder
├─ Edit 15 questions
├─ Configure answer weights
├─ Set scoring thresholds
└─ Map insights to answers

Leads Dashboard
├─ Real-time metrics (Total, This Month, Avg Score)
├─ Lead distribution (Cold/Warm/Hot)
├─ Filterable lead list
├─ Individual lead details
└─ Export functionality

Multi-Landing-Page Support
├─ Each company can have multiple LPs
├─ Each LP has its own assessment config
├─ Each LP tracks its own leads
└─ Full tenant isolation
```

---

## Architecture Highlights

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Frontend** | Flutter + BLoC | Cross-platform, GrowERP standard |
| **Frontend State** | flutter_bloc ^8.1.4 | Separation of concerns, testability |
| **API Client** | Retrofit + Dio | Type-safe REST, GrowERP standard |
| **Backend** | Moqui Framework | Multi-tenant, extensible, existing in GrowERP |
| **Database** | PostgreSQL | Relational, ACID-compliant, scalable |
| **Integration** | REST APIs | Public endpoints for landing pages, admin for management |

### Package Structure

```
Flutter Packages:
├─ landing_page/               ← NEW - Public landing pages & assessment
│  └─ Example with flutter_survey
│
├─ admin/ (extended)           ← ADD - Landing page admin module
│  ├─ Landing Page CRUD
│  ├─ Assessment builder
│  ├─ Insights mapper
│  └─ Leads dashboard
│
└─ growerp_marketing (enhanced)
   └─ Lead/Opportunity tracking from assessments

Backend (Moqui):
├─ Component: growerp/
│  ├─ Services:
│  │  ├─ LandingPageServices.xml
│  │  ├─ AssessmentServices.xml
│  │  └─ LeadServices.xml
│  │
│  └─ Entities:
│     ├─ LandingPageEntities.xml
│     └─ AssessmentEntities.xml
│
└─ Component: mantle-udm/
   └─ Opportunity (extended with assessment fields)
```

### Data Flow Diagram

```
Public User
    ↓
[Landing Page Screen]
    ├─ Load: GET /api/v1/landing-page/{pseudoId}
    └─ Display static content + CTA button
    ↓
[Assessment Flow - 3 Steps]
    ├─ Step 1: Capture contact info
    ├─ Step 2: Answer 10 best practices (Yes/No)
    │  └─ Calculate score: (Yes Count / 10) × 100%
    ├─ Step 3: Answer 5 qualification questions
    │  └─ Determine lead status: Cold (0-40), Warm (41-70), Hot (71-100)
    └─ Submit: POST /api/v1/assessment/submit
    ↓
[Results Flow - 4 Screens]
    ├─ Screen 1: Score Reveal (85% Ready)
    ├─ Screen 2: 3 Insights (from weak practices)
    ├─ Screen 3: Qualification Summary
    └─ Screen 4: Thank You + Dynamic CTA
       ├─ IF Hot + High Budget → Consultation booking
       ├─ IF Warm or Medium Budget → Presentation signup
       └─ IF Cold or Low Budget → Content (video/blog)
    ↓
[Backend Processes]
    ├─ Create AssessmentResult record
    ├─ Create Opportunity in Marketing (for lead tracking)
    ├─ Send lead notification email
    └─ Return Lead object to frontend
    ↓
[Admin Dashboard - Leads View]
    └─ Lead appears in filterable list with score, status, insights
```

---

## Implementation Roadmap

### Phase 1: Core Foundation (Weeks 1-2)
- [x] Architecture design (THIS DOCUMENT)
- [ ] Create `landing_page` Flutter package
- [ ] Implement LandingPageModel, AssessmentModel, LeadModel
- [ ] Build LandingPageService, AssessmentScoringService
- [ ] Create LandingPageBloc and AssessmentBloc
- [ ] Implement LandingPageScreen (static hero section)
- [ ] Create backend entities (LandingPageEntities.xml, AssessmentEntities.xml)
- [ ] Implement LandingPageServices.xml
- [ ] Create seed data for sample landing page
- **Deliverable:** Basic landing page displays, admin can create LPs

### Phase 2: Assessment Flow (Weeks 3-4)
- [ ] Implement ContactInfoScreen (3 fields)
- [ ] Implement BestPracticesScreen (10 scrollable questions)
- [ ] Implement QualificationScreen (Big Five questions)
- [ ] Wire BLoC event handling for all 3 steps
- [ ] Implement scoring calculation logic
- [ ] Implement insight generation service
- [ ] Create AssessmentServices.xml
- [ ] Add assessment builder to admin package
- **Deliverable:** Users can complete full 15-question assessment

### Phase 3: Dynamic Results (Weeks 5-6)
- [ ] Implement ScoreRevealScreen (gauge visualization)
- [ ] Implement InsightsScreen (3 insights)
- [ ] Implement QualificationSummaryScreen
- [ ] Implement ThankYouScreen with dynamic CTA
- [ ] Build score gauge/thermometer widget
- [ ] Wire up multi-page results navigation
- [ ] Implement CTA routing logic (consultation/presentation/resources)
- [ ] Add insights mapper to admin
- [ ] Add scoring configuration UI to admin
- **Deliverable:** Results pages show with dynamic CTAs based on score + budget

### Phase 4: Lead Integration (Weeks 7-8)
- [ ] Implement LeadCaptureService
- [ ] Create Opportunity entity integration
- [ ] Implement LeadServices.xml
- [ ] Add lead capture to assessment completion flow
- [ ] Create leads dashboard in admin package
- [ ] Implement lead filtering, search, export
- [ ] Add lead detail view
- [ ] Configure lead notification emails
- **Deliverable:** Leads captured in Marketing package, visible on dashboard

### Phase 5: Multi-Tenant & Scaling (Weeks 9-10)
- [ ] Enforce tenant isolation on all queries
- [ ] Implement company-level access controls
- [ ] Add multi-landing-page support to admin UI
- [ ] Implement caching for landing page content
- [ ] Add database indexing and query optimization
- [ ] Performance testing (target: <200ms response time)
- [ ] Security audit (GDPR, multi-tenant isolation)
- [ ] Comprehensive documentation
- **Deliverable:** Production-ready, multi-tenant system

---

## Database Schema Summary

### Core Tables

```
LandingPage (1 per configuration)
├─ pseudoId, companyPartyId, title, hookType, headline, etc.

ValueArea (3 per landing page)
├─ pseudoId, landingPageId, title, description, imageUrl

CredibilityInfo (1 per landing page)
├─ pseudoId, landingPageId, creatorBio, backgroundText, creatorImageUrl

CredibilityStatistic (multiple per credibility)
├─ pseudoId, credibilityId, statistic

PrimaryCTA (1 per landing page)
├─ pseudoId, landingPageId, buttonText, estimatedTime, cost, valuePromise

Assessment (1 per landing page)
├─ pseudoId, landingPageId, maxScore

AssessmentQuestion (15 per assessment)
├─ pseudoId, assessmentId, type (contact|best_practice|qualification)
├─ question, fieldType (text|email|radio|dropdown), mandatory

AssessmentQuestionOption (2-4 per question)
├─ pseudoId, questionId, optionText, optionWeight

ScoringThreshold (3 per assessment: Cold/Warm/Hot)
├─ pseudoId, assessmentId, status, minScore, maxScore

AssessmentResult (1 per submitted assessment)
├─ pseudoId, assessmentId, score, status
├─ name, email, phone, location
├─ answersJson, insightsJson, nextStepType

Opportunity (Marketing package, extended)
├─ opportunityId, assessmentResultId, assessmentScore
├─ assessmentStatus, landingPageId, recommendedAction
```

---

## API Endpoints (Summary)

### Public Endpoints (No Auth)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/v1/landing-page/{pseudoId}` | Get landing page content |
| GET | `/api/v1/landing-page/{id}/assessment` | Get questions |
| POST | `/api/v1/assessment/submit` | Submit answers |

### Admin Endpoints (Auth Required)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/v1/admin/landing-pages` | List landing pages |
| POST | `/api/v1/admin/landing-pages` | Create new LP |
| PUT | `/api/v1/admin/landing-pages/{id}` | Update LP |
| DELETE | `/api/v1/admin/landing-pages/{id}` | Delete LP |
| GET | `/api/v1/admin/assessment-leads` | List leads |
| GET | `/api/v1/admin/assessment-leads/{id}` | Lead details |
| PUT | `/api/v1/admin/assessment-leads/{id}/status` | Update lead status |
| POST | `/api/v1/admin/assessment-leads/export` | Export CSV/JSON |

---

## Success Metrics

### Phase 1 Completion
- ✅ Landing page displays without errors
- ✅ Admin can create landing pages
- ✅ Admin can configure basic settings

### Phase 2 Completion
- ✅ Users can complete all 15 questions
- ✅ Form validation works
- ✅ Assessment data submitted successfully

### Phase 3 Completion
- ✅ Score calculated correctly
- ✅ Results display with proper styling
- ✅ CTAs show based on score + budget

### Phase 4 Completion
- ✅ Leads captured in database
- ✅ Appear in marketing leads list
- ✅ Admin can view/filter/export leads

### Phase 5 Completion
- ✅ <200ms API response time
- ✅ Multi-tenant isolation verified
- ✅ 100% uptime in staging
- ✅ Security audit passed

---

## Key Design Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|-----------|
| Flutter for LP | Cross-platform consistency | Web needs separate build |
| BLoC pattern | GrowERP standard, separation of concerns | Learning curve for new devs |
| Multi-LP per company | Marketing flexibility | Complexity in admin |
| JSON answers storage | Flexible schema, easy versioning | Complex querying |
| Async lead capture | Non-blocking UX | Race condition risk (mitigated) |
| Public API endpoints | Easy embedding, white-labeling | Rate limiting required |
| Dynamic CTA routing | Personalization, sales efficiency | Maintenance complexity |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Multi-tenant data leak** | Critical | Query isolation + access controls + audit logging |
| **Assessment logic errors** | High | Comprehensive unit + integration tests |
| **Lead duplication** | Medium | Email uniqueness constraint + duplicate check |
| **Performance degradation** | Medium | Caching + indexing + async processing |
| **API rate limiting** | Low | Public endpoints rate-limited per IP |

---

## Next Steps

### For Architecture Review
1. Review `LANDING_PAGE_IMPLEMENTATION_PLAN.md` for complete requirements
2. Review `LANDING_PAGE_ARCHITECTURE.md` for technical details
3. Review `LANDING_PAGE_ADMIN_GUIDE.md` for admin workflows and API

### For Development Kickoff
1. Create Flutter `landing_page` package with base structure
2. Set up Moqui entities and services
3. Create admin module in existing admin package
4. Implement Phase 1 (Core Foundation)
5. Follow implementation roadmap phases

### For Team Preparation
1. Familiarize team with BLoC pattern (if new)
2. Review GrowERP architecture standards
3. Set up development environment with Flutter + Moqui
4. Plan sprint ceremonies and testing strategy

---

## Documentation Files Created

✅ **LANDING_PAGE_IMPLEMENTATION_PLAN.md** (40+ pages)
   - Complete 10-part specification
   - System components, architecture, phases
   - Database schema, API reference, deployment checklist

✅ **LANDING_PAGE_ARCHITECTURE.md** (25+ pages)
   - System diagrams and component relationships
   - State management flows, data validation
   - Performance optimization, testing strategy
   - Code examples and deployment checklist

✅ **LANDING_PAGE_ADMIN_GUIDE.md** (30+ pages)
   - Admin dashboard walkthrough
   - Step-by-step creation workflows
   - Complete REST API reference (11 endpoints)
   - Error codes and examples

✅ **LANDING_PAGE_IMPLEMENTATION_PLAN.md** (THIS FILE)
   - Executive summary
   - Quick reference guide
   - Implementation roadmap

---

## Questions & Clarifications

### Q: Can companies have more than one landing page?
**A:** Yes! Each company can have unlimited landing pages. Each LP can have different:
- Headlines, hooks, value propositions
- Assessment questions (custom scoring rules)
- CTAs and next step routing
- Lead tracking and analytics

### Q: How are leads captured?
**A:** Leads are automatically created as Opportunities in the Marketing package when they submit an assessment. They appear in the leads list with:
- Score (0-100%)
- Status (Cold/Warm/Hot)
- 3 Insights
- Qualification details (growth stage, desired outcome, etc.)
- Recommended next action

### Q: Can assessment questions be customized?
**A:** Yes! Admins can:
- Edit all 10 best practices questions
- Edit all 5 qualification questions
- Set answer weights for scoring
- Configure scoring thresholds (Cold/Warm/Hot ranges)
- Map insights to answers

### Q: How is the score calculated?
**A:** Simple formula: (Yes Count / 10) × 100%
- Only the 10 best practices questions count for scoring
- Contact info (step 1) and qualification (step 3) don't affect score
- Score determines if lead is Cold (0-40), Warm (41-70), or Hot (71-100)

### Q: What makes a lead "Hot" vs "Warm" vs "Cold"?
**A:** Two factors:
1. **Score:** Best practices adherence (0-100%)
2. **Budget:** Solution preference from question 4 (step 3)

**Routing Logic:**
- Hot (71-100%) + High Budget → "Schedule 1:1 Consultation"
- Warm (41-70%) or Medium Budget → "Join Group Presentation"
- Cold (0-40%) or Low Budget → "Access Learning Resources"

### Q: Can we see who submitted but doesn't complete?
**A:** For MVP, only submitted/completed assessments are captured. Future enhancement could track partial submissions.

### Q: How do we ensure data privacy?
**A:** 
- GDPR-compliant consent on landing page
- Privacy policy link required
- Encrypted data transmission (HTTPS)
- Configurable data retention per company
- Lead export for compliance
- Audit logging of admin actions

---

## Contact & Support

For questions about this specification:
- **Architecture:** See LANDING_PAGE_ARCHITECTURE.md
- **Admin Workflows:** See LANDING_PAGE_ADMIN_GUIDE.md
- **API Reference:** See LANDING_PAGE_ADMIN_GUIDE.md Part 2
- **Detailed Requirements:** See LANDING_PAGE_IMPLEMENTATION_PLAN.md

---

**Document Version:** 1.0  
**Created:** October 23, 2025  
**Status:** ✅ Architecture Complete - Ready for Development  

**Next Document:** Begin Phase 1 Implementation Planning
