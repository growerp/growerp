# Buddhist Era (BE) Date Formatting Guide

## Overview

GrowERP supports automatic Buddhist Era (BE) date formatting for Thai language users while maintaining Gregorian calendar dates in the database and for all other locales.

**Key Principle**: 
- **Database**: Always stores Gregorian/Western years (e.g., 2025)
- **Display**: Shows Buddhist Era years for Thai users (e.g., 2568 = 2025 + 543)
- **Tests**: Always use Gregorian calendar (English locale)

## When to Use What

### For UI Display (User-Facing)

Use the **localized extensions** in `date_format_extensions.dart`:

```dart
import 'package:growerp_core/growerp_core.dart';

// In Widget build methods where you have BuildContext:
Text(order.createdDate.toLocalizedDateOnly(context))
Text(event.eventDate.toLocalizedShortDate(context))
Text(appointment.scheduledTime.toLocalizedDateTime(context))
```

**Available Methods:**
- `toLocalizedDateOnly(context)` → Returns `yyyy-MM-dd` format (e.g., "2568-10-04" for Thai)
- `toLocalizedShortDate(context)` → Returns `yyyy/M/d` format (e.g., "2568/10/4" for Thai)
- `toLocalizedDateTime(context)` → Returns `yyyy-MM-dd HH:mm` format
- `toLocalizedString(context, format: 'custom')` → Custom format string

### For Tests

Use the **original `dateOnly()`** method:

```dart
// In integration tests - always Gregorian
expect(subscription.fromDate.dateOnly(), '2025-10-04');
expect(order.placedDate.dateOnly(), equals('2025-10-04'));
```

### For Backend Communication

Dates are automatically handled by the timezone conversion layer:
- Sent to backend: UTC with Gregorian calendar
- Received from backend: Converted to local time, Gregorian calendar
- **Never** send Buddhist Era dates to the backend

### For Date Pickers

Date pickers work with DateTime objects internally (Gregorian), but you can display the selected date with localization:

```dart
DateTime? selectedDate;

// Show picker (uses Gregorian internally)
final picked = await showDatePicker(
  context: context,
  initialDate: selectedDate ?? DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);

// Display selected date with localization
Text('Selected: ${picked.toLocalizedDateOnly(context)}')
```

## How It Works

### Buddhist Era Conversion

Buddhist Era year = Gregorian year + 543

Examples:
- 2025 CE → 2568 BE
- 2024 CE → 2567 BE
- 1900 CE → 2443 BE

### Locale Detection

The system automatically detects the current locale from `Localizations.localeOf(context)`:

```dart
// Thai locale (th)
final locale = Locale('th');
date.toLocalizedDateOnly(context) // → "2568-10-04"

// English locale (en)
final locale = Locale('en');
date.toLocalizedDateOnly(context) // → "2025-10-04"
```

## Migration Guide

### Step 1: Identify UI Display Code

Find all places where dates are shown to users:

```bash
# Search for .dateOnly() in UI files (not tests)
grep -r "\.dateOnly()" flutter/packages/*/lib/ --include="*.dart"
```

### Step 2: Add BuildContext

If the widget already has `BuildContext context`, you're good to go.

If not, you may need to:
1. Pass context as a parameter
2. Use `Builder` widget to get context
3. Restructure to have context available

### Step 3: Replace Method Calls

**Before:**
```dart
Text(order.createdDate.dateOnly())
```

**After:**
```dart
Text(order.createdDate.toLocalizedDateOnly(context))
```

### Step 4: Leave Tests Unchanged

Tests should continue using `.dateOnly()`:

```dart
// ✅ CORRECT - Tests always use Gregorian
expect(order.createdDate.dateOnly(), '2025-10-04');

// ❌ WRONG - Don't use localized methods in tests
expect(order.createdDate.toLocalizedDateOnly(context), '2568-10-04');
```

## Examples

### Example 1: Simple List Item

```dart
// Before
ListTile(
  title: Text(item.name),
  subtitle: Text('Created: ${item.createdDate.dateOnly()}'),
)

// After
ListTile(
  title: Text(item.name),
  subtitle: Text('Created: ${item.createdDate.toLocalizedDateOnly(context)}'),
)
```

