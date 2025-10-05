# GrowERP Backend L10n (Localization) Implementation Plan

## Executive Summary

This document outlines a comprehensive plan to add all user-facing strings from the GrowERP Moqui backend component to the localization (l10n) system. This will enable multi-language support for backend-generated messages, emails, and service responses.

## Current State Analysis

### Existing L10n Infrastructure in Moqui

Moqui framework provides a robust localization system:

1. **Entity**: `moqui.basic.LocalizedMessage`
   - Fields: `original`, `locale`, `localized`
   - Stores message translations indexed by original text and locale

2. **API**: `ec.l10n.localize(String original)`
   - Automatically looks up translations based on user's current locale
   - Falls back to original text if no translation exists

3. **Data Files**: XML files containing LocalizedMessage records
   - Example: `/moqui/framework/data/CommonL10nData.xml`
   - Example: `/moqui/runtime/component/mantle-usl/data/OrderInstallData.xml`

### Current User-Facing Strings in GrowERP Component

Based on analysis, user-facing strings are found in:

1. **Email Templates** (`/growerp/screen/email/`)
   - Welcome.xml - Welcome email with system introduction
   - PasswordReset.xml - Password reset instructions
   - *ExportBody.xml - Various export notifications

2. **Service Error Messages** (`/growerp/service/growerp/100/`)
   - BirdSendServices100.xml - "birdsend not configured..."
   - MailerLightServices100.xml - "mailerLight not configured..."
   - OpenMrsServices100.xml - Various OpenMRS integration errors
   - And others across all service files

3. **Service Success Messages**
   - Various informational messages returned to users

4. **Data Files** (`/growerp/data/`)
   - Enumeration descriptions
   - Status descriptions
   - Setup/demo data labels

## Localization Strategy

### Phase 1: String Extraction and Cataloging (Week 1-2)

#### 1.1 Automated Extraction
Create a script to extract user-facing strings from:

```bash
# Target files
- growerp/screen/email/**/*.xml
- growerp/service/**/*.xml  
- growerp/data/**/*.xml (descriptions and labels only)
```

**Extraction Criteria:**
- Text in `<label text="..."/>` tags
- Text in `message="..."` attributes (return/log messages)
- Text in `<![CDATA[...]]>` sections (email bodies)
- Text in `description="..."` for enumerations
- Hardcoded error/success messages in services

**Exclude:**
- Technical IDs and codes
- Field names (unless user-facing)
- XML/technical attributes
- URLs and email addresses (unless part of message)

#### 1.2 Create String Inventory

Create a spreadsheet/CSV with columns:
- **Original Text**: The English string
- **Context**: Where it's used (service/screen/data)
- **File Path**: Full path to source file
- **Line Number**: Location in file
- **Type**: email|error|success|label|description
- **Priority**: high|medium|low
- **Status**: pending|reviewed|translated

**Example entries:**
```csv
Original,Context,File Path,Line,Type,Priority,Status
"Welcome to the GrowERP ${classification} system",Email Welcome,screen/email/Welcome.xml,21,email,high,pending
"birdsend not configured see growerp/100/BirdSendServices100.xml",BirdSend Service,service/growerp/100/BirdSendServices100.xml,34,error,medium,pending
"Your reset password has been set to: ${resetPassword}",Password Reset Email,screen/email/PasswordReset.xml,18,email,high,pending
```

### Phase 2: String Standardization and Key Creation (Week 2-3)

#### 2.1 Create Message Keys

For each string, create a standardized key following Moqui conventions:

**Naming Pattern:**
```
[Component][Module][Type][Description]
```

**Examples:**
```
Original: "Welcome to the GrowERP ${classification} system"
Key: GrowerpEmailWelcomeGreeting

Original: "birdsend not configured"  
Key: GrowerpBirdSendNotConfigured

Original: "Your reset password has been set to: ${resetPassword}"
Key: GrowerpPasswordResetEmailBody

Original: "OpenMRS credentials not valid"
Key: GrowerpOpenMrsInvalidCredentials
```

#### 2.2 Handle Variable Substitution

Ensure all message keys preserve variable placeholders:
- Keep `${variable}` syntax intact
- Document required variables for each message
- Test that variable expansion works post-localization

### Phase 3: Create Localization Data Files (Week 3-4)

#### 3.1 Create Base L10n Data File

