# MVP:
This Minimum Complete Product (MCP) specification defines the absolute minimum set of features required to launch the core lead generation and configurable assessment system, based on the "$1 Million Landing Page" methodology.

The technology stack must be architecturally ready to integrate advanced features like those used in AI-driven Conversion Rate Optimization (CRO), even if those advanced functions are deferred during the MCP stage. This means the backend must be designed for rapid, data-driven optimization and personalization, aligning with modern systems like those that integrate AI/ML functionalities.

## Minimum Complete Product (MCP) Specification

The primary conversion goal of the MCP is the successful completion of the 15-question assessment and the delivery of dynamic results.

### 1. Core Platform Components (Phase 1: Launch Ready)

#### 1.1 Landing Page (LP) Structure

The LP must be static but highly configurable using basic text and image inputs:

- **Hook/Headline:** Must support both Frustration Hook and Results Hook formats (readiness question).
- **Subheading:** Must clearly state the goal: "Answer 15 questions to find out why...".
- **Value Proposition:** Ability to list and display **three key areas** the assessment measures and improves (e.g., sleep environment, sleep routine, sleep nutrition).
- **Credibility Section:** Space for configurable text and images covering the creator's **bio, background, and supporting data** (statistics or research quotes).
- **Primary CTA Button:** Must cover four critical components: Next step ("Start the quiz"), estimated time (e.g., 3 minutes), cost (free), and promise of immediate recommendations.
- **Compliance/Friction:** Must include an easily accessible link to the privacy policy (which may open in a lightbox to keep focus on the conversion goal).

#### 1.2 Assessment Flow (The 15 Questions)

The assessment flow must be broken into three mandatory steps, and all questions must be fully definable (text and answer options):

1. **Lead Capture (Contact Info):**
    
    - Capture **Name** (Mandatory).
    - Capture **Email Address** (Mandatory).
    - Capture **Location** (Automatically, via IP address).
    - Capture Phone Number (Optional).
    - _Rationale: This ensures lead data is collected first, similar to a squeeze page approach._
2. **Best Practices Scoring (10 Questions):**
    
    - Ten questions designed to assess adherence to predetermined "best practices".
    - Answers to these questions are the sole input for calculating the objective assessment score.
3. **Sales Qualification (5 Questions — The Big Five):**
    
    - Current Situation.
    - Desired Outcome (Most important goal in next 90 days).
    - Obstacle/What hasn't worked.
    - Preferred Solution (Implied budget/service level).
    - Open-Box Question ("Anything else you need to know").

#### 1.3 Scoring and Dynamic Results Page

- **Assessment Score Calculation:** Implement a configurable rule engine to assign scores/weights to the 10 Best Practices questions, resulting in one of three possible lead status tiers: **Cold, Warm, or Hot**.
- **The Big Reveal:** The results page must display the final score/status (e.g., "75%" or "Warm").
- **Three Insights:** The system must allow the marketer to manually map predefined text blocks for "three insights" displayed on the results page, based on key answers from the 15 questions.
- **Dynamic Next Steps (CTA Routing):** This is critical. The primary call to action must **dynamically change** based on the calculated lead status:
    - **Hot Leads (High Score):** Default CTA routes to booking a **one-to-one meeting**.
    - **Warm Leads (Mid Score):** Default CTA routes to a **group presentation or event**.
    - **Cold Leads (Low Score/Poor Fit):** Default CTA routes to recommended free **content** (e.g., a video or blog post).

### 2. Minimum Technology & Analytics (Based on AI-Ready Architecture)

The system must use an architecture consistent with platforms used for digital optimization, characterized by **Artificial Intelligence (AI) and Machine Learning (ML) readiness**, even if only basic functions are active initially.

#### 2.1 Backend and Data Storage

- **Lead Dashboard:** A centralized, exportable data repository and dashboard is mandatory, showing every lead's **Name, Email, Location, all 15 answers, the calculated score, and the recommended Next Step**.

#### 2.2 CRO and Optimization (Basic, Manual Implementation)

- **Tracking Readiness:** The system must allow easy installation of external analytics tracking codes (e.g., Google Analytics, traditional heatmap tools like Crazy Egg or FullStory).
- **Mobile Responsiveness:** The landing page and assessment flow must be designed to be responsive and highly optimized for mobile devices.

#### 2.3 Deferrals (Functionality Deferred Past MCP Launch)

The following advanced capabilities, detailed in the full requirement specification, are explicitly deferred to focus on rapid MCP launch:

|Deferred Functionality|Rationale for Deferral|
|:--|:--|
|**AI Continuous Testing/Optimization**|Requires complex algorithms and robust infrastructure; rely initially on manual traffic analysis.|
|**AI Predictive Attention Maps**|Pre-launch optimization tool; not essential for basic functioning lead generation.|
|**AI Qualitative Sentiment Analysis**|Analyzing the "Open-Box Question" text for themes and sentiment scores will initially be handled by human review of raw dashboard data.|
|**Integrated Session Recordings/Deep Heatmaps**|Rely on basic external tracking/analytics tools; integrating comprehensive proprietary tools is complex.|
|**Layered Conversational Surveys**|Advanced feature for collecting specific qualitative feedback on the page; core functionality relies only on the 15 assessment questions.|
|**Advanced Psychological Triggers** (e.g., customizable countdown timers, exit intent forms)|While valuable, these are typically bolt-on CRO tools and can be implemented post-launch to reduce friction.|
