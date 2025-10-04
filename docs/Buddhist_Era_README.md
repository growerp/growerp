# Buddhist Era Date Formatting - README

## 🎯 What This Is

A comprehensive solution for displaying dates in **Buddhist Era (BE)** calendar for Thai language users, while maintaining **Gregorian calendar** in the database and for all other users.

## ⚡ Quick Start

### For UI Code (displaying dates to users)

```dart
import 'package:growerp_core/growerp_core.dart';

// Before:
Text(order.placedDate.dateOnly())

// After:
Text(order.placedDate.toLocalizedDateOnly(context))
```

### For Tests (always Gregorian)

```dart
// No changes needed - keep using dateOnly()
expect(order.placedDate.dateOnly(), '2025-10-04');
```

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [Quick Reference](Buddhist_Era_Quick_Reference.md) | Fast lookup for common cases |
| [Full Guide](Buddhist_Era_Date_Formatting_Guide.md) | Complete usage documentation |
| [Implementation Summary](Buddhist_Era_Implementation_Summary.md) | Technical details and architecture |
| [Code Examples](examples/buddhist_era_date_examples.dart) | Working code samples |

## 🔑 Key Concepts

### Calendar Systems

- **Gregorian Calendar**: International standard (e.g., 2025 CE)
- **Buddhist Era**: Thai calendar (e.g., 2568 BE = 2025 + 543)

### Where Each is Used

```
┌─────────────────────────────────────────────┐
│                  GrowERP                     │
├─────────────────────────────────────────────┤
│                                              │
│  UI Layer (Thai users)                      │
│  └─ Buddhist Era (2568)  ← toLocalized...() │
│                                              │
│  UI Layer (Other users)                     │
│  └─ Gregorian (2025)     ← toLocalized...() │
│                                              │
│  Business Logic                             │
│  └─ DateTime objects (Gregorian 2025)       │
│                                              │
│  Database                                   │
│  └─ Stored as Gregorian (2025)              │
│                                              │
│  REST API                                   │
│  └─ JSON with Gregorian (2025)              │
│                                              │
│  Tests                                      │
│  └─ Always Gregorian (2025) ← dateOnly()    │
│                                              │
└─────────────────────────────────────────────┘
```

## 🚀 Available Extensions

### Main Extension Methods

```dart
extension LocalizedDateFormat on DateTime? {
  // Basic date (2568-10-04 for Thai, 2025-10-04 for others)
  String toLocalizedDateOnly(BuildContext context)
  
  // Short date (2568/10/4 for Thai, 2025/10/4 for others)
  String toLocalizedShortDate(BuildContext context)
  
  // Date and time (2568-10-04 14:30 for Thai)
  String toLocalizedDateTime(BuildContext context)
  
  // Custom format
  String toLocalizedString(BuildContext context, {String format})
}
```

### Helper Class

```dart
class LocalizedDateHelper {
  // Check if Thai locale
  static bool isThaiLocale(BuildContext context);
  
  // Convert years
  static int toBuddhistYear(int gregorianYear);    // 2025 → 2568
  static int toGregorianYear(int buddhistYear);    // 2568 → 2025
  
  // Format with locale
  static String formatDate(BuildContext context, DateTime? date, {String format});
  
  // Parse localized input
  static DateTime? parseLocalizedDate(BuildContext context, String dateString, {String format});
}
```

## 📋 Migration Checklist

When updating existing code:

- [ ] Identify user-facing date displays (not tests!)
- [ ] Ensure BuildContext is available
- [ ] Replace `.dateOnly()` with `.toLocalizedDateOnly(context)`
- [ ] Test with Thai locale (`th`)
- [ ] Verify tests still pass (they use `.dateOnly()`)
- [ ] Check database still has Gregorian dates

## 🎨 Examples by Use Case

### Lists
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.date.toLocalizedDateOnly(context)),
    );
  },
)
```

### Tables
```dart
DataTable(
  rows: items.map((item) => DataRow(
    cells: [
      DataCell(Text(item.name)),
      DataCell(Text(item.date.toLocalizedDateOnly(context))),
    ],
  )).toList(),
)
```

### Forms
```dart
Text(_selectedDate?.toLocalizedDateOnly(context) ?? 'Select date')
```

### Custom Formats
```dart
Text(event.date.toLocalizedString(context, format: 'dd MMMM yyyy'))
// Thai: "04 ตุลาคม 2568"
// English: "04 October 2025"
```

## ⚠️ Important Rules

### ✅ DO

- Use `toLocalizedDateOnly(context)` for UI display
- Keep using `dateOnly()` in tests
- Let DateTime objects stay in Gregorian (they already are)
- Pass dates to backend as-is (automatic UTC conversion)

### ❌ DON'T

- Don't use `toLocalizedDateOnly()` in tests
- Don't convert dates to BE before sending to backend
- Don't hard-code BE years in code
- Don't modify database to store BE dates

## 🧪 Testing

Tests remain unchanged:

```dart
// ✅ Correct
test('order date formatting', () {
  final order = FinDoc(placedDate: DateTime(2025, 10, 4));
  expect(order.placedDate.dateOnly(), '2025-10-04');
});

// ❌ Wrong
test('order date formatting', () {
  final order = FinDoc(placedDate: DateTime(2025, 10, 4));
  // Don't use localized methods in tests
  expect(order.placedDate.toLocalizedDateOnly(context), '2568-10-04');
});
```

## 🌍 Supported Locales

| Locale Code | Language | Calendar |
|-------------|----------|----------|
| `en` | English | Gregorian (2025) |
| `th` | Thai | Buddhist Era (2568) |
| `en_CA` | English (Canada) | Gregorian (2025) |

## 🔧 Implementation Files

| File | Purpose |
|------|---------|
| `growerp_core/lib/src/date_format_extensions.dart` | Extension implementation |
| `growerp_core/lib/src/domains/common/bloc/locale_bloc.dart` | Locale state management |
| `growerp_core/lib/src/extensions.dart` | Legacy `dateOnly()` method |

## 📦 Dependencies

- `intl` package (already included)
- `flutter/material.dart` (for BuildContext)

## 🐛 Troubleshooting

### "The method 'toLocalizedDateOnly' isn't defined"

**Solution**: Import growerp_core
```dart
import 'package:growerp_core/growerp_core.dart';
```

### "BuildContext not available"

**Solution**: Pass context from widget or use Builder
```dart
Builder(
  builder: (context) => Text(date.toLocalizedDateOnly(context)),
)
```

### "Tests failing with BE dates"

**Solution**: Tests should use `dateOnly()`, not `toLocalizedDateOnly()`
```dart
expect(date.dateOnly(), '2025-10-04');  // Correct
```

### "Date picker shows wrong year"

**Note**: Date pickers use Gregorian internally (Flutter limitation). The selected date will display correctly with localization.

## 📞 Support

- Questions? Check the [Full Guide](Buddhist_Era_Date_Formatting_Guide.md)
- Examples? See [Code Examples](examples/buddhist_era_date_examples.dart)
- Architecture? Read [Implementation Summary](Buddhist_Era_Implementation_Summary.md)

## 🎓 Learn More

- [Thai Buddhist Calendar (Wikipedia)](https://en.wikipedia.org/wiki/Thai_solar_calendar)
- [Flutter Internationalization Guide](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization)
- [Intl Package Documentation](https://pub.dev/packages/intl)

---

**Version**: 1.0  
**Last Updated**: October 2025  
**Status**: ✅ Infrastructure Complete - Ready for UI Migration
