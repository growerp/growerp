# Version Management Script

This directory contains a Dart script (`set_version.dart`) to manage versions across all GrowERP packages.

## Usage

```bash
# Navigate to the flutter directory
cd flutter

# Set version for all packages
dart set_version.dart <new_version>

# Example: Set all packages to version 1.11.0
dart set_version.dart 1.11.0
```

## What the script does

1. **Finds all packages**: Scans the `packages/` directory for `pubspec.yaml` files (excluding example directories)

2. **Preserves build numbers**: If a package has a version like `1.10.0+91`, it will update to `1.11.0+91` (preserving the `+91`)

3. **Updates version tags only**: Only modifies the `version:` field, leaving all dependencies unchanged

4. **Provides feedback**: Shows exactly what was changed and provides next steps

## Example Output

```
Setting version to: 1.11.0
Scanning packages...
Found 17 packages to update:
  - growerp_models
  - growerp_core
  - admin
  - hotel
  [...]

  Updated admin: 1.10.0+91 -> 1.11.0+91
  Updated growerp_core: 1.10.0 -> 1.11.0
  [...]

Version update completed successfully!
All packages updated to version: 1.11.0

Note: Only version tags were updated, dependencies were not modified.
```

## After running the script

1. Manually update dependencies if needed (the script no longer does this automatically)
2. Run `melos clean && melos bootstrap` to refresh dependencies
3. Test the changes to ensure everything works
4. Commit the version changes to git

## Package types handled

- **growerp_*** packages**: Core building block packages
- **Application packages**: admin, hotel, website, freelance, health, support
- **Internal dependencies**: Automatically updates references between growerp packages

## Version format

The script expects semantic versioning format: `x.y.z` (e.g., `1.11.0`)

Build numbers in the format `+xx` are automatically preserved.