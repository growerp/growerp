# GrowERP Backend L10n Quick Reference

## Quick Start Guide

### Using Localized Messages

#### In Email Templates (XML with CDATA)
```xml
<text type="html"><![CDATA[
    ${ec.resource.expand(ec.l10n.localize('GrowerpEmailWelcomeGreeting'), '')}
]]></text>
```

#### In Email Labels
```xml
<label text="${ec.l10n.localize('GrowerpPasswordResetSet')}"/>
```

#### In Service Return Messages
```xml
<return error="true" message="${ec.l10n.localize('GrowerpProductNotFound')}"/>
```

#### In Groovy Script Sections
```groovy
error = ec.l10n.localize('GrowerpOpenMrsInvalidCredentials')
```

#### With Variable Expansion
```xml
<!-- In CDATA with variables -->
${ec.resource.expand(ec.l10n.localize('GrowerpProductNotFound'), '')}

<!-- The message key should contain the variable placeholder -->
<!-- Original: "product ${product.productId} not found!" -->
```

## Available Message Keys

### Email Messages

| Key | Variables | Usage |
|-----|-----------|-------|
| `GrowerpEmailWelcomeGreeting` | `${classification}`, `${firstName!}`, `${lastName!}` | Welcome email greeting |
| `GrowerpEmailWelcomeAdminIntro` | - | Admin features intro |
| `GrowerpEmailWelcomeStripeInfo` | - | Stripe setup info |
| `GrowerpEmailWelcomeSupportInfo` | - | Support contact intro |
| `GrowerpEmailWelcomePasswordInfo` | `${newPassword}` | Login password info |
| `GrowerpEmailWelcomeTestSystemInfo` | - | Test system notice |
| `GrowerpEmailWelcomeRegisterAgain` | - | Re-registration prompt |
| `GrowerpEmailWelcomeTipsInfo` | - | Weekly tips notice |
| `GrowerpEmailWelcomeRegards` | - | Email closing |
| `GrowerpEmailWelcomeTeam` | `${classification}` | Team signature |
| `GrowerpEmailWelcomeTestNote` | - | Test system warning |
| `GrowerpPasswordResetSet` | `${resetPassword}` | Reset password value |
| `GrowerpPasswordResetInstructions` | - | How to use reset password |
| `GrowerpPasswordCurrentValid` | - | Current password still works |
| `GrowerpPasswordMustChange` | - | Must change before login |

### Integration Error Messages

| Key | Variables | Usage |
|-----|-----------|-------|
| `GrowerpBirdSendNotConfigured` | - | BirdSend not set up |
| `GrowerpMailerLiteNotConfigured` | - | MailerLite not set up |
| `GrowerpOpenMrsHostnameNotFound` | `${hostNames[0].settingValue}` | OpenMRS hostname missing |
| `GrowerpOpenMrsInvalidCredentials` | - | OpenMRS login failed |

### Entity Not Found Errors

| Key | Variables | Usage |
|-----|-----------|-------|
| `GrowerpAssetNotFound` | `${asset.assetId}` | Asset lookup failed |
| `GrowerpProductNotFound` | `${product.productId}` | Product lookup failed |
| `GrowerpCategoryNotFound` | `${category.categoryId}` | Category lookup failed |
| `GrowerpCompanyNotFound` | `${company.partyId}` | Company lookup failed |
| `GrowerpActivityNotFound` | `${activity.activityId}` | Activity lookup failed |
| `GrowerpOpportunityNotFound` | `${opportunity?.opportunityId}` | Opportunity lookup failed |
| `GrowerpChatRoomNotFound` | `${chatRoomId}` | Chat room lookup failed |
| `GrowerpSubscriptionNotFound` | `${subscription.subscriptionId}` | Subscription lookup failed |

### Validation Error Messages

| Key | Variables | Usage |
|-----|-----------|-------|
| `GrowerpWebsiteNameTaken` | `$newPart` | Website name already used |
| `GrowerpWebsitePathNotFound` | `$path` | Website path not found |
| `GrowerpNeedPostalAddressForCreditCard` | - | Address required for CC |
| `GrowerpCreateCompanyNeedsOwner` | - | Owner required to create company |
| `GrowerpTimeEntryAlreadyInvoiced` | - | Can't delete invoiced time |
| `GrowerpInvalidTypeValue` | `${companyUser.type}` | Invalid type parameter |
| `GrowerpInvalidRoleValue` | `${companyUser.role}` | Invalid role parameter |
| `GrowerpNoValidBase64Image` | - | Base64 image decode failed |
| `GrowerpActivityTypeRequired` | - | Activity type missing |
| `GrowerpActivityTypeNotSupported` | `$activityType` | Activity type invalid |

