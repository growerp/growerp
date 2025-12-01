# assessment

## Overview

The `assessment` package is a Flutter application that manages the assessment workflow for GrowERP. It provides a seamless user journey from lead capture through assessment completion.

## Purpose

This package serves as the main assessment application for GrowERP, replacing the previous landing page UI approach. It handles:

1. **Lead Capture**: Collects user name and email before starting an assessment
2. **Assessment Flow**: Manages the interactive assessment experience
3. **Results Display**: Shows assessment results and next steps to users

## Architecture

### Screen Flow

The application follows a multi-page flow managed by `LandingPageAssessmentFlowScreen`:

1. **Page 0: Landing Page** (optional) - Displays the public landing page for marketing/information
2. **Page 1: Lead Capture** - Collects respondent name and email using `LeadCaptureScreen`
3. **Page 2: Assessment** - Runs the actual assessment using `AssessmentFlowScreen`
4. **Page 3: Results** - Shows assessment results and completion status

### Key Components

- **LeadCaptureScreen**: Self-contained form for collecting name/email with validation
- **LandingPageAssessmentFlowScreen**: Manages the overall flow and page navigation
- **PublicLandingPageScreen**: Optional landing page display (loaded from backend)
- **Main App**: Entry point that initializes BLoCs and sets up the Flutter environment

## Building

### Build Flutter Web with WASM

```bash
cd flutter/packages/assessment
flutter build web --wasm
```

### Deploy to Moqui

Use the deployment script:

```bash
flutter/build-assessment.sh
```

Or manually:

```bash
./flutter/packages/admin/deploy-web-to-moqui.sh assessment
```

## Configuration

The app reads configuration from `app_settings.json`:

- Backend URL
- Assessment data endpoints
- Localization settings

## Integration with Moqui

The built files are served by Moqui at the `/assessment/` endpoint through the `assessmentApp.xml` screen. The screen:

- Serves `index.html` from `/assessment/`
- Sets appropriate CORS and CSP headers
- Allows iframe embedding with CSP: `frame-ancestors 'self'`
- Handles multi-tenant routing via hostname parsing

## Dart Dependencies

Key dependencies (managed in pubspec.yaml):

- `growerp_core`: Core BLoCs and utilities
- `growerp_models`: Data models and API clients
- `growerp_assessment`: Assessment-specific UI and logic
- `flutter_bloc`: State management
- `dio`: HTTP client
- `global_configuration`: Configuration loading

## Development

### Setup

```bash
melos bootstrap
```

### Generate Code

```bash
melos build
```

### Run Tests

```bash
melos test
```

## State Management

Uses the BLoC pattern via `flutter_bloc`. Core BLoCs are provided by `getAssessmentBlocProviders()` including:

- LandingPageBloc: Manages landing page data
- AssessmentBloc: Manages assessment state and results
- Authentication, chat, theme, and locale BLoCs from growerp_core

## Notes

- The landing page UI is now served by Moqui FTL template (`/assessmentLanding` endpoint)
- This package contains only the assessment app and lead capture flow
- MIME types for `.mjs` and `.wasm` files are handled by a custom servlet filter in Moqui
