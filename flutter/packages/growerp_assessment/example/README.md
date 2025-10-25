# GrowERP Assessment Package Example Application

This is an example Flutter application that showcases the features and capabilities of the `growerp_assessment` package.

## Overview

The Assessment Example App demonstrates how to:
- Integrate the `growerp_assessment` package into a Flutter application
- Use assessment management features
- Display assessment results and lead scoring
- Utilize BLoC pattern for state management
- Structure a multi-screen application with the GrowERP architecture

## Features Demonstrated

### 1. Assessment Management
- View and create assessments
- Manage assessment questions and scoring
- Handle assessment results and analytics

### 2. User Interface
- Dashboard with assessment metrics
- Assessment list screen
- Results analysis screen
- Navigation and routing

### 3. Integration
- BLoC-based state management
- API client integration
- Multi-company (tenant) support
- Localization support

## Getting Started

### Prerequisites

- Flutter 3.0.0 or later
- Dart 3.0.0 or later
- A running GrowERP backend instance

### Installation

1. Clone or download the repository
2. Navigate to this directory:
   ```bash
   cd flutter/packages/growerp_assessment/example
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Generate code (JSON serialization, API clients):
   ```bash
   flutter pub run build_runner build
   ```

5. Update `assets/cfg/app_settings.json` with your backend URL and configuration

### Running the App

**For development:**
```bash
flutter run
```

**For specific platform:**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d web

# Linux
flutter run -d linux

# Windows
flutter run -d windows
```

## Project Structure

```
example/
├── lib/
│   └── main.dart              # Application entry point and routing
├── integration_test/
│   └── assessment_test.dart   # Integration tests
├── test_driver/
│   └── integration_test.dart  # Test driver for integration tests
├── assets/
│   └── cfg/
│       └── app_settings.json  # Configuration file
└── pubspec.yaml              # Package dependencies
```

## Key Components

### main.dart
- **TopApp**: Main application widget with theme and BLoC setup
- **menuOptions()**: Defines navigation menu structure
- **generateRoute()**: Handles route navigation
- **MainMenu**: Dashboard displaying key metrics
- **AssessmentListScreen**: Shows available assessments
- **AssessmentResultsListScreen**: Displays assessment responses

## Configuration

Edit `assets/cfg/app_settings.json` to configure:
- Backend URL (`databaseUrl`)
- Chat WebSocket URL (`chatUrl`)
- Connection timeouts
- Request logging preferences

Example configuration:
```json
{
    "appName": "GrowERP Assessment Example",
    "databaseUrl": "https://your-backend.com",
    "chatUrl": "wss://your-chat-server.com",
    "connectTimeoutProd": 30,
    "receiveTimeoutProd": 300
}
```

## Testing

### Run Integration Tests

**Using Docker (recommended for CI/CD):**
```bash
./flutter/build_run_all_tests.sh
```

**Local development:**
```bash
flutter test integration_test/assessment_test.dart
```

**With specific emulator:**
```bash
flutter test integration_test/assessment_test.dart -d emulator-5554
```

## State Management

The app uses BLoC (Business Logic Component) pattern for state management:

```dart
// Access authentication state
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state.status == AuthStatus.authenticated) {
      // Render authenticated UI
    }
  },
)

// Access assessment data
BlocBuilder<AssessmentBloc, AssessmentState>(
  builder: (context, state) {
    // Render assessment UI
  },
)
```

## API Integration

The package uses a type-safe Retrofit client for API communication:

```dart
// Example: Get assessments
final assessments = await restClient
    .getAssessments(companyId: 'company_123');

// Example: Submit assessment
final result = await restClient
    .submitAssessment(
      assessmentId: 'assessment_123',
      result: assessmentResult,
    );
```

## Customization

### Adding New Screens

1. Create a new screen in `lib/`
2. Add to menu in `menuOptions()`
3. Update routing in `generateRoute()`
4. Add integration tests in `integration_test/`

### Modifying Dashboard

Edit the `MainMenu` class to customize dashboard items and metrics displayed.

## Troubleshooting

### Build Issues

If you encounter build issues:
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
flutter run
```

### Connection Issues

1. Verify backend is running and accessible
2. Check `app_settings.json` has correct URLs
3. Verify network connectivity and firewall rules
4. Check backend logs for errors

### Test Issues

1. Ensure emulator is running: `flutter emulators --launch emulator-5554`
2. Check test configuration in `integration_test/assessment_test.dart`
3. Verify backend test data is properly seeded

## Dependencies

- **growerp_assessment**: Assessment and lead scoring package
- **growerp_core**: Core GrowERP functionality
- **growerp_models**: Common data models
- **flutter_bloc**: State management framework
- **retrofit**: Type-safe HTTP client
- **dio**: HTTP client library

## Further Reading

- [Assessment Package README](../README.md)
- [Backend API Reference](../../../docs/ASSESSMENT_API_REFERENCE.md)
- [GrowERP Architecture Guide](../../../docs/GrowERP_Extensibility_Guide.md)
- [Building Blocks Development Guide](../../../docs/Building_Blocks_Development_Guide.md)

## License

This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License.

See LICENSE.md file in the root of the repository for complete details.

## Support

For issues, questions, or contributions, please visit:
- Website: https://www.growerp.com
- Documentation: https://docs.growerp.com
- GitHub: https://github.com/growerp
