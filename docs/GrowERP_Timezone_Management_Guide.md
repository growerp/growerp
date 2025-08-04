# GrowERP Timezone Management Implementation Guide

## Overview

GrowERP implements a comprehensive timezone management system to ensure consistent date/time handling between clients and servers in different timezones. This document explains the implementation details and provides usage guidelines.

## Problem Statement

In distributed applications, timezone differences between server and client can cause:
- Dates appearing incorrectly for users in different timezones
- Data inconsistency when users from multiple timezones interact
- Business logic errors due to timezone-sensitive calculations
- Poor user experience with confusing date displays

## Solution Architecture

GrowERP solves these issues through a multi-layered approach:

### 1. UTC-First Storage Strategy
- All dates/times are stored on the server in UTC
- Client-server communication uses UTC timestamps
- Local timezone conversion only for display purposes

### 2. Automatic Conversion Layer
- `DateTimeConverter` handles JSON serialization/deserialization
- Extensions provide easy timezone conversion methods
- Helper utilities for common timezone operations

### 3. Locale-Aware Display
- Dates formatted according to user's locale and timezone
- Support for different date formats (yyyy/M/d, etc.)
- Consistent date picker behavior across locales

## Implementation Details

### Core Components

#### 1. DateTimeConverter (`growerp_models/lib/src/json_converters.dart`)

```dart
class DateTimeConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    try {
      // Parse timestamp and ensure it's treated as UTC from server
      DateTime? parsed = DateTime.tryParse(json);
      if (parsed != null) {
        // If no timezone info, treat as UTC and convert to local
        if (!json.contains('Z') && !json.contains('+') && !json.contains('-', 10)) {
          return DateTime.parse(json + 'Z').toLocal();
        }
        return parsed.toLocal(); // Convert to local time for display
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    // Always send to server in UTC to avoid timezone issues
    return object.toUtc().toIso8601String();
  }
}
```

**Key Features:**
- Automatically converts incoming dates from UTC to local time
- Ensures outgoing dates are sent as UTC ISO strings
- Handles both timezone-aware and naive datetime strings
- Graceful error handling for malformed dates

#### 2. TimeZone Extensions (`growerp_core/lib/src/extensions.dart`)

```dart
extension DateTimeUtc on DateTime {
  /// Convert to UTC for server communication
  DateTime toServerTime() => toUtc();
  
  /// Convert from server time (assumed UTC) to local time
  static DateTime fromServerTime(String serverTimeString) {
    // Implementation handles various server time formats
  }
}

extension DateTimeSafeParser on String {
  /// Safely parse a date string from server, assuming UTC if no timezone info
  DateTime? toDateTimeSafe() {
    // Safe parsing with timezone handling
  }
}
```

**Benefits:**
- Easy-to-use extension methods on DateTime objects
- Consistent naming convention (`toServerTime`, `fromServerTime`)
- Safe parsing methods that handle edge cases

#### 3. TimeZoneHelper Utility (`growerp_core/lib/src/services/timezone_helper.dart`)

```dart
class TimeZoneHelper {
  /// Convert a local DateTime to UTC for server communication
  static DateTime toServerTime(DateTime localTime) => localTime.toUtc();
  
  /// Convert a server timestamp (assumed UTC) to local time for display
  static DateTime fromServerTime(String serverTimeString) { ... }
  
  /// Format a DateTime for display in local timezone
  static String formatLocalDate(DateTime? dateTime, {String format = 'yyyy/M/d'}) { ... }
  
  /// Format a DateTime for display with time in local timezone
  static String formatLocalDateTime(DateTime? dateTime, {String format = 'yyyy/M/d HH:mm'}) { ... }
  
  /// Check if two dates are the same day in local time
  static bool isSameLocalDate(DateTime? date1, DateTime? date2) { ... }
  
  /// Convert a date-only string (YYYY-MM-DD) to DateTime at midnight UTC
  static DateTime? dateStringToUtc(String? dateString) { ... }
  
  /// Convert a DateTime to date-only string in local timezone
  static String? dateTimeToDateString(DateTime? dateTime) { ... }
}
```

**Advantages:**
- Centralized timezone logic
- Utility methods for common operations
- Consistent date formatting across the application
- Easy testing and maintenance

#### 4. Locale Configuration (`growerp_core/lib/src/domains/common/widgets/top_app.dart`)

```dart
MaterialApp(
  locale: const Locale('en', 'CA'), // Canadian English uses ISO-style dates
  supportedLocales: const [Locale('en'), Locale('th'), Locale('en', 'CA')],
  localizationsDelegates: localizationsDelegates,
  // ... other properties
)
```

**Purpose:**
- Sets application-wide locale for consistent date formatting
- Canadian locale provides yyyy-MM-dd style dates
- Supports multiple locales for internationalization

## Usage Guidelines

### 1. Model Definitions

When defining models that include DateTime fields, use the `@DateTimeConverter()` annotation:

```dart
@freezed
class MyModel with _$MyModel {
  factory MyModel({
    String? id,
    @DateTimeConverter() DateTime? createdDate,
    @DateTimeConverter() DateTime? modifiedDate,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

### 2. Form Handling

When working with date forms, convert between local and server time:

```dart
// In form submission
DateTime? localDate = formData['date'] as DateTime?;
MyModel model = MyModel(
  createdDate: localDate?.toServerTime(), // Convert to UTC for server
);

