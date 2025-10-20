# GrowERP Documentation Index

This directory contains comprehensive documentation for extending and developing with GrowERP. GrowERP is designed with extensibility at its core, allowing developers to create custom applications and extend functionality through well-defined building blocks and configuration systems.

## 📖 Quick Navigation

### 🚀 Getting Started

- **[GrowERP Extensibility Guide](./GrowERP_Extensibility_Guide.md)** - Start here for complete overview
- **[Building Blocks Development Guide](./Building_Blocks_Development_Guide.md)** - Create Flutter packages
- **[Backend Components Development Guide](./Backend_Components_Development_Guide.md)** - Develop Moqui components

### 🎨 Design & Patterns

- **[GrowERP Design Patterns](./GrowERP_Design_Patterns.md)** - Comprehensive design patterns
- **[GrowERP Code Templates](./GrowERP_Code_Templates.md)** - Ready-to-use templates
- **[BLoC Message Translation - Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md)** ⭐ **NEW!** Complete guide for direct l10n keys pattern

### 🔧 Technical Guides

- **[Data Model Basic Guide](./basic_explanation_of_the_frontend_REST_Backend_data_models.md)** - Frontend/Backend data models
- **[Invoice Scan Documentation](./Invoice_Scan_Documentation.md)** - AI-powered invoice processing ⭐ **NEW!**
- **[Timezone Management Guide](./GrowERP_Timezone_Management_Guide.md)** - Handle timezone differences
- **[Timezone Quick Reference](./GrowERP_Timezone_Quick_Reference.md)** - Quick timezone guide
- **[Stripe Payment Processing](./Stripe_Payment_Processing_Documentation.md)** - Payment integration
- **[WebSocket Notification System](./WebSocket_Notification_System.md)** - Real-time notifications
- **[Backend URL Selection System](./Backend_URL_Selection_System_Documentation.md)** - Backend configuration

### 🌍 Internationalization

- **[Buddhist Era Documentation](./Buddhist_Era_README.md)** - Buddhist calendar support
- **[Buddhist Era Quick Reference](./Buddhist_Era_Quick_Reference.md)** - Quick reference
- **[Buddhist Era Testing Checklist](./Buddhist_Era_Testing_Checklist.md)** - Testing guide
- **[BLoC Message Translation - Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md)** ⭐ **NEW!** Multi-language BLoC messages with direct l10n keys

### 🚀 Release & Operations

- **[Version Management and Release Process](./GrowERP_Version_Management_and_Release_Process.md)** - Release strategy
- **[Snap Linux Distribution Guide](./snap_linux_distribution.md)** - Package for Linux
- **[GrowERP Timeout Fix Documentation](./GrowERP_Timeout_Fix_Documentation.md)** - Timeout handling

### 🤖 AI Integration

- **[GrowERP AI Development Instructions](./GrowERP_AI_Instructions.md)** - AI-assisted development
- **[Model Context Protocol (MCP) Server](../moqui/runtime/component/growerp/docs/README.md)** - AI integration system
- **[Invoice Scan Documentation](./Invoice_Scan_Documentation.md)** - AI-powered invoice processing ⭐ **NEW FEATURE!**

### 📊 Business Processes & Party Model

- **[B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md)** ⭐ **NEW!** - Comprehensive guide to B2C/B2B support, person/company relationships, and accounting
- **[Leads Upload Process](./leads_upload_process.md)** - Import lead data
- **[Leads Download Process](./leads_download_process.md)** - Export lead data
- **[Moqui Subscription Function](./Moqui_Subscription_Function.md)** - Subscription management

### 📚 Examples & References

- **[Management Summary: Open Source Extensibility](./Management_Summary_Open_Source_Extensibility.md)** - Executive overview
- **[Examples](./examples/)** - Code examples and use cases

## 🔥 What's New

### B2C and B2B Party Model Documentation (Latest)

Comprehensive guide to GrowERP's flexible party model that elegantly handles both B2C (Business-to-Consumer) and B2B (Business-to-Business) relationships:

- **B2C Support** - Standalone persons/individuals with direct transactions
- **B2B Support** - Companies with employees as representatives
- **Smart UI** - Shows UserDialog for standalone persons, CompanyDialog for persons representing companies
- **Accounting** - All records posted to companies (not employees) in B2B scenarios
- **Real-world use cases** - E-commerce, SaaS, Manufacturing, Hybrid platforms

