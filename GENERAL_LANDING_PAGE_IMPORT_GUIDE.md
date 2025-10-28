# General Landing Page and Assessment Import Guide

**File**: `moqui/runtime/component/growerp/data/GeneralLandingPageAssessmentImport.xml`

This Moqui XML import file creates a complete general business readiness assessment landing page and accompanying 15-question assessment. The template can be customized for any type of business by modifying the text, categories, and answer options.

---

## Overview

The import file consists of **5 main components**:

### 1. Landing Page
- **ID**: `GENERAL_READINESS_LP`
- **Pseudo ID**: `general-business-readiness`
- **Hook**: "Are you ready to unlock your business's full potential?"
- **Subheading**: "Answer a few questions to find out why you might be facing challenges..."

### 2. Landing Page Sections (5 Sections)

#### Section 1: Value Proposition Intro
- **Type**: `value_proposition`
- **Title**: "Three Key Areas for Business Success"
- **Content**: Introduction to the three key areas for transformation

#### Section 2: Operational Efficiency
- **Type**: `key_area`
- **Focus**: Process optimization, resource allocation, operational excellence
- **Customizable**: Replace with any business pillar (e.g., Sales, Marketing, Product)

#### Section 3: Customer Engagement
- **Type**: `key_area`
- **Focus**: Customer relationships, satisfaction, experience
- **Customizable**: Adjust for your business model (B2B, B2C, SaaS, etc.)

#### Section 4: Scalable Growth
- **Type**: `key_area`
- **Focus**: Sustainable expansion, scaling capabilities
- **Customizable**: Align with growth strategy

### 3. Credibility Section (3 Elements)

Each credibility element builds trust:

#### Who Created This?
- **Type**: `who_created`
- **Placeholders**: `[Your Name/Company]`, `[Your Title]`
- **Customize**: Add your company information

#### Our Background
- **Type**: `background`
- **Content**: Professional experience and project history
- **Customize**: Update with your actual background (years, projects, industries)

#### Research & Statistics
- **Type**: `research`
- **Placeholders**: `[Common Problem]`, `[Key Success Factor]`
- **Data**: 85% stat and 3X multiplier (customize with your research)

### 4. Call to Action
- **Button Text**: "Start the Readiness Quiz Now!"
- **Action**: Navigates to `/assessment`
- **Message**: Time (3 min), Cost (free), Benefit (immediate recommendations)
- **Customizable**: Change button text, timing, or action target

### 5. Assessment (15 Questions Total)

#### Part A: Contact Information (3 Questions)
- Full name (required)
- Email address (required)
- Phone number (optional)

#### Part B: Best Practices Questions (10 Questions)

1. **Current Situation** (Stagnant/Slow Growth/Rapid Growth)
2. **Operational Efficiency** (Poor/Fair/Good/Excellent)
3. **Customer Engagement** (Very Dissatisfied to Very Satisfied)
4. **Data Management** (Siloed to Well Integrated)
5. **Process Standardization** (Ad Hoc to Well Standardized)
6. **Technology Infrastructure** (Legacy to Modern & Integrated)
7. **Team Capability** (Low to High)
8. **Leadership Support** (Low to Strong)
9-10. Two additional best practice questions (customizable)

#### Part C: Qualifying Questions (5 Questions)

1. **Desired Outcome** (Multiple choice: Revenue, Customer satisfaction, Operations)
2. **Obstacle** (Single choice: Workflows, Visibility, Technology, Budget, Staff)
3. **Solution Preference** (Education/Training, Consulting, Implementation, Software)
4. **Timeline** (Immediate, Soon, Future, Just exploring)
5. **Open Box** (Free text: Budget, urgency, additional context)

---

## Data Structure

### Entity Relationships

```
LandingPage
├── LandingPageSection[] (5 sections)
├── CredibilityElement[] (3 elements)
└── CallToAction (1 CTA)

Assessment
└── AssessmentQuestion[] (16 questions)
    └── AssessmentQuestionOption[] (multiple per question)
```

### Key Fields

**Landing Page Fields**:
- `pageId`: Unique identifier (e.g., `GENERAL_READINESS_LP`)
- `pseudoId`: URL-friendly identifier (e.g., `general-business-readiness`)
- `headline`: Main hook/heading
- `subheading`: Secondary message
- `title`: Page title
- `description`: Page description

**Section Fields**:
- `sectionType`: Type of section (`value_proposition`, `key_area`, etc.)
- `sequenceNum`: Display order (1, 2, 3, ...)
- `title`: Section heading
- `description`: Section content

**Question Fields**:
- `questionType`: Input type (`text_input`, `single_choice`, `multiple_choice`, `text_area`, `email_input`)
- `sectionType`: Question category (`contact_info`, `best_practices`, `qualifying`)
- `required`: Whether question is mandatory (`Y`/`N`)
- `sequenceNum`: Question order

**Question Option Fields**:
- `optionValue`: The answer choice text
- `description`: Explanation of the option
- `sequenceNum`: Order among options

---

## Usage

### Loading the Import

To load this data into your Moqui instance:

