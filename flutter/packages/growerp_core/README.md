# GrowERP Core

The foundational package of the GrowERP Flutter frontend, providing essential infrastructure, UI components, and business logic shared across all GrowERP applications.

## Purpose

`growerp_core` serves as the building block for all GrowERP Flutter applications. It provides:

- **Authentication & Security** - User authentication, session management, and access control
- **REST API Integration** - Unified backend communication layer with the Moqui backend
- **Multi-Company Support** - Tenant isolation and company switching capabilities
- **Design System** - Reusable UI components following the Stitch design pattern
- **State Management** - Core BLoC implementations for shared business logic

## Key Features

### Design System Components

| Component | Description |
|-----------|-------------|
| `StatusChip` | Semantic status indicators (success, warning, danger, info, neutral) |
| `SkeletonLoader` | Shimmer loading placeholders for tables, cards, and lists |
| `SparklineChart` | Mini trend visualizations with percentage changes |
| `StyledDataTable` | Feature-rich data tables with sorting, selection, and styling |
| `StyledDetailCard` | Card-based detail views with consistent styling |
| `StyledImageUpload` | Compact horizontal image upload component |
| `ListFilterBar` | Search and filter bar for list views |
| `GroupingDecorator` | Section grouping with labels and borders |
| `DashboardCard` | Metric cards with icons and actions |

### Design Tokens

| Token | Purpose |
|-------|---------|
| `GrowerpSpacing` | Consistent spacing values (xs, sm, md, lg, xl) |
| `GrowerpRadius` | Border radius presets |
| `GrowerpDuration` | Animation timing constants |
| `GrowerpShadow` | Elevation shadow styles |
| `SemanticColors` | Status-based color extensions |

### Core Domains

- **Authentication** - Login, registration, password reset, session handling
- **Common** - Shared widgets, functions, and utilities
- **Tasks** - Task management and time tracking

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  growerp_core:
    path: ../growerp_core  # or from pub.dev when published
```

## Usage

```dart
import 'package:growerp_core/growerp_core.dart';

// Use design components
StatusChip(label: 'Active', type: StatusType.success)

// Access semantic colors
final successColor = Theme.of(context).colorScheme.success;

// Use spacing tokens
Padding(padding: EdgeInsets.all(GrowerpSpacing.md))
```

## Testing

Integration tests are available in the `example/` directory:

```sh
# Using melos (recommended)
melos bootstrap
melos build
melos l10n
melos test

# Or manually
cd example
flutter test integration_test
```

## Backend Configuration

Configure backend URLs in `example/assets/cfg/app_settings.json`:

```json
{
  "databaseUrlDebug": "https://backend.growerp.org",
  "chatUrlDebug": "wss://backend.growerp.org"
}
```

## Architecture

```
growerp_core/
├── lib/
│   ├── growerp_core.dart          # Public API exports
│   └── src/
│       ├── domains/
│       │   ├── authenticate/      # Auth BLoC, views, repository
│       │   ├── common/            # Shared widgets, functions
│       │   └── tasks/             # Task management
│       ├── styles/
│       │   ├── color_schemes.dart # Theme colors + semantic extensions
│       │   └── design_constants.dart # Spacing, radius, shadows
│       └── templates/             # Page templates, dashboard cards
└── example/                       # Demo app with integration tests
```

## Related Packages

- `growerp_models` - Shared data models and entities
- `growerp_user_company` - User and company management
- `growerp_catalog` - Product catalog management
- `growerp_order_accounting` - Orders and accounting

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.
