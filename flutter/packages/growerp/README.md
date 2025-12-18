# GrowERP CLI Utilities

A command line utility for GrowERP installation, import/export, and package management.

## Installation

Activate local version:
```bash
dart pub global activate --source path ~/growerp/flutter/packages/growerp
```

Activate public version:
```bash
dart pub global activate growerp
```

## Subcommands

| Command | Description |
|---------|-------------|
| `help` | Display help information for all commands |
| `install` | Install the complete GrowERP system (frontend, backend, chat) |
| `import` | Import CSV data files into a GrowERP system |
| `export` | Export company data to CSV files (under development) |
| `finalize` | Finalize the import process by completing documents and periods |
| `createPackage` | Create a new GrowERP package with Flutter frontend and Moqui backend |
| `exportPackage` | Export a GrowERP package as a zip archive |
| `importPackage` | Import a GrowERP package from a zip archive |

---

## help

Display detailed help information for all available commands.

```bash
growerp help
```

---

## install

Installs the complete GrowERP system:
1. Clone the repository from GitHub into the local `~/growerp` directory
2. Start the backend and chat server
3. Activate the dart melos global command
4. Build the Flutter system
5. The 'admin' package can now be started with `flutter run`

```bash
growerp install
```

**Flags:**
- `-dev` — Use the development branch instead of master
- `-d <path>` — Target directory (default: `~/growerp`)

---

## import

Upload data (ledger/glAccount, customers, products, etc.) from CSV files into GrowERP.

```bash
growerp import -i <inputDir> -u <email> -p <password> [options]
```

**Parameters:**
| Flag | Description |
|------|-------------|
| `-i <path>` | Input file or directory containing CSV files and images |
| `-u <email>` | User email address for login |
| `-p <password>` | Password for login |
| `-url <url>` | Backend URL (default: localhost) |
| `-n <name>` | New company name |
| `-c <currency>` | Currency ID (e.g., USD, EUR) |
| `-ft <fileType>` | Resume from this file type |
| `-fn <filename>` | Resume from this filename |
| `-sft <fileType>` | Stop just before this file type |
| `-t <seconds>` | Receive timeout (default: 600 seconds) |

**Example:**
```bash
growerp import -i growerpOutput -u admin@example.com -p secret123 -n "My Company" -c USD
```

---

## export

Export company-related information to CSV files. *(Under development)*

```bash
growerp export -u <email> -p <password> [options]
```

**Parameters:**
| Flag | Description |
|------|-------------|
| `-u <email>` | User email address for login |
| `-p <password>` | Password for login |
| `-o <dir>` | Output directory name (default: `growerpCsv`) |
| `-ft <fileType>` | Export only this file type |
| `-url <url>` | Backend URL |

---

## finalize

Finalize the import process by:
1. Complete all documents posted in the ledger
2. Complete orders with completed invoices
3. Approve invoices and complete payments
4. Process shipments
5. Close past time periods

```bash
growerp finalize -u <email> -p <password> [options]
```

**Parameters:**
| Flag | Description |
|------|-------------|
| `-u <email>` | User email address for login |
| `-p <password>` | Password for login |
| `-y <YYYY>` | Close a specific fiscal year (if missing, closes all except current year) |
| `-url <url>` | Backend URL |

---

## createPackage

Create a new GrowERP package with both Flutter frontend and Moqui backend components.

```bash
growerp createPackage <name> [options]
```

**Parameters:**
| Argument/Flag | Description |
|---------------|-------------|
| `<name>` | Package name (without `growerp_` prefix) |
| `-d <path>` | Target directory (default: `~/growerp`) |

Creates:
- `flutter/packages/growerp_<name>/` — Flutter frontend package
- `moqui/runtime/component/growerp-<name>/` — Moqui backend component

**Example:**
```bash
growerp createPackage inventory
```

---

## exportPackage

Export an existing GrowERP package as a zip archive for distribution or backup.

```bash
growerp exportPackage <packageName> [options]
```

**Parameters:**
| Argument/Flag | Description |
|---------------|-------------|
| `<packageName>` | Full package name (e.g., `growerp_inventory`) |
| `-o <dir>` | Output directory for the zip file (default: current directory) |

**Example:**
```bash
growerp exportPackage growerp_inventory -o ~/backups
```

---

## importPackage

Import a GrowERP package from a zip archive. Automatically adds the package to `melos.yaml`.

```bash
growerp importPackage <archivePath>
```

**Parameters:**
| Argument | Description |
|----------|-------------|
| `<archivePath>` | Path to the zip file to import |

**Example:**
```bash
growerp importPackage ~/downloads/growerp_inventory.zip
```

---

## convertToCsv Command

A separate utility to convert exported CSV/ODS/XLSX files from other systems to the GrowERP CSV format.

```bash
convertToCsv <inputDir> [fileType]
```

**Parameters:**
- `<inputDir>` — Directory containing the source files
- `[fileType]` — Optional: specific file type to convert

**Example:**
```bash
convertToCsv inputDir transaction
```

Creates a `growerpOutput` directory with the converted files.

---

## Complete Conversion Workflow

1. **Export** files from the old system and place them in a single directory
2. **Create images directory** (if importing images): create an `images/` folder and `images.csv` file
3. **Configure conversion rules** in the `convert_to_csv` program:
   - Specify file names in `getFileNames` function
   - Specify file-wide changes in `convertFile` function
   - Specify column mappings in `convertRow` function
4. **Convert** the files:
   ```bash
   dart pub global activate --source path ~/growerp/flutter/packages/growerp
   dart pub global run growerp:convertToCsv inputDir -f fileType -start yyyy/mm/dd -end yyyy/mm/dd
   ```
5. **Import** into GrowERP:
   ```bash
   growerp import -i growerpOutput -u username -p password
   ```
6. **Finalize** the import:
   ```bash
   growerp finalize -u username -p password
   ```

### Pre-Import Checklist

Before running `import`:
1. [Pause](http://localhost:8080/vapps/system/ServiceJob/Jobs/ServiceJobDetail?jobName=recalculate_GlAccountOrgSummaries) the 'recalculate account summaries' job

Before running `finalize`:
1. Disable accounting SECA by modifying files as listed in [initstart.sh](moqui/runtime/component/growerp/deploy/initstart.sh) under 'DISABLE_SECA'

After `finalize`:
1. Re-enable the recalculate job
2. Restore SECA files
