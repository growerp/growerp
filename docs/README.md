````markdown
# GrowERP Documentation Index

This directory contains comprehensive documentation for extending and developing with GrowERP. GrowERP is designed with extensibility at its core, allowing developers to create custom applications and extend functionality through well-defined building blocks and configuration systems.

**Last Updated:** January 5, 2026  
**Status:** ✅ COMPLETE & PRODUCTION-READY  
**Total Documentation:** 40+ Documents | 9,000+ Lines

## 📖 Quick Navigation

### ⭐ Phase 12 - Assessment Landing Page Implementation (LATEST)

- **[Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md)** ⭐ **PHASE 12** - Complete technical guide for FTL landing page + Flutter app integration (30 min read)
- **[Session Summary - Architecture Complete](./SESSION_SUMMARY_ARCHITECTURE_COMPLETE.md)** - This session's accomplishments (20 min read)
- **[Start Here - Visual Overview](./00_START_HERE.md)** - Project status dashboard (10 min read)
- **[GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md)** - Package design & strategy (45 min read)

**Phase 12 Highlights:**
- ✅ Assessment Landing Page fully documented
- ✅ FTL landing page + Flutter app integration complete
- ✅ Package renamed to `assessment` for clarity
- ✅ All deployment procedures updated and verified
- ✅ MIME type configuration for WASM assets documented
- ✅ Stack overflow bug fixes and BLoC initialization resolved

---

### 🚀 Getting Started with GrowERP

- **[GrowERP Extensibility Guide](./GrowERP_Extensibility_Guide.md)** - Start here for complete overview
- **[Building Blocks Development Guide](./Building_Blocks_Development_Guide.md)** - Create Flutter packages
- **[Backend Components Development Guide](./Backend_Components_Development_Guide.md)** - Develop Moqui components

### 📚 Phase 12 Specification Documents

- **[Architecture Update Summary](./ARCHITECTURE_UPDATE_SUMMARY.md)** (429 lines) - Session changes & migration path

---

### 🎨 Design & Patterns

- **[GrowERP Design Patterns](./GrowERP_Design_Patterns.md)** - Comprehensive design patterns
- **[GrowERP Code Templates](./GrowERP_Code_Templates.md)** - Ready-to-use templates
- **[BLoC Message Translation - Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md)** ⭐ **NEW!** Complete guide for direct l10n keys pattern

### 🔧 Technical Guides

- **[Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md)** ⭐ **NEW!** - Complete guide to dynamic menus and widget registry patterns
- **[Data Model Basic Guide](./basic_explanation_of_the_frontend_REST_Backend_data_models.md)** - Frontend/Backend data models
- **[Flutter-Moqui REST Backend Interface](./Flutter_Moqui_REST_Backend_Interface.md)** - Complete REST API communication guide with code examples
- **[Integration Test Guide](./Integration_Test_Guide.md)** ⭐ **NEW!** - Comprehensive guide to GrowERP's integration testing framework
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

## 🔥 What's New (January 2026)

### Modern UI & Theme System ⭐ **NEW!**

GrowERP now features an enhanced UI system with:

- **Flexible Color Theming** - Built with `flex_color_scheme` for beautiful, consistent themes
- **Trial Welcome Flow** - Streamlined onboarding with improved trial welcome dialogs (2-week free trial, no credit card required)
- **Tenant Setup Dialog** - Redesigned to match the modern login screen aesthetic
- **GroupingDecorator Widget** - Theme-aware grouped input fields with consistent OutlineInputBorder styling
- **Color Variations** - Enhanced navigation rail/drawer gradients and zebra striping in data tables

**Quick Start:**
1. Theme configuration via `flex_color_scheme` (see `growerp_core/lib/src/styles/`)
2. New `trialWelcome` flow replaces legacy `evaluationWelcome`
3. Use `GroupingDecorator` instead of `InputDecorator` for grouped fields

### Dynamic Navigation with go_router ⭐ **NEW!**

Rebuilt navigation system using `go_router` for:

- **Dynamic Menu Configuration** - Backend-stored, user-customizable menus
- **Static/Dynamic Router Patterns** - Choose based on app complexity
- **Widget Registry** - AI-ready widget discovery with metadata
- **See:** [Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md)

