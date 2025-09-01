# GrowERP - Open Source Modular ERP Platform

[![License: CC0-1.0](https://img.shields.io/badge/License-CC0%201.0-lightgrey.svg)](http://creativecommons.org/publicdomain/zero/1.0/)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.1-blue.svg)](https://flutter.dev/)
[![Moqui](https://img.shields.io/badge/Moqui-Framework-green.svg)](https://www.moqui.org/)

GrowERP is an open-source, multi-platform ERP application built with a modular architecture that allows for unprecedented extensibility and customization. Whether you're a small business or an enterprise, GrowERP adapts to your needs through its flexible building block system.

## 🚀 Quick Start

### Try GrowERP Now

**Production Applications:** Require credit card with 2 weeks trial
- **Admin App with complete functionality**: [Linux](https://snapcraft.io/growerp-admin) | [Windows](https://github.com/growerp/growerp/releases/download/1.9.15/growerpSetup.exe) | [MacOs](https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755) | [Web](https://admin.growerp.com) | [Android](https://play.google.com/store/apps/details?id=org.growerp.admin) | [iOS](https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755)

**Applications under test:**
- **Admin next version**: [admin.growerp.org](https://admin.growerp.org)
- **Hotel**: [hotel.growerp.org](https://hotel.growerp.org)
- **Freelance**: [freelance.growerp.org](https://freelance.growerp.org)

*Create a new company, select demo data, and explore! Login credentials will be sent to your email.*

### Install Locally (Easy Way)

```bash
dart pub global activate growerp
growerp install
```

<a href="https://studio.firebase.google.com/import?url=https%3A%2F%2Fgithub.com%2Fgrowerp%2Fgrowerp">
  <img height="32" alt="Open in Firebase Studio" src="https://cdn.firebasestudio.dev/btn/open_blue_32.svg">
</a>

## 📚 Documentation

### 🏗️ Extensibility & Development
- **[📖 Extensibility Overview](./docs/README.md)** - Complete guide to GrowERP's modular architecture
- **[🧩 Building Blocks Guide](./docs/Building_Blocks_Development_Guide.md)** - Create Flutter packages (growerp_* packages)
- **[⚙️ Backend Components Guide](./docs/Backend_Components_Development_Guide.md)** - Develop Moqui components
- **[📋 Management Summary](./docs/Management_Summary_Open_Source_Extensibility.md)** - Strategic overview for decision makers

### 🤝 Contributing
- **[🔧 Contributing Guide](./CONTRIBUTING.md)** - How to contribute to GrowERP
- **[📜 Code of Conduct](./CODE_OF_CONDUCT.md)** - Community guidelines
- **[📄 License](./LICENSE)** - CC0 1.0 Universal (Public Domain)

### 📖 Additional Resources
- **[User Documentation](https://www.growerp.com)** - End-user guides and tutorials
- **[Technical Documentation](./GrowERPObs/)** - Detailed technical documentation

## 🏛️ Architecture Overview

GrowERP uses a modular architecture that promotes reusability and extensibility:

```
┌─────────────────────────────────────────────────────────────┐
│                    Applications Layer                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐ │
│  │ Admin App   │ │ Hotel App   │ │Freelance App│ │Custom...│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  Building Blocks Layer                      │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────┐ │
│ │growerp_core  │ │growerp_catalog│ │growerp_order │ │ ...  │ │
│ │growerp_models│ │growerp_inventory│ │_accounting  │ │      │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ └──────┘ │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Backend Layer                            │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────┐ │
│ │GrowERP Comp. │ │Custom Comp.  │ │Mantle UDM    │ │Moqui │ │
│ │              │ │              │ │Mantle USL    │ │Frame │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ └──────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 🧩 Building Blocks (Frontend)
- **growerp_core** - Foundation templates and UI components
- **growerp_models** - Data models and API clients
- **growerp_catalog** - Product and category management
- **growerp_inventory** - Warehouse and stock management
- **growerp_order_accounting** - Orders, invoices, and accounting
- **growerp_user_company** - User and company management
- **growerp_marketing** - Marketing campaigns and analytics
- **growerp_website** - Website content management
- **growerp_activity** - Task and activity tracking
- **growerp_chat** - Real-time communication

### ⚙️ Backend Components
- **Moqui Framework** - Enterprise-grade backend framework
- **REST APIs** - Automatic JSON serialization and authentication
- **Entity Engine** - ORM with automatic CRUD operations
- **Service Engine** - Business logic with transactions
- **Security** - Role-based access control

## 🌟 Key Features

### ✨ For Businesses
- **Multi-platform** - Web, Android, iOS from single codebase
- **Modular Design** - Use only what you need
- **Industry-Specific** - Pre-built applications for different sectors
- **Scalable** - From small business to enterprise
- **Open Source** - No licensing fees, full control

### 🛠️ For Developers
- **Extensible Architecture** - Create custom building blocks and components
- **Modern Tech Stack** - Flutter frontend, Moqui backend
- **Comprehensive Documentation** - Detailed guides for all aspects
- **Active Community** - Collaborative development environment
- **Best Practices** - Established patterns and conventions

### 🏢 For Organizations
- **Cost Effective** - 60% reduction in Total Cost of Ownership
- **Rapid Development** - 50% faster application development
- **Customizable** - Adapt to specific business requirements
- **Future-Proof** - Modular architecture supports evolution
- **Community-Driven** - Benefit from collective innovation

## 🚀 Getting Started

### Prerequisites

- **Java JDK 11** - [Download](https://www.oracle.com/th/java/technologies/javase/jdk11-archive-downloads.html)
- **Java JDK 17** - [Download](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) (for Gradle 8+)
- **Flutter stable** - [Install](https://flutter.dev/)
- **Chrome Browser** - [Download](https://www.google.com/chrome/)
- **Git** - [Download](https://git-scm.com/downloads)
- **Android Studio** - [Download](https://developer.android.com/studio) (optional)
- **VS Code** - [Download](https://code.visualstudio.com/) (optional)

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/growerp/growerp
   cd growerp
   ```

2. **Start the backend** (in separate terminal):
   ```bash
   cd moqui
   # First time only
   ./gradlew build
   java -jar moqui.war load types=seed,seed-initial,install no-run-es
   
   # Regular startup
   java -jar moqui.war no-run-es
   ```

3. **Run the Flutter application:**
   ```bash
   cd flutter/packages/admin
   # First time only
   dart pub global activate melos 3.4.0
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   melos clean
   melos bootstrap
   melos l10n --no-select
   melos build --no-select
   
   # Regular startup
   flutter run
   ```

4. **Access the backend admin:**
   - URL: http://localhost:8080/vapps
   - User: SystemSupport
   - Password: moqui

### Docker Installation

For Docker-based installation, see the [Docker README](./docker/README.md).

## 🎯 Use Cases & Applications

### 🏢 Admin Application
Complete ERP solution with:
- Product catalog management
- Inventory tracking
- Order processing
- Accounting and invoicing
- User and company management
- Website content management
- Marketing campaigns

### 🏨 Hotel Application
Specialized for hospitality:
- Room management
- Reservation system
- Guest services
- Housekeeping
- Billing and accounting

### 💼 Freelance Application
Project management focused:
- Client management
- Time tracking
- Project organization
- Invoicing
- Activity monitoring

### 🔧 Custom Applications
Build your own using:
- Existing building blocks
- Custom components
- Industry-specific workflows
- Tailored user interfaces

## 🤝 Contributing

We welcome contributions from developers of all skill levels! Here's how you can help:

### 🎯 Contribution Areas
- **🐛 Bug Fixes** - Report and fix issues
- **✨ New Features** - Building blocks, backend components, integrations
- **📚 Documentation** - Improve guides, add examples, translations
- **🧪 Testing** - Unit tests, integration tests, quality assurance
- **🎨 UI/UX** - Design improvements, accessibility, themes

### 🚀 Getting Started
1. Read our [Contributing Guide](./CONTRIBUTING.md)
2. Check the [Extensibility Documentation](./docs/README.md)
3. Follow our [Code of Conduct](./CODE_OF_CONDUCT.md)
4. Join the community discussions

### 📈 High-Priority Areas
- Industry-specific building blocks (healthcare, education, manufacturing)
- Integration modules (payment, shipping, analytics)
- Localization and internationalization
- Performance and scalability improvements

## 📱 Screenshots

### Admin Application

<div align="center">

#### Mobile Screenshots
| Main Menu | Products | Website |
|-----------|----------|---------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_main_menu.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_catalog_products.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_website.png" width="200"> |

| Accounting | Ledger | Company |
|------------|--------|---------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_accounting.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_ledger.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/phoneScreenshots/Screenshot_company.png" width="200"> |

#### Web/Tablet Screenshots
| Main Menu |
|-----------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_main_menu.png" width="600"> |

| Company Management |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_company.png" width="600"> |

| Website Management |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_website.png" width="600"> |

| Order Management |
|------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_orders.png" width="600"> |

| Accounting |
|------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_accounting.png" width="600"> |

| Ledger |
|--------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_ledger.png" width="600"> |

| Product Catalog |
|-----------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/admin/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/Screenshot_products.png" width="600"> |

</div>

### Hotel Application

<div align="center">

#### Mobile Screenshots
| Daily View | Weekly Menu | Rooms |
|------------|-------------|-------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/main-day.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/main-week-menu.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/rooms.png" width="200"> |

| Reservations | Accounting | Ledger |
|--------------|------------|--------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/reservations.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/accounting.png" width="200"> | <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/phoneScreenshots/ledger.png" width="200"> |

#### Web/Tablet Screenshots
| Daily View |
|------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/main-day.png" width="600"> |

| Weekly View |
|-------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/main-week.png" width="600"> |

| Room Management |
|-----------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/rooms.png" width="600"> |

| Reservation System |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/reservations.png" width="600"> |

| Accounting |
|------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/accounting.png" width="600"> |

| Financial Ledger |
|------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/flutter/packages/hotel/android/fastlane/metadata/android/en-US/images/tenInchScreenshots/ledger.png" width="600"> |

</div>

### Generated Business Website

<div align="center">

| E-commerce Website |
|-------------------|
| <img src="https://raw.githubusercontent.com/growerp/growerp/master/GrowERPObs/media/website.png" width="600"> |

</div>

## 🌐 Community & Support

### 📞 Contact & Support
- **Email**: support@growerp.com
- **Website**: [www.growerp.com](https://www.growerp.com)
- **GitHub Issues**: [Report bugs and request features](https://github.com/growerp/growerp/issues)
- **GitHub Discussions**: [Community discussions](https://github.com/growerp/growerp/discussions)

### 🤝 Community
- **Contributors**: Join our growing community of developers
- **Documentation**: Help improve and translate documentation
- **Testing**: Test new features and report issues
- **Mentorship**: Learn from experienced contributors

### 📈 Project Status
- **License**: CC0 1.0 Universal (Public Domain)
- **Status**: Active development
- **Stability**: Production ready
- **Community**: Growing open source ecosystem

## 🎯 Roadmap

### 🔮 Upcoming Features
- Enhanced mobile responsiveness
- Advanced reporting and analytics
- Additional industry-specific modules
- Improved internationalization
- Performance optimizations

### 🚀 Long-term Vision
- Comprehensive ecosystem of building blocks
- Industry-leading extensibility platform
- Global community of contributors
- Enterprise-grade scalability and performance

---

<div align="center">

**🌟 Star this repository if you find GrowERP useful!**

**🤝 Join our community and help shape the future of open-source ERP!**

[⭐ Star](https://github.com/growerp/growerp/stargazers) • [🍴 Fork](https://github.com/growerp/growerp/fork) • [📝 Contribute](./CONTRIBUTING.md) • [💬 Discuss](https://github.com/growerp/growerp/discussions)

</div>
