# Assessment Package Example App

This is an example Flutter application demonstrating the usage of the `growerp_assessment` package, specifically showcasing the Landing Page Management features.

## Features

- **Landing Page Management**: Create, read, update, and delete landing pages
- **Search and Filter**: Find landing pages by title or other criteria
- **Status Management**: Manage landing page statuses (DRAFT, ACTIVE, INACTIVE)
- **Responsive UI**: Works on mobile and desktop platforms

## Getting Started

### Prerequisites

- Flutter SDK (3.33.0 or higher)
- Dart SDK (3.9.0 or higher)

### Setup

1. Navigate to the example directory:
```bash
cd flutter/packages/growerp_assessment/example
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure the backend URL in `assets/cfg/app_settings.json`:
```json
{
  "databaseUrl": "https://your-backend-url.com",
  "chatUrl": "wss://your-chat-url.com"
}
```

### Running the App

#### Development

```bash
flutter run
```

#### Release

```bash
flutter run --release
```

### Integration Tests

Run the integration tests:

```bash
flutter test integration_test/landing_page_test.dart
```

## Project Structure

```
example/
├── lib/
│   └── main.dart              # Application entry point and main menu
├── assets/
│   └── cfg/
│       └── app_settings.json  # Configuration settings
├── integration_test/
│   └── landing_page_test.dart # Integration tests
└── pubspec.yaml               # Package dependencies
```

## Key Screens

### Main Menu
- Entry point with navigation to Landing Pages management

### Landing Pages List
- Displays all landing pages in a responsive table
- Supports pagination and infinite scrolling
- Search functionality to find specific landing pages
- Quick actions:
  - Add new landing page
  - Search and filter
  - Edit by clicking on any row
  - Delete from detail dialog

### Landing Page Detail Dialog
- Create new landing pages
- Edit existing landing pages
- Update fields:
  - Title
  - Headline
  - Subheading
  - Hook Type (frustration, results, custom)
  - Status (DRAFT, ACTIVE, INACTIVE)
  - Privacy Policy URL
- Delete landing pages with confirmation

## Architecture

This example follows the GrowERP architectural pattern:

- **BLoC Pattern**: State management using `flutter_bloc`
- **Layered Architecture**: Separation of concerns between UI, BLoC, and data layers
- **Responsive Design**: Uses `responsive_framework` for multi-platform support
- **Models**: Type-safe data models from `growerp_models`

## Dependencies

- **growerp_assessment**: Landing page management package
- **growerp_core**: Core utilities and widgets
- **growerp_models**: Shared data models
- **flutter_bloc**: State management
- **responsive_framework**: Responsive design support

## Backend Integration

This example app requires a compatible GrowERP backend API. The backend must provide:

- `/getLandingPages` - Fetch list of landing pages
- `/getLandingPage` - Fetch single landing page details
- `/createLandingPage` - Create new landing page
- `/updateLandingPage` - Update existing landing page
- `/deleteLandingPage` - Delete landing page

## Testing

### Local Testing

The integration tests can be run locally:

```bash
flutter test integration_test/landing_page_test.dart
```

### CI/CD Testing

Tests are automatically run in the CI/CD pipeline for all pull requests.

## Troubleshooting

### Backend Connection Issues

If the app cannot connect to the backend:

1. Verify the backend URL in `app_settings.json`
2. Check that the backend is running and accessible
3. Verify network connectivity
4. Check firewall rules

### State Management Issues

If the landing page list doesn't update:

1. Check that the `LandingPageBloc` is properly initialized
2. Verify that events are being dispatched correctly
3. Check console logs for errors

## Contributing

When modifying this example:

1. Maintain consistency with the `growerp_user_company` example pattern
2. Update tests when adding new features
3. Keep the UI responsive for all screen sizes
4. Follow GrowERP coding standards

## License

This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License.