### B2C and B2B Party Model Documentation

Comprehensive guide to GrowERP's flexible party model:

- **B2C Support** - Standalone persons/individuals with direct transactions
- **B2B Support** - Companies with employees as representatives
- **Smart UI** - Shows UserDialog for standalone persons, CompanyDialog for persons representing companies
- **Accounting** - All records posted to companies (not employees) in B2B scenarios

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

## 📋 Reading Paths by Role

### 👔 Project Managers / Stakeholders
**Time:** 40 minutes
1. [Start Here - Visual Overview](./00_START_HERE.md) (10 min)
2. [Architecture Update Summary](./ARCHITECTURE_UPDATE_SUMMARY.md) (15 min)
3. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) Overview (15 min)

### 🏗️ Architects / Tech Leads
**Time:** 100 minutes
1. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) (30 min) ⭐ **Phase 12**
2. [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) (45 min)
3. [Architecture Update Summary](./ARCHITECTURE_UPDATE_SUMMARY.md) (25 min)

### 💻 Frontend Developers
**Time:** 80 minutes
1. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) (30 min) ⭐ **Phase 12**
2. [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) (45 min)
3. [Building Blocks Development Guide](./Building_Blocks_Development_Guide.md)
4. [GrowERP Design Patterns](./GrowERP_Design_Patterns.md)
5. [Integration Test Guide](./Integration_Test_Guide.md) ⭐ **NEW!**
6. [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **NEW!**
7. [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) ⭐ **NEW!**
8. [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **New Pattern!**
9. [Timezone Management Guide](./GrowERP_Timezone_Management_Guide.md)

### ⚙️ Backend Developers
**Time:** 80 minutes
1. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) (30 min) ⭐ **Phase 12**
2. [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) (45 min)
3. [Backend Components Development Guide](./Backend_Components_Development_Guide.md)
4. [Data Model Basic Guide](./basic_explanation_of_the_frontend_REST_Backend_data_models.md)
5. [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **NEW!**
6. [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) ⭐ **NEW!**
7. [Moqui Subscription Function](./Moqui_Subscription_Function.md)

### 🔧 DevOps / Infrastructure
**Time:** 45 minutes
1. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) (30 min) ⭐ **Phase 12 - Deployment & MIME types**
2. [Version Management and Release Process](./GrowERP_Version_Management_and_Release_Process.md) (15 min)

### 🎨 Admin / UI Developers
**Time:** 60 minutes
1. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) (30 min) ⭐ **Phase 12**
2. [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) (30 min)

### ✅ QA / Testers
**Time:** 60 minutes
1. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) Testing Checklist (30 min) ⭐ **Phase 12**
2. [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) (30 min)
3. [Integration Test Guide](./Integration_Test_Guide.md) ⭐ **NEW!** - Complete testing framework guide

### 🤖 AI/ML Developers
1. [GrowERP AI Development Instructions](./GrowERP_AI_Instructions.md)
2. [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) ⭐ **NEW!**
3. [Model Context Protocol (MCP) Server](../moqui/runtime/component/growerp/docs/README.md)

### 🌐 Localization/Translation Teams
1. [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) ⭐ **Complete guide**
2. [Buddhist Era Documentation](./Buddhist_Era_README.md)
3. [Buddhist Era Quick Reference](./Buddhist_Era_Quick_Reference.md)

### 🚀 Full-Stack Developers
1. [GrowERP Extensibility Guide](./GrowERP_Extensibility_Guide.md)
2. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) ⭐ **Phase 12**
3. [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) ⭐ **NEW!**
4. [GrowERP Code Templates](./GrowERP_Code_Templates.md)
5. [WebSocket Notification System](./WebSocket_Notification_System.md)

### 📚 New Team Members (Onboarding)
**Time:** 120 minutes
1. [Start Here - Visual Overview](./00_START_HERE.md) (10 min)
2. [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) (30 min) ⭐ **Phase 12**
3. [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) (45 min)
4. [GrowERP Extensibility Guide](./GrowERP_Extensibility_Guide.md) (20 min)
5. Q&A with team (15 min)

## 🏗️ Architecture Overview

### GrowERP Layered Architecture

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

## 🎯 Finding Specific Information

