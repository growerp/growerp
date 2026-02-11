# AGP 9+ Migration Fix for GrowERP Flutter Packages

## Problem
Starting with Android Gradle Plugin (AGP) 9.0+, the new DSL interface is enforced by default. This causes build failures when applying the Flutter Gradle plugin because Flutter doesn't yet fully support the new AGP 9+ DSL.

Error message:
```
[!] Starting AGP 9+, only the new DSL interface will be read. This results in a build failure when applying the Flutter Gradle plugin
```

## Solution
The recommended workaround is to opt out of the new DSL by setting the `android.newDsl=false` flag in `gradle.properties`. This allows the project to continue using the old DSL interfaces while maintaining compatibility with AGP 9+.

## Changes Made

### 1. Added `android.newDsl=false` to all `gradle.properties` files
Location: `*/android/gradle.properties`

Added the following line after `android.useAndroidX=true`:
```properties
android.newDsl=false
```

This flag tells AGP 9+ to use the old DSL interfaces, which are compatible with the current Flutter Gradle plugin.

### 2. Maintained Old DSL Configuration
- Kept `id "kotlin-android"` plugin in the plugins block
- Kept `kotlinOptions` block instead of migrating to `kotlin { compilerOptions {} }`

## Files Modified
All Android build configuration files across the GrowERP packages:
- 14 Groovy DSL files (`build.gradle`)
- 5 Kotlin DSL files (`build.gradle.kts`)
- 17 `gradle.properties` files

## Verification
Tested with the `support` package:
```bash
cd /home/hans/growerp/flutter/packages/support
flutter clean
flutter pub get
flutter build apk --debug
```
✅ Build succeeded!

## Future Migration
When Flutter adds full support for AGP 9+ new DSL (tracked in [Issue #180137](https://github.com/flutter/flutter/issues/180137)), you can migrate to the new DSL by:

1. Removing `android.newDsl=false` from `gradle.properties`
2. Removing `id "kotlin-android"` plugin
3. Replacing `kotlinOptions` with:
   ```gradle
   kotlin {
       compilerOptions {
           jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
       }
   }
   ```

## References
- [Flutter AGP 9 Migration Guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9)
- [Flutter Issue #180137](https://github.com/flutter/flutter/issues/180137)
- [Android Gradle Plugin Release Notes](https://developer.android.com/build/releases/gradle-plugin)

## Scripts Created
- `fix_agp9_migration.sh` - Initial migration script (attempted new DSL)
- `revert_to_old_dsl.sh` - Revert script (final solution using old DSL with flag)

## Date
2026-02-11
