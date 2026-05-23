# GrowERP Generative AI Integration Guide

**Date of Creation:** May 19, 2026  
**Status:** Active  
**Platform Version:** GrowERP 1.15.0  

This document serves as a comprehensive reference guide to all the **Artificial Intelligence (AI)** integrations, services, and functionalities implemented across the GrowERP codebase. 

AI inside GrowERP is primarily powered by **Google Gemini 2.5 Flash** (via direct generative language APIs) and **Google Veo 2 / Imagen Video** (via Vertex AI). It covers marketing, onboarding, content generation, video creation, and page design, using a state-of-the-art Generative UI (GenUI) paradigm on the frontend and robust Groovy/REST services on the backend.

---

## 1. Core AI Architecture & Utilities

### 🛠️ Unified AI Utility (`GeminiAiUtil.groovy`)
*   **Path**: `/data/growerp/backend/service/GeminiAiUtil.groovy`
*   **Service Name**: `growerp.100.GeneralServices100.call#GeminiApi`
*   **Purpose**: Acts as a central, LLM-agnostic utility layer for executing text generation requests.
*   **Key Details**:
    *   Implements retry logic with exponential backoff for handling API rate limits (`429` responses).
    *   Retrieves authorization key from User Preferences (`GEMINI_API_KEY`) with fallback to system environment variables.
    *   Supports dynamic parameter binding (e.g., custom model choice, temperature settings, max token lengths).
    *   Standardizes standard model usage with a default model configuration of `gemini-3.5-flash`.

---

## 2. AI-Driven Onboarding & GenUI

### 💬 Onboarding Chatbot Core (`onboardingChat.groovy`)
*   **Path**: `/data/growerp/backend/service/onboardingChat.groovy`
*   **Moqui Service**: `growerp.100.OnboardingServices100.chat#Onboarding`
*   **REST Endpoint**: `POST /rest/s1/growerp/100/OnboardingChat`
*   **Purpose**: Manages multi-turn onboarding dialogues that dynamically configure the application setup.
*   **Mechanics**:
    *   Maintains conversation state with Gemini by enforcing proper alternating turn formats (strictly alternating `user` and `model` roles starting with `user`).
    *   Applies structured `systemPrompt` (system instruction metadata) to constrain the AI's behavior, instructions, and output format.
    *   Outputs UI-friendly **A2UI JSONL** stream lines representing widgets, forms, inputs, and text prompts.

### 💾 Conversation Persistence (`onboardingSave.groovy`)
*   **Path**: `/data/growerp/backend/service/onboardingSave.groovy`
*   **Moqui Service**: `growerp.100.OnboardingServices100.save#Onboarding`
*   **Purpose**: Automatically saves onboarding chatbot history as a private support room for review.
*   **Mechanics**:
    *   Creates a `growerp.general.ChatRoom` entity flagged as private (`isPrivate: 'Y'`).
    *   Links the initiating user and the support operator (`SYSTEM_SUPPORT`) to the room membership.
    *   Parses Gemini's responses to extract only meaningful textual advice (filtering out structural configuration JSON) and stores the cleaned transcripts as individual `growerp.general.ChatMessage` entities.

---

## 3. Marketing & Social Media Automation

### 👤 Marketing Persona Generation (`generatePersonaWithAI.groovy`)
*   **Path**: `/data/growerp/backend/service/generatePersonaWithAI.groovy`
*   **Service Name**: `growerp.100.MarketingServices100.generate#PersonaWithAI`
*   **REST Endpoint**: `/rest/s1/growerp/100/marketing/generateWithAI`
*   **Purpose**: Generates realistic ideal-customer avatars based on business descriptions.
*   **Output Data Model**:
    ```json
    {
      "name": "Alex Johnson",
      "demographics": "Age range, occupation, income level, location...",
      "painPoints": "Bullet points summarizing challenges...",
      "goals": "Bullet points detailing objectives...",
      "toneOfVoice": "Preferred style of communication..."
    }
    ```
    *Creates or updates records in `growerp.marketing.MarketingPersona`.*

### 📅 Weekly Content Planning (`generateContentPlanWithAI.groovy`)
*   **Path**: `/data/growerp/backend/service/generateContentPlanWithAI.groovy`
*   **Service Name**: `growerp.100.MarketingServices100.generate#ContentPlanWithAI`
*   **REST Endpoint**: `/rest/s1/growerp/100/marketing/plans/generateWithAI`
*   **Purpose**: Uses the **PNP (Pain-News-Prize) formula** to plan a cohesive week of content targeting a specific persona.
*   **Structure**:
    *   **Monday**: *PAIN* - Address a specific customer challenge.
    *   **Wednesday**: *NEWS* - Share a relevant industry trend or insight.
    *   **Friday**: *PRIZE* - Offer value or actionable advice with a call-to-action.
    *Creates a `ContentPlan` parent entity and multiple `SocialPost` draft children.*

### 📝 Social Post Drafting (`draftSocialPostWithAI.groovy`)
*   **Path**: `/data/growerp/backend/service/draftSocialPostWithAI.groovy`
*   **Service Name**: `growerp.100.MarketingServices100.draft#SocialPostWithAI`
*   **REST Endpoint**: `/rest/s1/growerp/100/marketing/posts/draftWithAI`
*   **Purpose**: Generates publish-ready, highly engaging, and non-corporate copy for LinkedIn or X based on the content plan's outline.
*   **Key Details**:
    *   Generates a strong opening hook.
    *   Appends selective relevant emojis (sparingly) and 3–5 targeted hashtags.
    *   Concludes with a **Signal of Interest Elicitor (SOIE)** question to drive engagement comments.
    *Saves drafted copy directly to `growerp.marketing.SocialPost.draftContent`.*