### Business Logic Error Messages

| Key | Variables | Usage |
|-----|-----------|-------|
| `GrowerpChatMessageIdRequired` | - | Missing required ID |
| `GrowerpRootCategoryNotFound` | `$ownerPartyId` | Root category missing |
| `GrowerpMandatoryRootCategoryNotFound` | `$ownerPartyId` | Critical: root category missing |
| `GrowerpCategoryRollupNotFound` | `${category.categoryId}` | Category hierarchy error |
| `GrowerpProductStoreNotFound` | `${path}`, `$companyPartyId` | Store not found |
| `GrowerpTextPageNotFound` | `${path}` | Page not found |
| `GrowerpImageNotFoundWithPath` | `${path}` | Image not found |
| `GrowerpAccountCodeNotFound` | `${paymentType.accountCode}`, `$companyPartyId` | GL account missing |
| `GrowerpCanOnlyDeleteInitialLedger` | - | Ledger delete restricted |
| `GrowerpEntityNotSupportedForExport` | `${entityName}` | Export not supported |

### Enumeration Descriptions

| Key | Usage |
|-----|-------|
| `GrowerpRequestTypeConsultation` | Request type: Consultation |

## Supported Languages

| Language | Code | Status |
|----------|------|--------|
| English (default) | `default` | ✅ Complete |
| Thai | `th` | ✅ Complete |
| Dutch | `nl` | ✅ Complete |

## Adding a New Message

### Step 1: Add to GrowerpL10nData.xml

```xml
<!-- Add at the appropriate section in the file -->
<moqui.basic.LocalizedMessage locale="default" original="GrowerpYourNewMessageKey"
    localized="Your English message with ${variable}" />
<moqui.basic.LocalizedMessage locale="th" original="GrowerpYourNewMessageKey"
    localized="ข้อความภาษาไทยของคุณพร้อม ${variable}" />
<moqui.basic.LocalizedMessage locale="nl" original="GrowerpYourNewMessageKey"
    localized="Uw Nederlandse bericht met ${variable}" />
```

### Step 2: Use in Code

**In XML service:**
```xml
<return error="true" message="${ec.l10n.localize('GrowerpYourNewMessageKey')}"/>
```

**In Groovy script:**
```groovy
errorMessage = ec.l10n.localize('GrowerpYourNewMessageKey')
```

**In email template (CDATA):**
```xml
${ec.resource.expand(ec.l10n.localize('GrowerpYourNewMessageKey'), '')}
```

### Step 3: Reload Data

```bash
cd moqui
java -jar moqui.war load types=seed-initial
```

## Message Key Naming Convention

**Format**: `Growerp[Module][Type][Description]`

**Modules**:
- `Email` - Email templates
- `Password` - Password-related
- `BirdSend`, `MailerLite`, `OpenMrs` - Integration services
- `Asset`, `Product`, `Category`, `Company`, etc. - Entity types
- `Website`, `Chat`, `Activity`, etc. - Functional areas

**Types**:
- (none) - General message
- `NotFound` - Entity not found errors
- `Invalid` - Validation errors
- `Required` - Required field/parameter
- `NotSupported` - Unsupported operation

**Examples**:
- ✅ `GrowerpEmailWelcomeGreeting`
- ✅ `GrowerpProductNotFound`
- ✅ `GrowerpActivityTypeRequired`
- ❌ `product_not_found` (wrong format)
- ❌ `growerpProductNotFound` (missing capital G)

## Variable Handling

### Rules
1. Always preserve `${variable}` placeholders
2. Variable names must match in all languages
3. Use `ec.resource.expand()` for variable substitution in CDATA
4. Test with actual data to verify variable expansion

### Examples

