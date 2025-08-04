# GrowERP Timezone Quick Reference

## Quick Usage Examples

### 🏷️ Model Definition
```dart
@freezed
class MyModel with _$MyModel {
  factory MyModel({
    @DateTimeConverter() DateTime? createdDate,
    @DateTimeConverter() DateTime? modifiedDate,
  }) = _MyModel;
}
```

### 📝 Form Handling
```dart
// Form initialization (server UTC → local display)
FormBuilderDateTimePicker(
  initialValue: model.date?.toLocal(),
  format: DateFormat('yyyy/M/d'),
)

// Form submission (local → server UTC)
DateTime? localDate = formData['date'] as DateTime?;
MyModel(createdDate: localDate?.toServerTime())
```

### 🎨 Display Formatting
```dart
// Simple date display
Text(TimeZoneHelper.formatLocalDate(model.date))

// Custom format
Text(TimeZoneHelper.formatLocalDateTime(
  model.date, 
  format: 'MMM d, yyyy HH:mm'
))

// Using extensions
Text(model.date?.toLocal().dateOnly() ?? '')
```

### 🔄 Manual Conversion
```dart
// Local to UTC for server
DateTime utcTime = localTime.toServerTime();

// Server string to local time
DateTime localTime = TimeZoneHelper.fromServerTime(serverString);

// Safe parsing
DateTime? safeDate = serverString?.toDateTimeSafe();
```

### ✅ Date Comparisons
```dart
// Same local date check
bool sameDay = TimeZoneHelper.isSameLocalDate(date1, date2);

// Always compare in UTC
bool isAfter = date1.toUtc().isAfter(date2.toUtc());
```

## 🚨 Common Patterns to Avoid

```dart
// ❌ Don't do this
DateTime.now().toString()              // Timezone ambiguous
model.date = DateTime.parse(string)    // No timezone handling
date1.compareTo(date2)                 // Timezone-dependent

// ✅ Do this instead
TimeZoneHelper.formatLocalDate(DateTime.now())
model.date = serverString?.toDateTimeSafe()
date1.toUtc().compareTo(date2.toUtc())
```

## 🔧 Debugging Commands

```dart
// Debug timezone info
debugPrint('Local: ${date}');
debugPrint('UTC: ${date.toUtc()}');
debugPrint('Offset: ${date.timeZoneOffset}');
debugPrint('ISO: ${date.toUtc().toIso8601String()}');
```

## 📋 Migration Checklist

- [ ] Add `@DateTimeConverter()` to model DateTime fields
- [ ] Update form `initialValue` to use `.toLocal()`
- [ ] Replace `DateTime.toString()` with `TimeZoneHelper.formatLocalDate()`
- [ ] Use `.toServerTime()` in form submissions
- [ ] Update date comparisons to use UTC
- [ ] Test with different system timezones

## 🏗️ Files to Import

```dart
import 'package:growerp_core/growerp_core.dart'; // TimeZoneHelper, extensions
import 'package:intl/intl.dart';                 // DateFormat
```

---
*For complete details, see [GrowERP_Timezone_Management_Guide.md](./GrowERP_Timezone_Management_Guide.md)*