Create: `/moqui/runtime/component/growerp/data/GrowerpL10nData.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<entity-facade-xml type="seed-initial">
    
    <!-- Email Messages -->
    <moqui.basic.LocalizedMessage locale="default" 
        original="GrowerpEmailWelcomeGreeting"
        localized="Welcome to the GrowERP ${classification} system, ${firstName!} ${lastName!}" />
    <moqui.basic.LocalizedMessage locale="th" 
        original="GrowerpEmailWelcomeGreeting"
        localized="ยินดีต้อนรับสู่ระบบ GrowERP ${classification}, ${firstName!} ${lastName!}" />
    
    <moqui.basic.LocalizedMessage locale="default" 
        original="GrowerpPasswordResetBody"
        localized="Your reset password has been set to: ${resetPassword}" />
    <moqui.basic.LocalizedMessage locale="th" 
        original="GrowerpPasswordResetBody"
        localized="รหัสผ่านรีเซ็ตของคุณถูกตั้งเป็น: ${resetPassword}" />
    
    <!-- Service Error Messages -->
    <moqui.basic.LocalizedMessage locale="default" 
        original="GrowerpBirdSendNotConfigured"
        localized="BirdSend is not configured. Please check configuration in growerp/100/BirdSendServices100.xml" />
    <moqui.basic.LocalizedMessage locale="th" 
        original="GrowerpBirdSendNotConfigured"
        localized="BirdSend ยังไม่ได้กำหนดค่า กรุณาตรวจสอบการตั้งค่าใน growerp/100/BirdSendServices100.xml" />
    
    <!-- OpenMRS Integration Messages -->
    <moqui.basic.LocalizedMessage locale="default" 
        original="GrowerpOpenMrsInvalidCredentials"
        localized="OpenMRS credentials are not valid" />
    <moqui.basic.LocalizedMessage locale="th" 
        original="GrowerpOpenMrsInvalidCredentials"
        localized="ข้อมูลรับรอง OpenMRS ไม่ถูกต้อง" />
    
    <!-- Add more messages... -->
    
</entity-facade-xml>
```

#### 3.2 Organize by Module

Consider splitting into multiple files for maintainability:

- `GrowerpL10nEmailData.xml` - Email template strings
- `GrowerpL10nServiceData.xml` - Service messages
- `GrowerpL10nPartyData.xml` - Party/user related messages
- `GrowerpL10nCatalogData.xml` - Catalog/product messages
- `GrowerpL10nFinancialData.xml` - Financial document messages
- `GrowerpL10nIntegrationData.xml` - External integration messages

### Phase 4: Update Source Code to Use L10n (Week 4-6)

#### 4.1 Update Email Templates

**Before:**
```xml
<label text="Your reset password has been set to: ${resetPassword}"/>
```

**After:**
```xml
<label text="${ec.l10n.localize('GrowerpPasswordResetBody')}"/>
```

Or with direct resource expansion:
```xml
<label text="${ec.resource.expand(ec.l10n.localize('GrowerpPasswordResetBody'), '')}"/>
```

#### 4.2 Update Service Messages

**Before:**
```xml
<return error="false" 
    message="birdsend not configured see growerp/100/BirdSendServices100.xml" />
```

**After:**
```xml
<return error="false" 
    message="${ec.l10n.localize('GrowerpBirdSendNotConfigured')}" />
```

**Before (in script):**
```groovy
error = "OpenMRS credentials not valid"
```

**After:**
```groovy
error = ec.l10n.localize('GrowerpOpenMrsInvalidCredentials')
```

#### 4.3 Update Data Descriptions

For enumeration descriptions that are user-facing:

**Before:**
```xml
<moqui.basic.Enumeration enumId="RqtConsulation" 
    description="Consultation" enumTypeId="RequestType" />
```

**After:**
```xml
<moqui.basic.Enumeration enumId="RqtConsulation" 
    description="${ec.l10n.localize('GrowerpRequestTypeConsultation')}" 
    enumTypeId="RequestType" />
```

Note: For enumerations, consider using `LocalizedEntityField` instead:

```xml
<moqui.basic.LocalizedEntityField 
    entityName="moqui.basic.Enumeration"
    fieldName="description" 
    pkValue="RqtConsulation" 
    locale="en" 
    localized="Consultation" />
<moqui.basic.LocalizedEntityField 
    entityName="moqui.basic.Enumeration"
    fieldName="description" 
    pkValue="RqtConsulation" 
    locale="th" 
    localized="การให้คำปรึกษา" />
```

### Phase 5: Translation (Week 6-8)

#### 5.1 Initial Target Languages

Based on GrowERP's current user base:
- **English (default)** - Already complete
- **Thai (th)** - Primary additional language
- **Spanish (es)** - For broader international support

#### 5.2 Translation Process

1. **Professional Translation** (Recommended for customer-facing messages)
   - Email templates
   - Error messages shown to end users
   - UI labels

