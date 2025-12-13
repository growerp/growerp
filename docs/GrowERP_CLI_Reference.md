# GrowERP CLI Command Reference

**Version:** 1.10.5  
**Last Updated:** December 12, 2024

---

## Overview

The `growerp` CLI is a command-line tool for managing GrowERP installations, data import/export, package management, and administrative tasks. It provides utilities for setting up development environments, migrating data, and creating new GrowERP packages.

## Installation

### From Pub.dev
```bash
dart pub global activate growerp
```

### From Source
```bash
cd flutter/packages/growerp
dart pub get
dart pub global activate --source path .
```

After installation, ensure `~/.pub-cache/bin` is in your PATH.

---

## Commands

### `growerp help`

Displays help information with all available commands and options.

```bash
growerp help
```

---

### `growerp install`

Installs the complete GrowERP system including frontend, backend, and chat services.

```bash
growerp install [-dev] [-d <directory>]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `-dev` | Use development branch instead of master | master |
| `-d <directory>` | Target installation directory | ~/growerp |

**What It Does:**
1. Clones the GrowERP repository
2. Builds the Moqui backend
3. Initializes the database with seed data
4. Sets up the chat server
5. Starts backend services in the background

**Example:**
```bash
# Install from master branch to default location
growerp install

# Install development version to custom location
growerp install -dev -d /opt/growerp
```

---

### `growerp import`

Imports data from CSV files into a GrowERP system (local or remote).

```bash
growerp import -i <inputDirectory> -u <username> -p <password> [-url <backendUrl>] [-n <companyName>] [-c <currencyId>] [-ft <startFileType>] [-fn <startFileName>] [-sft <stopFileType>]
```

**Options:**
| Option | Description | Required |
|--------|-------------|----------|
| `-i <inputDir>` | Directory containing CSV files | Yes |
| `-u <username>` | Admin email address for login | Yes |
| `-p <password>` | Admin password | Yes |
| `-url <url>` | Backend URL | No (localhost) |
| `-n <companyName>` | Company name (for new registration) | No |
| `-c <currencyId>` | Currency ID (e.g., USD, EUR) | No |
| `-ft <fileType>` | Resume from this file type | No |
| `-fn <fileName>` | Resume from this file name | No |
| `-sft <fileType>` | Stop before this file type | No |

**Supported File Types:**
- `itemType` - Item types
- `paymentType` - Payment types
- `glAccount` - General ledger accounts
- `product` - Products
- `category` - Categories
- `asset` - Assets
- `company` - Companies
- `user` - Users
- `website` - Website configuration
- `finDocTransaction` - Financial document transactions
- `finDocOrderSale` - Sales orders
- `finDocOrderPurchase` - Purchase orders
- `finDocInvoiceSale` - Sales invoices
- `finDocInvoicePurchase` - Purchase invoices
- `finDocPaymentSale` - Sales payments
- `finDocPaymentPurchase` - Purchase payments
- `finDocShipmentIncoming` - Incoming shipments
- `finDocShipmentOutgoing` - Outgoing shipments

**Example:**
```bash
# Import to local system
growerp import -i ./data -u admin@example.com -p password123 -n "My Company" -c USD

# Import to remote system, starting from products
growerp import -i ./data -u admin@example.com -p password123 -url https://api.example.com -ft product
```

---

### `growerp export`

Exports company data to CSV files.

```bash
growerp export -o <outputDirectory> -u <username> -p <password> [-url <backendUrl>]
```

**Options:**
| Option | Description | Required |
|--------|-------------|----------|
| `-o <outputDir>` | Output directory for CSV files | Yes |
| `-u <username>` | Admin email for login | Yes |
| `-p <password>` | Admin password | Yes |
| `-url <url>` | Backend URL | No (localhost) |

**Exported Files:**
- `glAccount.csv` - General ledger accounts
- `company.csv` - Companies
- `user.csv` - Users
- `product.csv` - Products
- `category.csv` - Categories
- `website.csv` - Website configuration

**Example:**
```bash
growerp export -o ./backup -u admin@example.com -p password123
```

---

### `growerp finalize`

Finalizes the import process by completing documents and closing accounting periods.

```bash
growerp finalize -u <username> -p <password> [-url <backendUrl>] [-y <year>]
```

**Options:**
| Option | Description | Required |
|--------|-------------|----------|
| `-u <username>` | Admin email for login | Yes |
| `-p <password>` | Admin password | Yes |
| `-url <url>` | Backend URL | No (localhost) |
| `-y <YYYY>` | Close specific fiscal year | No (all except current) |

**What It Does:**
1. Closes accounting time periods
2. Approves pending invoices
3. Completes pending payments
4. Completes invoice-linked orders
5. Receives incoming shipments
6. Sends outgoing shipments

**Example:**
```bash
# Finalize all years except current
growerp finalize -u admin@example.com -p password123

