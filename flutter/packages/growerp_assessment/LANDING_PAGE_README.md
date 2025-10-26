# Landing Page Management in Assessment Package

## Overview

The GrowERP Assessment package now includes comprehensive landing page management functionality. This allows you to create, edit, and manage landing pages for lead capture and assessment flows.

## Features

### Landing Page Management
- **Create/Edit Landing Pages**: Full CRUD operations for landing pages
- **Status Management**: Draft, Active, and Inactive states
- **SEO Optimization**: Title, description, and meta tag support
- **Hook Types**: Frustration, Aspiration, and Curiosity-based landing pages
- **Responsive Design**: Works on all device sizes

### BLoC Architecture
- **LandingPageBloc**: Manages landing page state and operations
- **Type-safe Events**: Load, Create, Update, Delete operations
- **Error Handling**: Built-in error handling with user-friendly messages

## Usage

### 1. Add Landing Page BLoC to Your App

```dart
import 'package:growerp_assessment/growerp_assessment.dart';

// In your app setup
List<BlocProvider> providers = getAssessmentBlocProviders(restClient, classificationId);

// Add to your MultiBlocProvider
MultiBlocProvider(
  providers: providers,
  child: MyApp(),
)
```

### 2. Add Landing Page Management to Your Menu

```dart
MenuOption(
  title: 'Landing Pages',
  route: '/landing-pages',
  child: const LandingPageListScreen(),
),
```

### 3. Navigate to Landing Page Management

```dart
Navigator.pushNamed(context, '/landing-pages');
```

## Screens Included

### LandingPageListScreen
- Lists all landing pages with search functionality
- Shows status indicators (Active/Draft/Inactive)
- Provides quick actions (Edit, Duplicate, Delete)
- Infinite scroll for large datasets

### LandingPageDialog
- Create/Edit landing page form
- Form validation
- Hook type selection (Frustration/Aspiration/Curiosity)
- Status management
- Image URL support

## API Integration

The landing page functionality integrates with the GrowERP backend through:
- `GET /rest/s1/growerp/100/LandingPage` - List landing pages
- `GET /rest/s1/growerp/100/LandingPage/{pageId}` - Get specific landing page
- `POST /rest/s1/growerp/100/LandingPage` - Create landing page
- `PATCH /rest/s1/growerp/100/LandingPage/{pageId}` - Update landing page
- `DELETE /rest/s1/growerp/100/LandingPage/{pageId}` - Delete landing page

## Landing Page Model

```dart
class LandingPage {
  final String pageId;           // System unique ID
  final String pseudoId;         // URL-friendly ID
  final String ownerPartyId;     // Multi-tenant owner
  final String title;            // Page title (SEO)
  final String headline;         // Hero headline
  final String? hookType;        // frustration/aspiration/curiosity
  final String? subheading;      // Supporting text
  final String? description;     // SEO description
  final String? heroImageUrl;    // Hero image
  final String status;           // ACTIVE/DRAFT/INACTIVE
  // ... additional fields
}
```

## Example Integration

See the example app in `example/lib/main.dart` for a complete implementation showing:
- Menu integration
- Route handling
- Dashboard display
- BLoC provider setup

## Demo Data

The backend includes demo landing page data that gets loaded during system setup:
- Business Assessment landing page
- Tech Startup landing page  
- E-commerce landing page
- Service Business landing page

Each demo page includes proper sections, credibility elements, and call-to-action buttons.

## Customization

### Hook Types
- **Frustration**: "Tired of..." / "Stop struggling..."
- **Aspiration**: "Achieve..." / "Unlock your potential..."
- **Curiosity**: "Discover..." / "What if..."

### Status Colors
- **Active**: Green indicator
- **Draft**: Orange indicator  
- **Inactive**: Red indicator

## Backend Integration

Demo data is automatically loaded via the `load#DemoData` service in PartyServices100.xml:

```xml
<!-- Landing page demo data is loaded in load#DemoData service -->
<entity-find entity-name="growerp.landing.LandingPage" list="landingPages">
    <econdition field-name="ownerPartyId" value="DEMO" />
</entity-find>
<!-- ... iterates and creates landing pages for each company -->
```

This ensures every new company gets sample landing pages to work with immediately.