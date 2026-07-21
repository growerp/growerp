# GrowERP Marketing package

A marketing content and lead-generation plugin for the GrowERP system. Covers content
planning through lead capture and scoring.

## Features

- **Personas** — target-audience/buyer-persona definitions that drive content and landing pages
- **Content Plans** — editorial/campaign content planning
- **Master Content** — reusable source content pieces
- **Social Posts** — social-media post drafts generated from master content
  (published via `growerp_outreach`)
- **Landing Pages** — public lead-capture landing pages, with page-section builder
- **Assessments** — lead-scoring quizzes: questions/options, scoring thresholds, and a
  3-step public flow (lead capture → questions → scored result)
- **Email Sequences** — follow-up email sequences tied to landing pages/assessments
- **Credibility Info** — testimonials/trust content shown on landing pages

## Public assessment/landing-page flow

`AssessmentFlowScreen` / `LandingPageAssessmentFlowScreen` and `PublicLandingPageScreen`
are anonymous-access screens meant to be embedded (e.g. as an iframe) outside the main
authenticated app — see `LeadCaptureScreen` → `AssessmentQuestionsScreen` →
`AssessmentResultsScreen`/`AssessmentConfirmationScreen`.

## integrated test
An integrated test is available in the example component.  
It uses a local backend system.

You can also use our test backend system   
    set in: example/assets/cfg/app_settings.json  
        databaseUrlDebug: https://test.growerp.org

Start test with melos: (activate with: dart global activate melos)
```sh
melos build_all
melos l10n
cd example
flutter test integration_test
```

## use the example component
As with the integration test you can use a local backend or our test backend.
Before you can use the Marketing component you have to create a company which sends an
email with a password. Use this password to login and the Marketing component appears in
the main menu.