```bash
# From the moqui directory
java -jar moqui.war load types=seed,seed-initial,install no-run-es
```

Or selectively load just this file:

```bash
java -jar moqui.war data-load=runtime/component/growerp/data/GeneralLandingPageAssessmentImport.xml
```

### Viewing the Landing Page

Once loaded, access the landing page at:
```
/landingpage?pageId=GENERAL_READINESS_LP
```

Or using the pseudo ID:
```
/landingpage?pseudoId=general-business-readiness
```

---

## Customization Guide

### Change the Three Key Areas

Edit the three `key_area` sections to match your business pillars:

**For a SaaS Company**:
- Pillar 1: Product-Market Fit
- Pillar 2: Customer Success
- Pillar 3: Growth & Retention

**For a Manufacturing Company**:
- Pillar 1: Supply Chain Efficiency
- Pillar 2: Quality Control
- Pillar 3: Workforce Development

**For a Healthcare Provider**:
- Pillar 1: Patient Care Quality
- Pillar 2: Operational Efficiency
- Pillar 3: Compliance & Safety

### Update Credibility Section

Replace placeholder text:
- `[Your Name/Company]` → Your actual company name
- `[Your Title]` → Your professional title
- `[Common Problem]` → A statistic relevant to your industry
- `[Key Success Factor]` → The key factor for success in your industry

Example for E-commerce:
```
"85% of online retailers struggle with inventory accuracy..."
"Organizations prioritizing customer data integration are 3X more likely..."
```

### Modify Question Options

Change answer choices to match your business context:

**Example - Service Industry**:
```xml
<growerp.assessment.AssessmentQuestionOption
    optionValue="Service Delivery Quality"
    questionId="GENERAL_Q_OBSTACLE"
    .../>
```

### Add Custom Questions

To add a new question, create a new `AssessmentQuestion` entity:

```xml
<growerp.assessment.AssessmentQuestion
    questionId="GENERAL_Q_CUSTOM_1"
    pseudoId="custom-question"
    assessmentId="GENERAL_READINESS_ASSESS"
    sequenceNum="17"
    questionType="single_choice"
    sectionType="best_practices"
    question="Your custom question here?"
    required="Y"
    createdByUserId="admin"
    createdDate="${growerp.now()}"/>
```

---

## Question-to-Section Mapping

| Section | Question Type | Count | Purpose |
|---------|---|---|---|
| Contact Info | Text/Email | 3 | Lead capture |
| Best Practices | Multiple choice | 10 | Score calculation |
| Qualifying | Single/Multiple choice, Text | 5 | Sales qualification |
| **Total** | | **16** | Complete assessment |

---

## Results Scoring (Backend Implementation)

Based on best practices questions, implement scoring logic:

- **Questions 1-2**: Measure business maturity (30% weight)
- **Questions 3-4**: Measure customer/data readiness (30% weight)
- **Questions 5-7**: Measure operational capability (30% weight)
- **Question 8**: Measure team capability (10% weight)

**Score Ranges**:
- **0-25**: Not Ready - Need foundational improvements
- **26-50**: Early Stage - Some progress, significant gaps remain
- **51-75**: Ready - Capable with targeted support
- **76-100**: Very Ready - Positioned for success

---

## Integration Points

### Connect to Results Page

After assessment completion, redirect to:
```
/assessment-results?assessmentId=GENERAL_READINESS_ASSESS&score={calculatedScore}
```

### CRM Integration

Capture responses in CRM system:
- Contact info → Lead creation
- Qualifying questions → Lead scoring
- Open box question → Notes/comments

### Email Follow-up

Send customized follow-up emails based on score:
- Low score: Educational resources
- Medium score: Consultation offer
- High score: Premium solution pitch

---

## File Statistics

- **Lines**: 786
- **Landing Pages**: 1
- **Sections**: 5
- **Credibility Elements**: 3
- **CTAs**: 1
- **Assessments**: 1
- **Questions**: 16
- **Question Options**: 30+
- **Total Data Records**: 50+

---

## Notes

- All IDs use meaningful prefixes (`GENERAL_Q_`, `GENERAL_LP_`, etc.)
- Pseudo IDs use kebab-case for URL compatibility
- All records include `createdByUserId="admin"` and `createdDate` timestamp
- The `${growerp.now()}` variable is evaluated at import time
- Questions include `description` fields for context
- All entities follow Growerp naming conventions

---

## Troubleshooting

**Question not appearing**:
- Check `sequenceNum` values are unique and sequential
- Verify `sectionType` matches assessment structure

**Options not showing**:
- Ensure `questionId` matches parent question's ID
- Check `sequenceNum` for display order

**Landing page not loading**:
- Verify `pageId` and `pseudoId` in URL
- Check that associated sections exist

---

## Related Files

- **Template**: `/flutter/packages/landing_page/general_landing_page.md`
- **Specification**: `/flutter/packages/landing_page/erp_landing_page.md` (ERP-specific version)
- **Landing Page Models**: `/flutter/packages/growerp_models/lib/src/models/landing_page_model.dart`
- **Assessment Models**: `/flutter/packages/growerp_models/lib/src/models/assessment_model.dart`