2. **Machine Translation + Review** (For technical messages)
   - Internal error messages
   - Technical descriptions
   - Developer-facing messages

3. **Translation File Format**

Create CSV for translators:
```csv
Key,Context,English (default),Thai (th),Spanish (es)
GrowerpEmailWelcomeGreeting,Welcome email greeting,"Welcome to the GrowERP ${classification} system","ยินดีต้อนรับสู่ระบบ GrowERP ${classification}","Bienvenido al sistema GrowERP ${classification}"
```

#### 5.3 Translation Guidelines

Provide translators with:
- **Context document**: What each message is used for
- **Variable list**: All `${variable}` placeholders and their meanings
- **Tone guidelines**: Formal vs informal, brand voice
- **Character limits**: For UI elements if applicable

### Phase 6: Testing and Validation (Week 8-9)

#### 6.1 Unit Testing

Create service tests for each localized message:

```xml
<!-- Test service in growerp/service/growerp/test/L10nTests.xml -->
<service verb="test" noun="EmailL10n">
    <actions>
        <set field="ec.user.locale" value="th"/>
        <service-call name="growerp.100.PartyServices100.create#User" 
            in-map="[firstName: 'สมชาย', ...]"/>
        <!-- Verify email contains Thai text -->
    </actions>
</service>
```

#### 6.2 Integration Testing

1. **Email Testing**
   - Send emails in different locales
   - Verify variable substitution works
   - Check encoding (UTF-8)

2. **Service Testing**
   - Call services with different user locales
   - Verify error messages are localized
   - Check JSON responses contain localized text

3. **UI Testing** (if applicable)
   - Switch locale in admin interface
   - Verify all strings update

#### 6.3 Validation Checklist

- [ ] All original strings extracted
- [ ] All strings have keys in LocalizedMessage
- [ ] All service code updated to use `ec.l10n.localize()`
- [ ] All email templates updated
- [ ] Variables work correctly post-localization
- [ ] Thai translations complete and reviewed
- [ ] Spanish translations complete and reviewed
- [ ] No hardcoded strings remain
- [ ] Encoding is UTF-8 throughout
- [ ] Fallback to default locale works
- [ ] Database seed data loads correctly

### Phase 7: Documentation and Deployment (Week 9-10)

#### 7.1 Developer Documentation

Create `/docs/GrowERP_Backend_Localization_Guide.md`:

```markdown
# Adding Localized Strings to GrowERP Backend

## Quick Start

1. Add message key to `/growerp/data/GrowerpL10nData.xml`:
   ```xml
   <moqui.basic.LocalizedMessage locale="default" 
       original="GrowerpYourNewMessageKey"
       localized="Your English text here ${variable}" />
   ```

2. Add translations for other locales (th, es, etc.)

3. Use in service:
   ```xml
   <return message="${ec.l10n.localize('GrowerpYourNewMessageKey')}"/>
   ```

4. Use in email template:
   ```xml
   <label text="${ec.l10n.localize('GrowerpYourNewMessageKey')}"/>
   ```

## Best Practices
...
```

#### 7.2 Translation Maintenance Guide

Document the process for:
- Adding new strings
- Updating existing translations
- Adding new languages
- Working with translation vendors

#### 7.3 Deployment Plan

1. **Database Migration**
   ```bash
   cd moqui
   ./gradlew cleandb
   java -jar moqui.war load types=seed,seed-initial,install no-run-es
   ```

2. **Gradual Rollout**
   - Deploy to test environment first
   - Validate all locales
   - Deploy to staging
   - Production deployment

3. **Rollback Plan**
   - Keep backup of original code
   - Document reversion procedure
   - Test rollback scenario

## Technical Implementation Details

### String Extraction Script

Create `extract_l10n_strings.sh`:

```bash
#!/bin/bash
# Extract user-facing strings from GrowERP component

COMPONENT_DIR="moqui/runtime/component/growerp"
OUTPUT_FILE="growerp_l10n_inventory.csv"

echo "Original,Context,File Path,Line,Type" > $OUTPUT_FILE

# Extract from email templates
grep -rn 'text=' $COMPONENT_DIR/screen/email/*.xml | \
    sed 's/.*text="\([^"]*\)".*/\1/' >> $OUTPUT_FILE

# Extract from service messages  
grep -rn 'message=' $COMPONENT_DIR/service/**/*.xml | \
    sed 's/.*message="\([^"]*\)".*/\1/' >> $OUTPUT_FILE

# Extract from CDATA sections (email bodies)
# More complex parsing needed...

echo "Extraction complete: $OUTPUT_FILE"
```

