# Buddhist Era Quick Reference Card

## 🎯 Quick Decision Guide

```
Is this code for UI display to users?
  ├─ YES → Use .toLocalizedDateOnly(context)
  │
  └─ NO → Is this a test?
      ├─ YES → Use .dateOnly() 
      │
      └─ NO → Is this backend communication?
          ├─ YES → Use DateTime as-is (automatic UTC conversion)
          │
          └─ Use .dateOnly() (non-localized)
```

## 🔄 Common Replacements

```dart
// OLD (everywhere)
Text(item.date.dateOnly())

// NEW (in UI code)
Text(item.date.toLocalizedDateOnly(context))

// UNCHANGED (in tests)
expect(item.date.dateOnly(), '2025-10-04')
```

## 📝 Quick Examples

### List Display
```dart
ListTile(
  subtitle: Text(order.placedDate.toLocalizedDateOnly(context)),
)
```

### Table Cell
```dart
DataCell(Text(subscription.fromDate.toLocalizedDateOnly(context)))
```

### Custom Format
```dart
Text(event.date.toLocalizedString(context, format: 'dd/MM/yyyy'))
```

### Date Picker Display
```dart
Text(_selectedDate?.toLocalizedDateOnly(context) ?? 'Select date')
```

## 🌍 What Users See

| Locale | Input Date | Display |
|--------|-----------|---------|
| English (`en`) | 2025-10-04 | 2025-10-04 |
| Thai (`th`) | 2025-10-04 | 2568-10-04 |

## ⚠️ Remember

- ✅ Database always stores Gregorian (2025)
- ✅ Tests always use Gregorian (2025)
- ✅ Backend always uses Gregorian (2025)
- ✅ UI shows Buddhist Era for Thai (2568)

## 🔢 Conversion Formula

```dart
Buddhist Era = Gregorian Year + 543

2025 + 543 = 2568
```

## 📚 Full Documentation

See: `docs/Buddhist_Era_Date_Formatting_Guide.md`