**Quick Start:**
1. Read: [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **Latest documentation**
2. Understand the core rule: When a person has a company, accounting goes to the company
3. See implementation in `growerp_user_company` package

**Key Decision Matrix:**
| Scenario | Display | Accounting Posts To |
|----------|---------|-------------------|
| Person with no company | UserDialog | Individual person |
| Person with company | CompanyDialog | Company (not individual) |
| Pure company | CompanyDialog | Company |

---

### BLoC Message Translation with Direct L10n Keys (Current Pattern)

A streamlined pattern for handling multi-language messages from BLoCs using direct l10n keys:

- **Direct l10n keys** - No MessageKeys constants needed
- **Simple parameter passing** - Using colon delimiter (e.g., `'userAddSuccess:John'`)
- **Type-safe** - Compile-time checks via generated l10n methods
- **Easy to debug** - Messages are readable strings, not constants
- **Complete examples** - Implemented across all 8 GrowERP packages

**Quick Start:**
1. Read: [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **Complete guide**
2. See live examples in all `growerp_*` packages (e.g., `flutter/packages/growerp_user_company/`)

**Pattern at a glance:**
```dart
// In BLoC - emit direct l10n key with parameter
message = 'userAddSuccess:${user.name}';

// In Translator - parse and translate
final parts = messageKey.split(':');
final key = parts[0];  // 'userAddSuccess'
final param = parts[1]; // user name
return l10n.userAddSuccess(param);

// In UI - display translated message (no changes needed)
BlocListener<UserBloc, UserState>(
  listener: (context, state) {
    if (state.message != null) {
      final translated = translateUserBlocMessage(l10n, state.message!);
      HelperFunctions.showMessage(context, translated, Colors.green);
    }
  },
  // ...
)
```

## 📋 Documentation by Role

### For Frontend Developers

1. [Building Blocks Development Guide](./Building_Blocks_Development_Guide.md)
2. [GrowERP Design Patterns](./GrowERP_Design_Patterns.md)
3. [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **NEW!**
4. [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) ⭐ **NEW FEATURE!**
5. [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **New Pattern!**
6. [Timezone Management Guide](./GrowERP_Timezone_Management_Guide.md)

### For Backend Developers

1. [Backend Components Development Guide](./Backend_Components_Development_Guide.md)
2. [Data Model Basic Guide](./basic_explanation_of_the_frontend_REST_Backend_data_models.md)
3. [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **NEW!**
4. [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) ⭐ **NEW FEATURE!**
5. [Moqui Subscription Function](./Moqui_Subscription_Function.md)

### For Full-Stack Developers

1. [GrowERP Extensibility Guide](./GrowERP_Extensibility_Guide.md)
2. [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **NEW!**
3. [GrowERP Code Templates](./GrowERP_Code_Templates.md)
4. [WebSocket Notification System](./WebSocket_Notification_System.md)

### For DevOps/Release Managers

1. [Version Management and Release Process](./GrowERP_Version_Management_and_Release_Process.md)
2. [Snap Linux Distribution Guide](./snap_linux_distribution.md)

### For AI/ML Developers

1. [GrowERP AI Development Instructions](./GrowERP_AI_Instructions.md)
2. [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) ⭐ **NEW FEATURE!**
3. [Model Context Protocol (MCP) Server](../moqui/runtime/component/growerp/docs/README.md)

### For Localization/Translation Teams

1. [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **Complete guide**
2. [Buddhist Era Documentation](./Buddhist_Era_README.md)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│            Application Layer (Apps)                      │
│  Admin • Hotel • Freelance • Health • Custom Apps      │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│         Building Blocks Layer (Packages)                 │
│  growerp_core • growerp_models • growerp_catalog         │
│  growerp_inventory • growerp_order_accounting            │
│  growerp_user_company • growerp_marketing • ...          │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│           Backend Layer (Moqui)                          │
│  GrowERP Component • Custom Components                   │
│  Mantle UDM • Mantle USL • Moqui Framework              │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Common Tasks

### Add a New Feature

1. Design: Read [Design Patterns](./GrowERP_Design_Patterns.md)
2. Frontend: Follow [Building Blocks Guide](./Building_Blocks_Development_Guide.md)
3. Backend: Follow [Backend Components Guide](./Backend_Components_Development_Guide.md)
4. Test: Use [Code Templates](./GrowERP_Code_Templates.md)

### Internationalize Your Feature

1. Add translations to `.arb` files
2. Follow [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **New pattern!**
3. Handle timezones with [Timezone Guide](./GrowERP_Timezone_Management_Guide.md)
4. Support Buddhist Era with [Buddhist Era Guide](./Buddhist_Era_README.md)

### Release Your Changes

1. Follow [Version Management](./GrowERP_Version_Management_and_Release_Process.md)
2. Run tests
3. Update documentation
4. Create release

## 🛠️ Development Tools

### Code Generation

```bash
# Generate localizations
melos l10n --no-select

# Run all tests
melos test

# Clean and bootstrap
melos clean && melos bootstrap

# Build all packages
melos build
```

### Quick References

- [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **New pattern!**
- [Timezone Quick Reference](./GrowERP_Timezone_Quick_Reference.md)
- [Buddhist Era Quick Reference](./Buddhist_Era_Quick_Reference.md)

## 📞 Getting Help

### Resources

- [GrowERP GitHub Repository](https://github.com/growerp/growerp)
- [GrowERP Website](https://www.growerp.com)
- [Moqui Framework Documentation](https://www.moqui.org/docs)
- [Flutter Documentation](https://flutter.dev/docs)

### Community

- GitHub Issues for bug reports
- GitHub Discussions for questions
- Contributing guidelines in repository

## 🤝 Contributing

Contributions are welcome! Please:

1. Read the contributing guidelines
2. Follow established patterns (especially the [BLoC Message Translation pattern](./QUICK_REFERENCE_BLOC_MESSAGES.md))
3. Write tests
4. Update documentation
5. Submit pull requests

## 📄 License

GrowERP is released under the CC0 1.0 Universal license.

---

**Last Updated:** October 2025  
**Maintained by:** GrowERP Community

---

## 📝 Documentation Standards

All documentation in this directory follows these standards:

- **Markdown format** for consistency
- **Clear headings** for easy navigation
- **Code examples** for practical understanding
- **Diagrams** where appropriate
- **Cross-references** to related documents
- **Version history** where relevant

For questions or improvements to this documentation, please create an issue or submit a pull request.
