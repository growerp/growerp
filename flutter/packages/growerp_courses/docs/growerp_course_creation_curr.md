# How to Create a Course with GrowERP: The Curriculum

This curriculum outlines the process of building, validating, and selling a course using the GrowERP ecosystem. It combines industry best practices with the specific tools and strategies found in the GrowERP architecture (Assessments, Landing Pages, and Outreach).

## Course Overview
*   **Goal**: To take a course creator from "Idea" to "Automated Sales Funnel" using GrowERP.
*   **Prerequisites**: Access to GrowERP Admin, Basic XML knowledge (for data definition).
*   **Estimated Completion Time**: 4 Weeks.

---

## Module 1: Strategy & Validation (The "Why")
*Based on "GrowERP Course Media Strategy.md" and "Marketing hooks.md"*

### Lesson 1.1: Identifying the Pain Point
*   **Objective**: Define a specific problem your course solves.
*   **Case Study**: The **Field Service Efficiency Masterclass**.
    *   *Bad*: "A course about inventory software."
    *   *Good*: "Your HVAC fleet is losing $500 per van every week. Here’s how to stop it."
*   **Action Project**: Write 3 "Agitator" hooks for your course topic.

### Lesson 1.2: The "Why-What-How" Framework
*   **Objective**: Structure your value proposition.
    *   **Why**: Why does this problem exist? (e.g., "Manual inventory tracking")
    *   **What**: What is the solution? (e.g., "Real-time Van Warehouses")
    *   **How**: How do we implement it? (The Course Content).
*   **Ref**: Solopreneur Mini-Course Strategy.

---

## Module 2: The Assessment Engine (The "Pre-Sell")
*Based on `GrowerpSuggestedCourses.xml` - Assessment Entities*

### Lesson 2.1: Why Assessments Beat Standard Opt-ins
*   **Theory**: People love learning about themselves. An "Effective Score" is more compelling than a "Newsletter Signup".
*   **Strategy**: Use the assessment to qualify leads *before* they buy.

### Lesson 2.2: Building the Assessment in XML
*   **Technical Skill**: Defining `growerp.assessment.Assessment`.
*   **Key Components**:
    *   `AssessmentQuestion`: The input (e.g., "How do you track inventory?").
    *   `AssessmentQuestionOption`: Scored answers (Score 1 for "Paper", Score 10 for "ERP").
    *   `ScoringThreshold`: Determining user status (Hot vs. Warm lead).
*   **Example Code Review**: Analyzing the `FS_EFFICIENCY` assessment structure.

---

## Module 3: Curriculum Design & Content
*Based on Digital Product Best Practices*

### Lesson 3.1: Structuring for Success
*   **Rule of Thumb**: 3-5 Modules per Course.
*   **Lesson Structure**:
    1.  **The Concept** (Video/Text).
    2.  **The Example** (Real-world scenario).
    3.  **The Action Item** (Implementation).
*   **Ref**: "8 Steps to Your First Mini-Course.md".

### Lesson 3.2: Production Formats
*   **Video**: Keep under 6 minutes (Micro-learning).
*   **Text/Guide**: For referencing complex configurations.
*   **Quizzes**: Reinforce learning (GrowERP supports `Assessment` types for quizzes too).

---

## Module 4: The Launch Funnel & Automation
*Based on Landing Pages and Marketing Service definitions*

### Lesson 4.1: The Landing Page
*   **Technical Skill**: Defining `growerp.landing.LandingPage`.
*   **Components**:
    *   `hookType`: "ResultsHook" vs "StoryHook".
    *   `ctaAssessmentId`: Linking your Assessment from Module 2.
    *   `headline`: The primary promise.
*   **Example**: Analyzing `B2B_LANDING` ("Scale Your Sales Team Without Scaling Your Software Bill").

### Lesson 4.2: Automated Outreach
*   **Strategy**: Using `OutreachServices` to follow up.
*   **Sequence**:
    1.  **Hot Lead (Heigh Score)**: Direct personal email/call.
    2.  **Warm Lead (Medium Score)**: Nurture sequence (Case Studies).
*   **Ref**: "20 emails to persuade people to buy.md".

---

## Final Project
**Build Your Prototype**:
1.  Define your **Hook**.
2.  Write a simple 5-question **Assessment** in XML.
3.  Create a **Landing Page** entry linking to it.
4.  Outline your **Course Modules**.
