# Language Selection Guide for GrowERP

This guide explains how to use the in-app language selection feature that has been implemented in GrowERP.

## Overview

The GrowERP application now supports dynamic language switching between English and Thai without requiring users to change their device system language. This is implemented using Flutter's internationalization (i18n) system with a custom LocaleBloc for state management.

## How Users Can Change Language

### Method 1: In-App Language Selector (Recommended)

1. **On the Home/Login Screen:**
   - Look for the language icon (🌐) in the top-right corner of the app bar
   - Tap the language icon to open the language selection menu
   - Choose between:
     - 🇺🇸 **English** - Switch to English interface
     - 🇹🇭 **ไทย** - Switch to Thai interface
   - The app will immediately update to show the selected language
   - Your language preference is automatically saved and will persist across app restarts

### Method 2: Device System Language (Automatic)

1. **Change Device Language:**
   - Go to your device's **Settings**
   - Navigate to **Language & Region** (iOS) or **Language & Input** (Android)
   - Set your system language to Thai (ไทย)
   - Restart the GrowERP app
   - The app will automatically detect and use Thai

## Supported Languages

Currently supported languages:
- **English (en)** - Default language
- **Thai (th)** - Full translation available

## Technical Implementation

### Components Added:

1. **LocaleBloc** - Manages app locale state and persistence
2. **Language Selector UI** - PopupMenuButton in the home form app bar
3. **Persistent Storage** - Uses SharedPreferences to remember user's choice
4. **Dynamic Locale Loading** - TopApp widget responds to locale changes

### Key Features:

- ✅ **Persistent Language Selection** - Choice is saved and restored on app restart
- ✅ **Real-time Language Switching** - No app restart required
- ✅ **Visual Language Indicators** - Flag emojis for easy identification
- ✅ **Accessibility Support** - Proper tooltips and key identifiers for testing
- ✅ **Fallback Support** - Defaults to English if translation is missing

## Translated Strings

The following UI elements are now localized:

| English | Thai |
|---------|------|
| Welcome to The GrowERP Business System | ยินดีต้อนรับสู่ระบบธุรกิจ GrowERP |
| Login | เข้าสู่ระบบ |
| Logout | ออกจากระบบ |
| Register new Company and Administrator | ลงทะเบียนบริษัทและผู้ดูแลระบบใหม่ |
| Select Language | เลือกภาษา |

## For Developers

### Adding New Languages

1. Create new ARB file: `flutter/packages/growerp_core/lib/src/l10n/intl_[locale].arb`
2. Add translations for all existing keys
3. Add the new locale to `supportedLocales` in `top_app.dart`
4. Add menu item in the language selector popup
5. Run `melos l10n` to generate localization files

### Adding New Translatable Strings

1. Add the key-value pair to `intl_en.arb`
2. Add translations to all other language files (`intl_th.arb`, etc.)
3. Run `melos l10n` to regenerate localization classes
4. Use `CoreLocalizations.of(context)!.yourKey` in your widgets

### Testing Language Selection

Use these key identifiers for automated testing:
- `Key('languageSelector')` - Language selection button
- `Key('HomeFormUnAuth')` - Home form app bar
- Language changes can be tested by dispatching `LocaleChanged` events to the LocaleBloc

## Troubleshooting

### Language Not Changing
- Ensure the LocaleBloc is properly provided in the widget tree
- Check that `melos l10n` was run after adding new translations
- Verify the locale is supported in `top_app.dart`

### Missing Translations
- Check that all ARB files contain the same keys
- Run `melos l10n` to see untranslated message reports
- Add missing translations and regenerate

### Persistence Issues
- Ensure SharedPreferences dependency is available
- Check device storage permissions
- Clear app data if preferences become corrupted

## Future Enhancements

Potential improvements for the language selection system:
- Add more languages (Chinese, Japanese, Spanish, etc.)
- Implement RTL (Right-to-Left) language support
- Add language-specific date/time formatting
- Include currency formatting based on locale
- Add voice-over support for accessibility

## Support

For issues related to language selection or translations, please:
1. Check this guide first
2. Verify your implementation follows the technical requirements
3. Test with the provided key identifiers
4. Report bugs with specific language/translation combinations