### Example 2: Table Cell

```dart
// Before
DataCell(Text(order.placedDate?.dateOnly() ?? '')),

// After
DataCell(Text(order.placedDate.toLocalizedDateOnly(context))),
```

### Example 3: Custom Format

```dart
// Before
Text(DateFormat('dd/MM/yyyy').format(event.eventDate))

// After
Text(event.eventDate.toLocalizedString(context, format: 'dd/MM/yyyy'))
```

### Example 4: Conditional Display

```dart
// Before
Text(item.fromDate != null ? item.fromDate.dateOnly() : '')

// After
Text(item.fromDate.toLocalizedDateOnly(context))
// Note: Extension handles null automatically, returns empty string
```

## Helper Class

For more complex scenarios, use `LocalizedDateHelper`:

```dart
// Check if Thai locale is active
if (LocalizedDateHelper.isThaiLocale(context)) {
  // Do something specific for Thai users
}

// Convert years manually
int beYear = LocalizedDateHelper.toBuddhistYear(2025); // → 2568
int gregYear = LocalizedDateHelper.toGregorianYear(2568); // → 2025

// Parse user input (handles BE → Gregorian conversion)
DateTime? parsed = LocalizedDateHelper.parseLocalizedDate(
  context, 
  '2568-10-04',  // Thai user enters BE year
  format: 'yyyy-MM-dd'
); // Returns DateTime with year 2025 (Gregorian)
```

## Testing Checklist

- [ ] Tests use `dateOnly()` and expect Gregorian dates
- [ ] UI displays use `toLocalizedDateOnly(context)`
- [ ] Database queries/responses not affected
- [ ] Date pickers work correctly
- [ ] Switching locales updates dates immediately
- [ ] No Buddhist Era dates sent to backend

## Common Pitfalls

### ❌ Don't: Use localized methods in tests
```dart
// Wrong!
expect(order.date.toLocalizedDateOnly(context), '2568-10-04');
```

### ❌ Don't: Send BE dates to backend
```dart
// Wrong!
await api.createOrder(date: beDate);
```

### ❌ Don't: Hard-code format with BE years
```dart
// Wrong!
Text('Created: 2568-10-04'); // Hard-coded BE year
```

### ✅ Do: Use extensions for UI
```dart
// Correct!
Text('Created: ${order.date.toLocalizedDateOnly(context)}');
```

### ✅ Do: Keep database operations unchanged
```dart
// Correct - database always gets Gregorian
await api.createOrder(date: DateTime.now()); // 2025-10-04
```

## Technical Details

### Extension Implementation

The localized date extensions are implemented in:
- `flutter/packages/growerp_core/lib/src/date_format_extensions.dart`

### Locale Management

Locale state is managed by:
- `LocaleBloc` in `growerp_core/lib/src/domains/common/bloc/locale_bloc.dart`
- Persisted in SharedPreferences
- Available via `Localizations.localeOf(context)`

### Supported Locales

Currently supported:
- English (`en`)
- Thai (`th`) - with Buddhist Era support
- English/Canada (`en_CA`)

To add more locales, update `supportedLocales` in `top_app.dart`.

## FAQ

**Q: Why not store Buddhist Era in the database?**
A: The database uses international standards (Gregorian calendar) for consistency, data exchange, and compatibility with external systems.

**Q: What if I need to display dates in a service/repository?**
A: Services and repositories should not format dates. Return DateTime objects and let the UI layer handle formatting with context.

**Q: Can I use this for date calculations?**
A: Always use DateTime objects (Gregorian) for calculations. Only convert to BE for final display.

**Q: What about other calendars (Islamic, Persian, etc.)?**
A: The same pattern can be extended. Add locale checks and conversion logic in `date_format_extensions.dart`.

## Resources

- [Thai Buddhist Calendar](https://en.wikipedia.org/wiki/Thai_solar_calendar)
- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization)
- [Intl Package Documentation](https://pub.dev/packages/intl)
