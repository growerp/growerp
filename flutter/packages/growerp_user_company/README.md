# GrowERP User & Company

A Flutter package for managing users, companies, and their relationships within the GrowERP ecosystem.

## Purpose

`growerp_user_company` provides comprehensive user and company management functionality, including:

- **User Management** - Create, edit, delete, and list users with role-based access
- **Company Management** - Multi-company support with organization hierarchy
- **User-Company Relationships** - Associate users with companies and manage permissions
- **Role Management** - Customer, supplier, lead, and internal company roles

## Key Features

### User Management

| Feature | Description |
|---------|-------------|
| User List | Searchable, sortable list with role-based filtering |
| User Dialog | Detailed user editing with profile photo upload |
| User Groups | Admin, employee, and custom group assignments |
| Login Management | Enable/disable login access per user |

### Company Management

| Feature | Description |
|---------|-------------|
| Company List | Filterable company directory |
| Company Dialog | Organization details, logo, and settings |
| Employee Management | Associate users as company employees |
| Multi-Role Support | Customer, supplier, lead classifications |

### UI Components

Built on `growerp_core` design system:

- `StyledImageUpload` - Profile photo and logo upload
- `ListFilterBar` - Inline search for list views
- `StatusChip` - Role-based visual indicators
- `StyledDataTable` - Sortable, paginated data display
- `GroupingDecorator` - Organized form sections

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  growerp_user_company:
    path: ../growerp_user_company
  growerp_core:
    path: ../growerp_core
```

## Usage

### Register Routes

```dart
import 'package:growerp_user_company/growerp_user_company.dart';

// Add to your router
GoRoute(
  path: '/users',
  builder: (context, state) => UserList(role: Role.company),
),
GoRoute(
  path: '/companies', 
  builder: (context, state) => CompanyList(role: Role.customer),
),
```

### Provide BLoCs

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => UserBloc(restClient)),
    BlocProvider(create: (_) => CompanyBloc(restClient)),
    BlocProvider(create: (_) => CompanyUserBloc(restClient)),
  ],
  child: MyApp(),
)
```

### Use Components

```dart
// User list with role filter
UserList(role: Role.company)

// Company list for customers
CompanyList(role: Role.customer)

// User dialog for editing
UserDialog(user: existingUser)

// Company dialog for editing
CompanyDialog(company: existingCompany)
```

## Module Structure

```
growerp_user_company/
├── lib/
│   ├── growerp_user_company.dart    # Public API exports
│   └── src/
│       ├── user/
│       │   ├── bloc/                # UserBloc, events, states
│       │   └── views/               # UserList, UserDialog
│       ├── company/
│       │   ├── bloc/                # CompanyBloc, events, states
│       │   └── views/               # CompanyList, CompanyDialog
│       ├── company_user/
│       │   ├── bloc/                # CompanyUserBloc for relationships
│       │   └── views/               # Combined company-user views
│       └── common/                  # Shared utilities
├── l10n/                            # Localization files
└── example/                         # Demo app with integration tests
```

## State Management

Uses BLoC pattern with the following blocs:

| Bloc | Purpose |
|------|---------|
| `UserBloc` | User CRUD operations and list management |
| `CompanyBloc` | Company CRUD operations and list management |
| `CompanyUserBloc` | User-company relationship management |

## Testing

```sh
# Using melos (recommended)
melos bootstrap
melos build
melos l10n
cd flutter/packages/growerp_user_company/example
flutter test integration_test

# Or run all tests
melos test
```

## Localization

Supports multiple languages via ARB files in `l10n/`:

- English (default)
- Additional languages can be added

Regenerate localizations:
```sh
melos l10n
```

## Dependencies

- `growerp_core` - Design system and core infrastructure
- `growerp_models` - User, Company, and related data models
- `flutter_bloc` - State management
- `image_picker` - Profile photo selection

## Related Packages

- `growerp_core` - Foundation package with design system
- `growerp_models` - Shared data models
- `growerp_catalog` - Product and category management
- `growerp_order_accounting` - Orders and financial management

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.
