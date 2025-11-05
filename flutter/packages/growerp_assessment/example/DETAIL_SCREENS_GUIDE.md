/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

# Assessment & Landing Page Example App

This example demonstrates the complete workflow for managing assessments and landing pages using the GrowERP Assessment package.

## Features

### 1. Dashboard Navigation
- **Main Dashboard**: Central hub showing Landing Pages and Assessments options
- **Responsive Layout**: Optimized for mobile and desktop views
- **Icon Navigation**: Visual menu with category and order icons

### 2. Landing Pages Management
- **List View**: Browse all landing pages with search, pagination, and filtering
- **Detail Screen**: View comprehensive landing page information in a popUp dialog
  - Read-only fields with metadata
  - Edit button to open edit dialog
  - Delete button with confirmation
  - Draggable floating action buttons
- **Create/Edit**: Full form with dropdowns for status and hook type
- **Field Normalization**: Handles backend data formatting (e.g., 'ResultsHook' → 'results')

### 3. Assessments Management
- **List View**: Browse all assessments with search and pagination
- **Detail Screen**: View assessment information with the same professional popUp pattern
  - Read-only fields with metadata
  - Edit button to open edit dialog
  - Delete button with confirmation
  - Draggable floating action buttons
- **Create/Edit**: Form for managing assessment metadata
- **Status Dropdown**: Normalized to uppercase for consistency

## Architecture

### Detail Screens
The app uses a two-screen pattern for data management:

1. **List Screen** (`LandingPageList`, `AssessmentList`)
   - Shows paginated list of items
   - Tap to open detail screen
   - Floating action buttons for search and create

2. **Detail Screen** (`LandingPageDetailScreen`, `AssessmentDetailScreen`)
   - Shows read-only information in organized sections
   - Floating edit button to modify
   - Delete button with confirmation dialog
   - Professional popUp dialog design (consistent with UserDialog)

### Design Pattern
Both detail screens follow the `popUp()` widget pattern:
- Responsive sizing (400px mobile, 900px desktop)
- Draggable interface (move by pulling top-right corner)
- Organized information sections with InputDecorator styling
- Metadata section for created/modified information
- Desktop FAB + Mobile bottom buttons

## Usage

### Running the Example
```bash
cd flutter/packages/growerp_assessment
flutter run -t example/lib/main.dart
```

### Workflow

1. **Login**
   - App displays HomeForm with login
   - After authentication, dashboard appears

2. **View Landing Pages**
   - Tap "Landing Pages" menu option
   - Browse list of landing pages
   - Tap any row to view detail screen
   - Tap edit button in detail screen to modify
   - Tap delete button to remove with confirmation

3. **View Assessments**
   - Tap "Assessments" menu option
   - Browse list of assessments
   - Tap any row to view detail screen
   - Tap edit button to modify
   - Tap delete button to remove with confirmation

4. **Create New Items**
   - Use floating "+" button in list view
   - Fill in required fields in edit dialog
   - Tap "Create" to add to system

## Detail Screen Components

### LandingPageDetailScreen
Displays:
- **Basic Info**: ID, Status, Title, Hook Type, Assessment ID
- **Content**: Headline, Subheading, Privacy Policy URL
- **Metadata**: Created by/date, Last modified by/date

### AssessmentDetailScreen
Displays:
- **Basic Info**: ID, Status, Assessment Name
- **Description**: Full description with multi-line support
- **Metadata**: Assessment ID, Created by/date, Last modified by/date

## Integration Points

### BLoC State Management
- `LandingPageBloc`: Manages landing page CRUD operations
- `AssessmentBloc`: Manages assessment CRUD operations
- Detail screens listen to bloc state and auto-close on success

### Responsive Design
- Mobile: 400px dialog with bottom buttons
- Tablet/Desktop: 900px dialog with floating action button
- Automatic detection via `ResponsiveBreakpoints`

### Error Handling
- Message display on failure (red notifications)
- Confirmation dialogs for delete operations
- Loading indicators during async operations

## Code Examples

### Opening a Detail Screen from List
```dart
await showDialog(
  context: context,
  builder: (BuildContext context) {
    return BlocProvider.value(
      value: _landingPageBloc,
      child: LandingPageDetailScreen(
        landingPage: selectedLandingPage,
      ),
    );
  },
);
```

### Editing from Detail Screen
```dart
FloatingActionButton(
  onPressed: () async {
    var result = await showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<LandingPageBloc>(),
        child: LandingPageDialog(landingPage),
      ),
    );
  },
  child: const Icon(Icons.edit),
)
```

## Data Flow

```
List View (tap row)
    ↓
Detail Screen (shows read-only data)
    ├─ Edit Button → Edit Dialog
    │   └─ Update via BLoC
    │       └─ Detail Screen closes
    │
    └─ Delete Button → Confirmation
        └─ Delete via BLoC
            └─ Detail Screen closes
```

## Key Features of Detail Screens

✅ **Professional UI**: Using growerp_core's `popUp()` widget
✅ **Responsive**: Optimized for all screen sizes
✅ **Draggable**: Move dialogs around by dragging
✅ **Read-Only**: Display data without editing in detail view
✅ **Metadata**: Show audit information (created/modified by/date)
✅ **Actions**: Edit and delete with confirmations
✅ **Consistent**: Same pattern for both Landing Pages and Assessments
✅ **State Sync**: Auto-close after successful operations

## Testing the Detail Screens

1. Navigate to Landing Pages or Assessments
2. Tap on any item to open the detail screen
3. Verify all fields display correctly
4. Try dragging the detail screen by the top-right corner
5. Tap the edit button to modify the item
6. Tap the delete button to remove (with confirmation)
7. Verify the detail screen closes after successful operations

## Future Enhancements

- Add more sections to detail screens (e.g., questions for assessments)
- Implement nested editing for complex objects
- Add export/share functionality
- Implement version history tracking
