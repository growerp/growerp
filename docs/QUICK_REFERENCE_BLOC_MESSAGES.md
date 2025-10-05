# Quick Reference: Using BLoC Messages in growerp_user_company

## For BLoC Developers

### Emitting Simple Messages
```dart
emit(state.copyWith(
  status: Status.success,
  message: 'operationSuccess',  // Just the l10n key
));
```

### Emitting Parameterized Messages
```dart
emit(state.copyWith(
  status: Status.success,
  message: 'userAddSuccess:${user.name}',  // key:param format
));
```

### Multiple Parameters (if needed)
```dart
message: 'orderCreated:${orderId}:${customerName}:${amount}'
```

## For UI Developers

### In BlocListener
```dart
BlocListener<YourBloc, YourState>(
  listener: (context, state) {
    if (state.message != null && state.message!.isNotEmpty) {
      final l10n = UserCompanyLocalizations.of(context)!;
      final translated = translateUserCompanyBlocMessage(l10n, state.message!);
      
      if (translated.isNotEmpty) {
        HelperFunctions.showMessage(
          context,
          translated,
          state.status == Status.success ? Colors.green : Colors.red,
        );
      }
    }
  },
  child: YourWidget(),
)
```

### Required Imports
```dart
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';
import 'package:growerp_user_company/src/common/translate_bloc_messages.dart';
```

## For Localization

### Adding a New Message

1. **Add to English .arb** (`lib/l10n/intl_en.arb`):
```json
{
  "myNewMessage": "Operation {name} completed",
  "@myNewMessage": {
    "description": "Success message for operation",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

2. **Add to Other Languages** (nl, de, fr, th, zh):
```json
{
  "@@locale": "nl",
  "myNewMessage": "Bewerking {name} voltooid"
}
```

3. **Run Localization Generator**:
```bash
cd flutter
melos l10n --no-select
```

4. **Update Translator** (`lib/src/common/translate_bloc_messages.dart`):
```dart
// In appropriate translator function
if (messageKey.contains(':')) {
  final parts = messageKey.split(':');
  final key = parts[0];
  final param = parts.length > 1 ? parts.sublist(1).join(':') : '';
  
  switch (key) {
    case 'myNewMessage':
      return l10n.myNewMessage(param);
    // ... other cases
  }
}
```

5. **Use in BLoC**:
```dart
message = 'myNewMessage:${operationName}';
```

## Message Key Naming Convention

- **Operation + Result**: `{entity}{operation}{result}`
  - `userAddSuccess`
  - `companyUpdateFailure`
  - `orderDeleteSuccess`
  
- **Simple operations**: `{scope}{operation}{result}`
  - `compUserUploadSuccess`
  - `dataFetchFailure`

## Available Translators

1. `translateUserBlocMessage(l10n, key)` - User messages only
2. `translateCompanyBlocMessage(l10n, key)` - Company messages only
3. `translateCompanyUserBlocMessage(l10n, key)` - Generic (tries all)

**Recommendation**: Use `translateUserCompanyBlocMessage()` for simplicity unless performance is critical.

## Common Messages Already Available

### User Messages
- `userUpdateSuccess:${name}`
- `userDeleteSuccess:${name}`
- `userAddSuccess:${name}`
- `userUpdateFailure`
- `userDeleteFailure`
- `userAddFailure`
- `userFetchFailure`
- `userValidationError`

### Company Messages
- `companyUpdateSuccess:${name}`
- `companyAddSuccess:${name}`
- `companyUpdateFailure`
- `companyDeleteSuccess`
- `companyDeleteFailure`
- `companyAddFailure`
- `companyFetchFailure`

### CompanyUser Messages
- `compUserUploadSuccess`
- `compUserUploadFailure`
- `compUserDownloadSuccess`
- `compUserDownloadFailure`

## Troubleshooting

### Message Not Translated
- Check if key exists in .arb files
- Verify translator function includes the case
- Ensure l10n was regenerated after .arb changes
- Check for typos in key name

### Parameter Not Showing
- Verify `{name}` placeholder in .arb file
- Check placeholder metadata in English .arb
- Ensure using `:` delimiter in BLoC: `'key:param'`
- Verify translator parses parameters correctly

### Wrong Language
- Check device/app locale setting
- Verify all .arb files have @@locale
- Ensure translation exists in target language file

## Testing

```dart
// Example test
test('translates parameterized user add success', () {
  final message = 'userAddSuccess:John Doe';
  final result = translateUserBlocMessage(l10n, message);
  expect(result, contains('John Doe'));
});
```

## Best Practices

✅ **DO**:
- Use colon delimiter for parameters: `'key:param'`
- Keep message keys in .arb files
- Use translator functions in UI
- Add translations for all 6 languages
- Include placeholder metadata in English .arb

❌ **DON'T**:
- Import l10n in BLoC files
- Hardcode translated strings
- Use JSON encoding for messages
- Skip non-English translations
- Forget to regenerate l10n after .arb changes

## Performance Notes

- String split is very fast (~nanoseconds)
- Switch statements compile to jump tables
- No JSON parsing overhead
- Minimal memory allocations
- Safe for high-frequency operations

---

For live examples, see any `growerp_*` package (e.g., `flutter/packages/growerp_user_company/`)