---

## 4. Course Promotion & Video Generation

### 🎓 Course Media Generation (`generateCourseMediaWithAI.groovy`)
*   **Path**: `/data/growerp/backend/service/generateCourseMediaWithAI.groovy`
*   **Service Name**: `growerp.100.CourseServices100.generate#CourseMediaWithAI`
*   **REST Endpoint**: `/rest/s1/growerp/100/course/generateMediaWithAI`
*   **Purpose**: Auto-generates high-value multichannel campaign materials from course details (syllabus, difficulty, target audience, lessons).
*   **Supported Platforms & Formats**:
    *   **LinkedIn**: 3-part PNP posts separated by markers.
    *   **Medium / Substack**: A complete 1500–2500 word SEO-friendly long-form article in Markdown.
    *   **Email**: A 5-day nurture sequence (Welcome, Concept Deep Dive, Case Study, Objections, CTA).
    *   **YouTube**: A full spoken script structured with exact timestamp indicators.
    *   **Twitter/X**: A 10–15 numbered tweet thread with a hook tweet.
    *   **In-App**: Structured step-by-step help, tutorial guide, and troubleshooting sidebar documentation.
    *Inserts the result into `growerp.course.CourseMedia`.*

### 🎬 Text-to-Video Creation (`generateVideoFromScript.groovy`)
*   **Path**: `/data/growerp/backend/service/generateVideoFromScript.groovy`
*   **Purpose**: Converts YouTube scripts generated in the previous step into cinematic or animated video media.
*   **Core Mechanics**:
    1.  **AI Prompter**: Uses Gemini to analyze the script and compose a single, visually dense video prompt under 200 words (visual descriptions only, ignoring narration).
    2.  **Google Veo 2 Integration**: Sends the prompt to Vertex AI (`imagegeneration@006` or `veo-2-video`) using Application Default Credentials (ADC).
    3.  **Keyframe Fallback**: Generates a set of 4 keyframe images as storyboard images first when instant video generation is queued.
    4.  **Storyboard Fallback**: If full Veo access is restricted, falls back to producing a comprehensive shot-by-shot visual JSON blueprint:
        ```json
        {
          "title": "...",
          "duration": "...",
          "shots": [{"shotNumber": 1, "duration": "3s", "description": "...", "cameraMovement": "..."}]
        }
        ```
    *Updates `CourseMedia` status from `DRAFT` to `SCHEDULED` or `PUBLISHED`.*

---

## 5. Visual Generation & Business Assessment

### 🎨 Landing Page & Assessment Creation (`generateLandingPageWithAI.groovy`)
*   **Path**: `/data/growerp/backend/service/generateLandingPageWithAI.groovy`
*   **Service Name**: `growerp.100.LandingPageServices100.generate#LandingPageWithAI`
*   **REST Endpoint**: `POST /rest/s1/growerp/100/landing/generateWithAI`
*   **Purpose**: Creates a complete landing page AND a fully customized 15-question Business Readiness Assessment in one single API request.
*   **Generated Elements**:
    1.  **Landing Page Schema**: Page title, headline hook, secondary subheadings, active call-to-actions, hero copy, features, credibility stories, and industry statistics.
    2.  **Part A (10 Best Practices Questions)**: Multiple-choice scoring questions assessing alignment with industry standards (each option assigned a relative score 0-100).
    3.  **Part B (5 Sales Qualification Questions)**: Preset key indicators including situation analysis, outcome goals, operational obstacles, solution type/budget indicators, and open feedback.
    4.  **Scoring Thresholds**: Dynamically calculates "Critical", "Needs Work", and "Ready" outcomes.
    *Inserts records across `LandingPage`, `PageSection`, `CredibilityInfo`, `CredibilityStatistic`, `Assessment`, `AssessmentQuestion`, `AssessmentQuestionOption`, and `ScoringThreshold`.*

---

## 6. Frontend Flutter AI Integration

The Flutter app leverages these backend services through its state-management and UI components:

```
[Flutter UI Event] ──► [BLoC Controller] ──► [RestClient Endpoint] ──► [Moqui XML REST] ──► [Groovy AI Script]
```

*   **REST Client Mappings**:
    *   Backend endpoints are mapped inside `packages/growerp_models/lib/src/rest_client.dart` (and its generated output `.g.dart`) as HTTP REST queries targeting `rest/s1/growerp/100/`.
*   **State Management (BLoCs)**:
    *   **`LandingPageGenerationBloc`**: Manages step-based loading states during visual asset creation:
        1.  `researchingBusiness`: Initial research parameters evaluation.
        2.  `generatingContent`: Waiting for Gemini API to return structured layout and assessments.
        3.  `creatingXml` / `importing`: Parsing the payload and initializing DB values.
    *   **Onboarding GenUI View**: Connects to the WebSocket/REST chat stream, rendering standard text messages as interactive forms (such as checkboxes, input buttons, or custom selection matrices) using the Human Textual Interface (HTI) pattern.

---

> [!NOTE]
> All direct integrations with Gemini models use `gemini-3.5-flash` for high-speed, cost-effective generation. Complex multi-step generations (like landing pages or media nurture sequences) include built-in exponential delay retries to safely handle rate limits.