**Correct:**
```xml
<!-- English -->
<moqui.basic.LocalizedMessage locale="default" original="GrowerpWelcome"
    localized="Welcome ${firstName} ${lastName}" />

<!-- Thai - variables stay the same -->
<moqui.basic.LocalizedMessage locale="th" original="GrowerpWelcome"
    localized="ยินดีต้อนรับ ${firstName} ${lastName}" />
```

**Incorrect:**
```xml
<!-- DON'T translate variable names! -->
<moqui.basic.LocalizedMessage locale="th" original="GrowerpWelcome"
    localized="ยินดีต้อนรับ ${ชื่อ} ${นามสกุล}" />  ❌
```

## Troubleshooting

### Message Not Translating

**Check:**
1. Is the message key spelled correctly?
2. Is the locale set for the user?
3. Has the seed data been loaded?
4. Is there a 'default' locale entry?

**Debug:**
```xml
<log level="info" message="Current locale: ${ec.user.locale}"/>
<log level="info" message="Message: ${ec.l10n.localize('YourMessageKey')}"/>
```

### Variables Not Expanding

**Use `ec.resource.expand()` in CDATA:**
```xml
<!-- Wrong -->
${ec.l10n.localize('GrowerpProductNotFound')}

<!-- Right -->
${ec.resource.expand(ec.l10n.localize('GrowerpProductNotFound'), '')}
```

### Character Encoding Issues

**Ensure UTF-8:**
1. XML file has `<?xml version="1.0" encoding="UTF-8"?>`
2. Database uses UTF-8
3. File editor saves as UTF-8

## Testing

### Test Email in Different Locales

```xml
<service verb="test" noun="EmailLocale">
    <actions>
        <!-- Save current locale -->
        <set field="originalLocale" from="ec.user.locale"/>
        
        <!-- Test Thai -->
        <script>ec.user.setLocale(new Locale('th'))</script>
        <service-call name="YourEmailService"/>
        <!-- Check email content -->
        
        <!-- Test Dutch -->
        <script>ec.user.setLocale(new Locale('nl'))</script>
        <service-call name="YourEmailService"/>
        <!-- Check email content -->
        
        <!-- Restore locale -->
        <script>ec.user.setLocale(originalLocale)</script>
    </actions>
</service>
```

### Test Service Error Messages

```xml
<service verb="test" noun="ErrorLocale">
    <actions>
        <script>ec.user.setLocale(new Locale('th'))</script>
        
        <!-- Trigger error -->
        <service-call name="ServiceThatMightError" ignore-error="true"/>
        
        <!-- Verify error message is in Thai -->
        <assert><condition><expression>ec.message.messages.find { 
            it.message.contains('ไม่พบ') 
        } != null</expression></condition></assert>
    </actions>
</service>
```

## Best Practices

1. **Always provide 'default' locale** - Required for fallback
2. **Keep messages short** - Max 255 characters
3. **Use meaningful keys** - Easy to understand what message is
4. **Group by module** - Organize in GrowerpL10nData.xml
5. **Test with real data** - Verify variable expansion works
6. **Get native speaker review** - For important customer-facing messages
7. **Document variables** - Note what each variable represents

## Files to Edit

| Task | File |
|------|------|
| Add new messages | `/moqui/runtime/component/growerp/data/GrowerpL10nData.xml` |
| Email templates | `/moqui/runtime/component/growerp/screen/email/*.xml` |
| Service messages | `/moqui/runtime/component/growerp/service/**/*.xml` |
| Test locale | Create test services in appropriate service files |

## See Also

- **Implementation Plan**: `/docs/GrowERP_Backend_L10n_Implementation_Plan.md`
- **Progress Report**: `/docs/GrowERP_Backend_L10n_Implementation_Progress.md`
- **Moqui L10n Docs**: https://www.moqui.org/m/docs/framework/Localization

---

**Quick Questions?**

**Q: How do I change a user's locale?**  
A: Set `locale` field in `moqui.security.UserAccount` table (e.g., 'th', 'nl', 'en')

**Q: How do I add a new language?**  
A: Add new `<moqui.basic.LocalizedMessage>` entries with new locale code

**Q: Can I use HTML in messages?**  
A: Yes, for email templates - HTML is preserved in localized strings

**Q: What if a translation is missing?**  
A: System automatically falls back to 'default' locale (English)

---

**Last Updated**: October 5, 2025
