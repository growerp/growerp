# GrowERP Locale Handling Guide

**Date Created**: October 5, 2025  
**Status**: Implemented and Active

## Overview

GrowERP automatically sets the backend locale based on the frontend user's locale during registration and login. This ensures that all backend-generated messages (emails, error messages, etc.) are displayed in the user's preferred language.

## How It Works

### 1. Frontend Locale Detection

The Flutter frontend automatically detects the user's device locale using:

```dart
// In auth_bloc.dart during registration
locale: PlatformDispatcher.instance.locale
```

This captures the user's device locale (e.g., `th` for Thai, `nl` for Dutch, `en` for English) and sends it to the backend.

### 2. Backend Locale Storage

During user registration or account creation, the locale is stored in the `moqui.security.UserAccount` table:

**Field**: `locale` (String)  
**Format**: ISO language code (e.g., `th`, `nl`, `en`) or locale code (e.g., `th_TH`, `nl_NL`, `en_US`)

### 3. Services That Handle Locale

#### Registration (`register#User` and `register#WebsiteUser`)

Both registration services accept and store the user's locale:

```xml
<service verb="register" noun="User" authenticate="anonymous-all">
    <in-parameters>
        ...
        <parameter name="locale" />
        <parameter name="timeZoneOffset" />
    </in-parameters>
    <actions>
        <!-- Locale is passed to create#User -->
        <set field="user" from="[
            ...
            locale: locale,
            timeZoneOffset: timeZoneOffset,
            ...]" />
        <service-call name="growerp.100.PartyServices100.create#User"
            in-map="[user: user, ...]" />
    </actions>
</service>
```

#### User Creation (`create#User`)

The `create#User` service passes locale to Moqui's `create#Account` service:

```xml
<service verb="create" noun="User">
    <actions>
        <set field="inMap" from="[
            ...
            locale: user.locale,
            timeZone: user.timeZoneOffset
        ]" />
        <service-call name="mantle.party.PartyServices.create#Account"
            in-map="inMap" out-map="userAccount" />
    </actions>
</service>
```

#### User Update (`update#User`)

The `update#User` service allows locale to be changed:

```xml
<service verb="update" noun="User">
    <actions>
        <service-call name="mantle.party.PartyServices.update#PartyUserAccount"
            in-map="[
                partyId: user.partyId,
                locale: user.locale ?: oldValue.user.locale,
                timeZone: user.timeZoneOffset ?: oldValue.user.timeZoneOffset
            ]" />
    </actions>
</service>
```

### 4. Locale Usage in Moqui

Once a user logs in, Moqui automatically:

1. **Loads the user's locale** from the `UserAccount.locale` field
2. **Sets the execution context locale** (`ec.user.locale`)
3. **Uses this locale** for all `ec.l10n.localize()` calls

This happens in `UserFacadeImpl.groovy`:

```groovy
String localeStr = ua.locale
if (localeStr != null && localeStr.length() > 0) {
    int usIdx = localeStr.indexOf("_")
    localeCache = usIdx < 0 ? new Locale(localeStr) :
            new Locale(localeStr.substring(0, usIdx), 
                      localeStr.substring(usIdx+1).toUpperCase())
}
```

## Implementation Details

### Frontend Implementation

**File**: `flutter/packages/growerp_core/lib/src/domains/authenticate/blocs/auth_bloc.dart`

```dart
// During registration
final result = await restClient.register(
  classificationId: classificationId,
  email: event.user.email!,
  firstName: event.user.firstName!,
  lastName: event.user.lastName!,
  userGroup: event.user.userGroup!,
  newPassword: kReleaseMode ? null : 'qqqqqq9!',
  timeZoneOffset: DateTime.now().timeZoneOffset.toString(),
  locale: PlatformDispatcher.instance.locale, // <-- Automatic locale detection
);
```

### Backend Services Updated

#### ✅ `register#User` (PartyServices100.xml)
- Accepts `locale` parameter
- Passes to `create#User`
- Used for new admin registration

#### ✅ `register#WebsiteUser` (PartyServices100.xml)
- Accepts `locale` parameter  
- Passes to `create#Account`
- Used for customer/website registration

#### ✅ `create#User` (PartyServices100.xml)
- Accepts `user.locale` parameter
- Passes to `create#Account`
- Stores in UserAccount table

#### ✅ `update#User` (PartyServices100.xml)
- Accepts `user.locale` parameter
- Updates UserAccount via `update#PartyUserAccount`
- Allows users to change their locale preference