| Need to find | Document | Section |
|---|---|---|
| **Dynamic menu system** | [Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md) | Complete guide |
| **Widget registry pattern** | [Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md) | Widget Registry |
| **Static vs dynamic router** | [Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md) | When to Use Each Pattern |
| **Example app menu setup** | [Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md) | Static Router |
| **Integration test framework** | [Integration Test Guide](./Integration_Test_Guide.md) | Complete guide |
| **Landing page implementation (Phase 12)** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | Complete guide |
| **FTL + Flutter integration** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | Architecture, Runtime Behavior |
| **Assessment app deployment** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | Build & Deployment |
| **Package rename details** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | Phase 12 Changes Summary |
| **Lead capture flow** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | User Flow |
| **MIME type configuration** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | MIME Type Configuration |
| **Phase 12 troubleshooting** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | Troubleshooting table |
| **Architecture overview** | [GrowERP Assessment & Landing Page Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) | All sections |
| **Testing strategy** | [Assessment Landing Page Explanation](./Assessment_Landing_Page_Explanation.md) | Testing Checklist |
| **How to extend GrowERP** | [GrowERP Extensibility Guide](./GrowERP_Extensibility_Guide.md) | All sections |
| **BLoC message pattern** | [BLoC Message Translation Quick Reference](./QUICK_REFERENCE_BLOC_MESSAGES.md) | Complete guide |
| **B2C/B2B model** | [B2C and B2B Party Model Documentation](./B2C_B2B_Party_Model_Documentation.md) | Complete guide |
| **Buddhist Era support** | [Buddhist Era Documentation](./Buddhist_Era_README.md) | Complete guide |
| **Invoice scanning** | [Invoice Scan Documentation](./Invoice_Scan_Documentation.md) | Complete guide |
| **Payment integration** | [Stripe Payment Processing Documentation](./Stripe_Payment_Processing_Documentation.md) | Complete guide |
| **Real-time notifications** | [WebSocket Notification System](./WebSocket_Notification_System.md) | Complete guide |
| **Timezone handling** | [Timezone Management Guide](./GrowERP_Timezone_Management_Guide.md) | Complete guide |
| **Release process** | [Version Management and Release Process](./GrowERP_Version_Management_and_Release_Process.md) | Complete guide |
| **AI development** | [GrowERP AI Development Instructions](./GrowERP_AI_Instructions.md) | Complete guide |

---

## 🚀 Quick Start by Role

**👔 Manager?** → [Start Here](./00_START_HERE.md) + [Architecture Summary](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md)

**🏗️ Architect?** → [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) + [Architecture](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md) + [Extensibility Guide](./GrowERP_Extensibility_Guide.md)

**💻 Frontend Dev?** → [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) + [Building Blocks Guide](./Building_Blocks_Development_Guide.md) + [Design Patterns](./GrowERP_Design_Patterns.md)

**⚙️ Backend Dev?** → [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) + [Backend Components Guide](./Backend_Components_Development_Guide.md) + [Data Models](./basic_explanation_of_the_frontend_REST_Backend_data_models.md)

**🔧 DevOps?** → [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) (Deployment section) + [Version Management](./GrowERP_Version_Management_and_Release_Process.md)

**🎨 Admin Dev?** → [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) + [Architecture Guide](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md)

**✅ QA?** → [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) (Testing Checklist) + [Architecture Guide](./GROWERP_ASSESSMENT_AND_LANDING_PAGE_ARCHITECTURE.md)

**📚 New Person?** → Start with [Start Here](./00_START_HERE.md), then [Assessment Landing Page](./Assessment_Landing_Page_Explanation.md) for Phase 12 overview

---

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

**Last Updated:** January 5, 2026  
**Maintained by:** GrowERP Community  
**Status:** ✅ COMPLETE & PRODUCTION-READY

**Recent Updates Summary:**
- ✅ Modern UI with flex_color_scheme theming
- ✅ go_router navigation with dynamic menus
- ✅ Trial welcome flow (replacing evaluation welcome)
- ✅ Enhanced tenant setup and registration dialogs
- ✅ GroupingDecorator for consistent form styling
- ✅ Integration test improvements with animation handling

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

---

**Last Updated:** January 5, 2026  
**Maintained by:** GrowERP Community