# Close specific fiscal year
growerp finalize -u admin@example.com -p password123 -y 2023
```

---

### `growerp createPackage`

Creates a new GrowERP package with Flutter frontend and Moqui backend components.

```bash
growerp createPackage <packageName> [-d <directory>]
```

**Arguments:**
| Argument | Description |
|----------|-------------|
| `<packageName>` | Package name (without `growerp_` prefix) |

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `-d <directory>` | Target GrowERP root directory | ~/growerp |

**What It Creates:**

**Flutter Package** (`flutter/packages/growerp_<name>/`):
```
growerp_<name>/
├── lib/
│   ├── growerp_<name>.dart          # Main export
│   ├── l10n/
│   │   └── intl_en.arb              # Localization
│   └── src/
│       ├── models/
│       │   ├── models.dart
│       │   └── demo_model.dart      # Freezed model
│       ├── bloc/
│       │   ├── bloc.dart
│       │   └── demo_bloc.dart       # BLoC with CRUD events
│       ├── repository/
│       │   ├── repository.dart
│       │   └── demo_repository.dart # REST repository
│       ├── views/
│       │   ├── views.dart
│       │   └── demo_list_screen.dart # Full CRUD UI
│       └── integration_test/
│           └── demo_test.dart       # Integration test class
├── example/
│   ├── lib/main.dart                # Example app
│   └── integration_test/
│       └── demo_test.dart           # Integration tests
├── pubspec.yaml
├── l10n.yaml
└── README.md
```

**Moqui Component** (`moqui/runtime/component/<name>/`):
```
<name>/
├── component.xml                    # Component descriptor
├── entity/
│   └── <Name>Entities.xml          # Entity definitions
├── service/
│   └── <Name>Services.xml          # Service definitions
└── data/
    └── <Name>DemoData.xml          # Demo/seed data
```

**Features Included:**
- ✅ Freezed data model with JSON serialization
- ✅ Complete BLoC with Fetch, Create, Update, Delete events
- ✅ REST repository with Dio client
- ✅ List screen with Add, Edit, Delete dialogs
- ✅ Test keys on all UI elements
- ✅ Integration test class with CRUD methods
- ✅ Moqui entity and service definitions
- ✅ Localization support
- ✅ **Automatically adds package to `flutter/melos.yaml`**

**Example:**
```bash
# Create package in default location
growerp createPackage inventory

# Create in specific location
growerp createPackage inventory -d /home/user/mygrowerp
```

**Post-Creation Steps:**
```bash
cd flutter/packages/growerp_inventory
dart run build_runner build --delete-conflicting-outputs
flutter pub get
```

---

### `growerp exportPackage`

Exports a GrowERP package as a zip archive for distribution or backup.

```bash
growerp exportPackage <packageName> [-o <outputDirectory>]
```

**Arguments:**
| Argument | Description |
|----------|-------------|
| `<packageName>` | Full package name (e.g., `growerp_testpkg`) |

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `-o <directory>` | Output directory for zip file | Current directory |

**Archive Contents:**
```
growerp_<name>.zip
├── flutter/
│   └── growerp_<name>/           # Complete Flutter package
│       ├── lib/
│       ├── example/
│       ├── pubspec.yaml
│       └── ...
└── moqui/
    └── <name>/                   # Moqui component (if exists)
        ├── entity/
        ├── service/
        └── ...
```

**Excluded Files:**
- `.dart_tool/` - Dart build cache
- `build/` - Build output
- `.freezed.dart`, `.g.dart` - Generated files
- `pubspec.lock` - Lock files
- `.idea/`, `.vscode/` - IDE settings
- `android/.gradle/`, `ios/Pods/` - Platform build artifacts

**Example:**
```bash
# Export to current directory
growerp exportPackage growerp_testpkg