### Locale Detection in Services

Ensure services respect user locale:

```xml
<service verb="send" noun="Email">
    <in-parameters>
        <parameter name="userId"/>
        <parameter name="emailTemplateId"/>
    </in-parameters>
    <actions>
        <!-- Get user's preferred locale -->
        <entity-find-one entity-name="moqui.security.UserAccount" 
            value-field="userAccount">
            <field-map field-name="userId" from="userId"/>
        </entity-find-one>
        
        <!-- Set locale for this execution context -->
        <if condition="userAccount.locale">
            <script>ec.user.setLocale(new Locale(userAccount.locale))</script>
        </if>
        
        <!-- Now all ec.l10n.localize() calls use user's locale -->
        <service-call name="org.moqui.impl.EmailServices.send#EmailTemplate"
            in-map="[emailTemplateId: emailTemplateId, ...]"/>
    </actions>
</service>
```

### Component.xml Configuration

Update `/growerp/component.xml` to load l10n data:

```xml
<component name="growerp" version="1.10.3+0">
    <depends-on name="moqui-fop" />
    <depends-on name="mantle-udm" />
    <depends-on name="mantle-usl" />
</component>
```

Ensure data files are in proper type category:
- `seed-initial`: Core translations needed for system boot
- `seed`: Standard translations
- `install`: Optional/demo translations

## Priority Categorization

### High Priority (Must have for initial release)
1. Email templates (Welcome, Password Reset)
2. User-facing error messages
3. Payment/order related messages
4. Authentication/authorization messages

### Medium Priority (Should have)
1. Integration error messages (OpenMRS, BirdSend, etc.)
2. Export/Import messages
3. Financial document messages
4. Enumeration descriptions shown to users

### Low Priority (Nice to have)
1. Technical/debug messages
2. Internal service messages
3. Demo data descriptions
4. Developer-facing messages

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Variable expansion breaks after localization | High | Thorough testing of all variables, automated tests |
| Translation quality issues | Medium | Professional review for customer-facing text |
| Performance impact of l10n lookups | Low | Moqui caches LocalizedMessage entities |
| Missing translations causing errors | Medium | Always provide 'default' locale fallback |
| Character encoding issues (Thai, etc.) | Medium | Ensure UTF-8 throughout, test thoroughly |
| Long translations breaking UI layouts | Low | Provide character limits to translators |

## Success Metrics

- [ ] 100% of user-facing strings extracted
- [ ] 100% of extracted strings have 'default' locale entries
- [ ] 90%+ Thai translation coverage
- [ ] 80%+ Spanish translation coverage
- [ ] Zero hardcoded user-facing English strings in code
- [ ] All integration tests passing
- [ ] Email templates render correctly in all locales
- [ ] Service error messages localized correctly

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| 1. Extraction & Cataloging | 2 weeks | Complete string inventory CSV |
| 2. Standardization | 1 week | Message keys defined |
| 3. L10n Data Files | 1 week | GrowerpL10nData.xml created |
| 4. Code Updates | 2 weeks | All code using ec.l10n.localize() |
| 5. Translation | 2 weeks | Thai & Spanish translations |
| 6. Testing | 1 week | All tests passing |
| 7. Documentation & Deploy | 1 week | Docs complete, deployed |
| **Total** | **10 weeks** | Fully localized backend |

## Next Steps

1. **Immediate (This Week)**
   - Review and approve this plan
   - Set up translation workflow
   - Create string extraction script

2. **Short Term (Next 2 Weeks)**
   - Run extraction script
   - Create and review string inventory
   - Begin creating message keys

3. **Medium Term (Weeks 3-6)**
   - Create l10n data files
   - Update service code
   - Begin translations

4. **Long Term (Weeks 7-10)**
   - Complete translations
   - Testing and validation
   - Documentation and deployment

## Resources Needed

- **Development**: 1 senior developer (full-time, 10 weeks)
- **Translation**: Thai translator (2-3 weeks)
- **Translation**: Spanish translator (2-3 weeks)
- **QA**: 1 QA engineer (1 week for testing)
- **Documentation**: Technical writer (1 week)

## References

- Moqui L10n Documentation: https://www.moqui.org/m/docs/framework/Localization
- GrowERP Documentation: `/docs/README.md`
- Moqui LocalizedMessage Entity: Framework entity definition
- Existing Examples: `/moqui/runtime/component/mantle-usl/data/OrderInstallData.xml`

---

**Document Version**: 1.0  
**Created**: October 5, 2025  
**Author**: AI Coding Agent  
**Status**: Draft for Review