// In form initialization
FormBuilderDateTimePicker(
  name: 'date',
  initialValue: model.createdDate?.toLocal(), // Convert to local for display
  format: DateFormat('yyyy/M/d'),
)
```

### 3. Date Display

For displaying dates in the UI:

```dart
// Using TimeZoneHelper
String displayDate = TimeZoneHelper.formatLocalDate(
  myModel.createdDate, 
  format: 'yyyy/M/d'
);

// Using extensions
String dateOnly = myModel.createdDate?.toLocal().dateOnly();
```

### 4. Date Comparisons

When comparing dates:

```dart
// Check if same local date
bool isSame = TimeZoneHelper.isSameLocalDate(date1, date2);

// Compare in specific timezone
DateTime utcDate1 = date1.toUtc();
DateTime utcDate2 = date2.toUtc();
bool isAfter = utcDate1.isAfter(utcDate2);
```

### 5. API Communication

The conversion is handled automatically, but for manual API calls:

```dart
// Sending to server
Map<String, dynamic> payload = {
  'date': myDateTime.toServerTime().toIso8601String(),
};

// Receiving from server
DateTime localDate = TimeZoneHelper.fromServerTime(response['date']);
```

## Best Practices

### 1. Consistency Rules

- **Always store in UTC**: Server database should only contain UTC timestamps
- **Display in local**: Users should always see dates in their local timezone
- **Convert at boundaries**: Transform timezones at API and UI boundaries only
- **Use extensions**: Leverage provided extension methods for clarity

### 2. Testing Considerations

```dart
// Test with different timezones
test('date conversion handles different timezones', () {
  // Set test timezone
  DateTime testDate = DateTime(2025, 8, 2, 10, 0); // Local time
  DateTime utcDate = testDate.toServerTime();
  
  expect(utcDate.isUtc, true);
  expect(utcDate.toLocal(), testDate);
});
```

### 3. Error Handling

```dart
// Safe date parsing
DateTime? safeDate = serverDateString?.toDateTimeSafe();
if (safeDate == null) {
  // Handle parsing error
  return DateTime.now(); // or appropriate fallback
}
```

### 4. Performance Considerations

- Timezone conversions are lightweight operations
- Cache formatted dates for repeated display
- Use UTC for all date arithmetic and comparisons
- Convert to local time only for final display

## Migration Guide

### Existing Code Migration

1. **Update Model Annotations**:
   ```dart
   // Before
   DateTime? createdDate,
   
   // After
   @DateTimeConverter() DateTime? createdDate,
   ```

2. **Update Form Handling**:
   ```dart
   // Before
   initialValue: widget.model.date,
   
   // After
   initialValue: widget.model.date?.toLocal(),
   ```

3. **Update Date Display**:
   ```dart
   // Before
   Text(model.date?.toString() ?? ''),
   
   // After
   Text(TimeZoneHelper.formatLocalDate(model.date) ?? ''),
   ```

### Backward Compatibility

The implementation is designed to be backward compatible:
- Existing date strings without timezone info are treated as UTC
- `DateTime.toString()` still works but should be replaced gradually
- Old models continue to work with gradual migration

## Troubleshooting

### Common Issues

1. **Dates appear wrong by several hours**
   - Ensure `@DateTimeConverter()` is used on model fields
   - Check that form initial values use `.toLocal()`
   - Verify server stores dates in UTC

2. **Date picker shows incorrect format**
   - Verify locale is set in `TopApp`
   - Check `DateFormat` pattern in form fields
   - Ensure `FormBuilderDateTimePicker` uses correct format

3. **API responses have incorrect dates**
   - Check server timezone configuration
   - Verify API returns UTC timestamps
   - Use `TimeZoneHelper.fromServerTime()` for manual parsing

### Debug Tips

```dart
// Debug timezone conversion
debugPrint('Local time: ${localDate}');
debugPrint('UTC time: ${localDate.toUtc()}');
debugPrint('Timezone offset: ${localDate.timeZoneOffset}');
debugPrint('ISO string: ${localDate.toUtc().toIso8601String()}');
```

## Future Enhancements

### Planned Improvements

1. **User Timezone Preferences**: Allow users to set preferred display timezone
2. **Timezone-Aware Business Rules**: Handle business logic that depends on specific timezones
3. **Advanced Locale Support**: Enhanced formatting for different regions
4. **Performance Optimization**: Caching and optimization for large datasets

### Extension Points

The system is designed for easy extension:
- Add new date formats through `TimeZoneHelper`
- Extend `DateTimeConverter` for custom serialization
- Create specialized converters for different API endpoints

## Conclusion

The GrowERP timezone management system provides:
- **Consistency**: All dates stored and processed uniformly
- **User Experience**: Dates displayed in user's local timezone
- **Developer Experience**: Simple APIs and clear patterns
- **Maintainability**: Centralized logic and clear separation of concerns

By following this implementation guide, developers can ensure robust timezone handling throughout the GrowERP application while maintaining code clarity and user satisfaction.

---

*This document should be updated as the timezone implementation evolves or new requirements emerge.*