# Export to specific directory
growerp exportPackage growerp_testpkg -o /tmp/archives
```

---

### `growerp importPackage`

Imports a GrowERP package from a zip archive and adds it to the project.

```bash
growerp importPackage <archivePath>
```

**Arguments:**
| Argument | Description |
|----------|-------------|
| `<archivePath>` | Path to the zip archive file |

**What It Does:**
1. Validates the archive structure
2. Extracts Flutter package to `flutter/packages/`
3. Extracts Moqui component to `moqui/runtime/component/` (if present)
4. **Automatically adds the package to `melos.yaml`**

**Example:**
```bash
# Import a package
growerp importPackage /tmp/growerp_inventory.zip
```

**Post-Import Steps:**
```bash
# Bootstrap melos to include the new package
melos bootstrap

# Build generated files
cd flutter/packages/growerp_inventory
dart run build_runner build --delete-conflicting-outputs
```

---

## Configuration Files

### app_settings.json

Used by the import/export commands to configure backend connection:

```json
{
  "backendUrl": "http://localhost:8080",
  "classificationId": "AppAdmin",
  "chatUrl": "ws://localhost:3000"
}
```

---

## Common Workflows

### Setting Up a New Development Environment

```bash
# 1. Install GrowERP
growerp install

# 2. Start the backend (if not already running)
cd ~/growerp/moqui
java -jar moqui.war no-run-es &

# 3. Run an example app
cd ~/growerp/flutter/packages/admin
flutter run
```

### Creating and Testing a New Package

```bash
# 1. Create the package
growerp createPackage myfeature -d ~/growerp

# 2. Build generated files
cd ~/growerp/flutter/packages/growerp_myfeature
dart run build_runner build --delete-conflicting-outputs

# 3. Run the example app
cd example
flutter run

# 4. Run integration tests (requires running backend + emulator)
flutter test integration_test
```

### Migrating Data Between Systems

```bash
# 1. Export from source system
growerp export -o ./migration -u admin@source.com -p password -url https://source.example.com

# 2. Import to target system
growerp import -i ./migration -u admin@target.com -p password -n "New Company" -c USD -url https://target.example.com

# 3. Finalize the import
growerp finalize -u admin@target.com -p password -url https://target.example.com
```

### Sharing a Package

```bash
# 1. Export the package
growerp exportPackage growerp_myfeature -o ./dist

# 2. Share the zip file

# 3. Recipient imports the package
growerp importPackage growerp_myfeature.zip

# 4. Bootstrap melos
melos bootstrap
```

---

## Troubleshooting

### Command Not Found

If `growerp` is not found after installation:

```bash
# Add pub cache to PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Or for Windows
set PATH=%PATH%;%USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### Backend Connection Errors

```bash
# Check if backend is running
curl http://localhost:8080/api/echo

# If using a remote backend, ensure the URL is correct
growerp import -url https://api.example.com ...
```

### Import Resumption

If import fails partway through:

```bash
# Resume from a specific file type
growerp import -i ./data -u admin@example.com -p password -ft product

# Resume from a specific file
growerp import -i ./data -u admin@example.com -p password -fn product-0005.csv
```

### Package Creation Errors

If `createPackage` fails:

```bash
# Ensure you're in or specifying the correct GrowERP root
growerp createPackage myfeature -d /path/to/growerp

# The directory should contain flutter/ and moqui/ subdirectories
```

---

## Related Documentation

- [Building Blocks Development Guide](Building_Blocks_Development_Guide.md) - Creating GrowERP packages
- [Backend Components Development Guide](Backend_Components_Development_Guide.md) - Moqui development
- [Integration Test Guide](Integration_Test_Guide.md) - Testing packages
- [GrowERP Extensibility Guide](GrowERP_Extensibility_Guide.md) - Extending GrowERP

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.10.5 | Dec 2024 | Added exportPackage, importPackage commands |
| 1.10.4 | Nov 2024 | Added createPackage command |
| 1.10.0 | Oct 2024 | Initial CLI release with install, import, export, finalize |

---

**Need Help?** Run `growerp help` for quick command reference or visit [https://www.growerp.com](https://www.growerp.com)