## Supported Locales

Currently supported languages:

| Language | Code | Status |
|----------|------|--------|
| English | `en` | ✅ Default |
| Thai | `th` | ✅ Complete |
| Dutch | `nl` | ✅ Complete |

Future languages (infrastructure ready):
- Spanish (`es`)
- German (`de`)
- French (`fr`)
- Chinese (`zh`)

## Testing

### Test Registration with Locale

**Frontend Test (Flutter):**
```dart
// User registers with Thai locale
final user = User(
  email: 'test@example.com',
  firstName: 'สมชาย',
  lastName: 'ใจดี',
  userGroup: UserGroup.customer,
);

// Device locale is automatically detected and sent
await authBloc.add(AuthRegister(user));
```

**Backend Verification:**
```sql
-- Check that locale was stored
SELECT user_id, username, locale, time_zone 
FROM moqui.security.UserAccount 
WHERE username = 'test@example.com';
```

### Test Localized Email

After registration, the welcome email should be in the user's locale:

**For Thai user:**
```
ยินดีต้อนรับสู่ระบบ GrowERP Admin, สมชาย ใจดี
```

**For Dutch user:**
```
Welkom bij het GrowERP Admin systeem, Jan de Vries
```

### Test Locale Change

**Update user locale:**
```dart
final updatedUser = currentUser.copyWith(
  locale: 'nl', // Change to Dutch
);
await userBloc.add(UserUpdate(updatedUser));
```

**Backend Service:**
```xml
<service-call name="growerp.100.PartyServices100.update#User"
    in-map="[user: [partyId: 'USER123', locale: 'nl']]" />
```

## Troubleshooting

### Issue: User receives emails in wrong language

**Check:**
1. Verify UserAccount.locale is set correctly:
   ```sql
   SELECT locale FROM moqui.security.UserAccount WHERE user_id = 'USER_ID';
   ```

2. Verify locale is valid (exists in GrowerpL10nData.xml):
   ```sql
   SELECT DISTINCT locale FROM moqui.basic.LocalizedMessage;
   ```

3. Check if message key exists for the locale:
   ```sql
   SELECT * FROM moqui.basic.LocalizedMessage 
   WHERE original = 'GrowerpEmailWelcomeGreeting' 
   AND locale = 'th';
   ```

### Issue: Locale not being set during registration

**Check:**
1. Frontend is sending locale parameter
2. Service is accepting locale parameter
3. Database column allows the value (VARCHAR check)

**Debug:**
```xml
<log level="info" message="Registering user with locale: ${locale}" />
```

### Issue: Locale changes are not persisting

**Check:**
1. `update#User` service is being called
2. `update#PartyUserAccount` is receiving locale parameter
3. Database transaction is committing

## Best Practices

1. **Always send locale from frontend** - Never rely on backend default
2. **Store locale, don't derive it** - Store in database, not calculated each time
3. **Validate locale codes** - Ensure they match supported locales
4. **Test all locales** - Every new feature should work in all supported languages
5. **Provide fallback** - Always have English as default if translation missing

## Related Documentation

- **L10n Implementation Plan**: `/docs/GrowERP_Backend_L10n_Implementation_Plan.md`
- **L10n Progress**: `/docs/GrowERP_Backend_L10n_Implementation_Progress.md`
- **L10n Quick Reference**: `/docs/GrowERP_Backend_L10n_Quick_Reference.md`
- **Moqui L10n Docs**: https://www.moqui.org/m/docs/framework/Localization

## API Reference

### Registration Endpoints

**POST** `/rest/s1/growerp/register`

Request body:
```json
{
  "classificationId": "AppAdmin",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "newPassword": "SecurePass1!",
  "locale": "en",
  "timeZoneOffset": "+00:00"
}
```

### User Update Endpoints

**PUT** `/rest/s1/growerp/users/{userId}`

Request body:
```json
{
  "user": {
    "partyId": "USER123",
    "firstName": "John",
    "lastName": "Doe",
    "locale": "nl",
    "timeZoneOffset": "+01:00"
  }
}
```

## Summary

✅ **Locale is automatically detected** from user's device  
✅ **Stored in UserAccount table** during registration  
✅ **Used for all localized messages** via `ec.l10n.localize()`  
✅ **Can be updated** by users at any time  
✅ **Applies to emails, errors, and all user-facing text**

The system ensures a seamless multi-language experience without requiring users to manually select their language preference.

---

**Last Updated**: October 5, 2025  
**Version**: 1.0  
**Status**: Production Ready
