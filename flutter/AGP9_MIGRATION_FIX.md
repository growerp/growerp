# AGP 9 / Gradle 9 build configuration

## Current stack

All Android projects under `flutter/packages/*/android` (apps and package examples)
run the same stack:

| Item | Version |
|---|---|
| Gradle wrapper | 9.1.0 |
| `com.android.application` (AGP) | 9.0.1 |
| `org.jetbrains.kotlin.android` (KGP) | 2.3.20 |
| Java / `jvmTarget` | 17 |

Flutter (3.47) drops support for Gradle < 9.1.0, which forced this upgrade.
Build scripts are Kotlin DSL only — `settings.gradle.kts`, `build.gradle.kts`,
`app/build.gradle.kts`. The groovy variants were removed.

## Why `android.newDsl=false` is still set

Starting with AGP 9, only the new DSL interface is read, and the Flutter Gradle
plugin does not yet support it:

```
[!] Starting AGP 9+, only the new DSL interface will be read. This results in a
    build failure when applying the Flutter Gradle plugin
```

So every `android/gradle.properties` keeps:

```properties
android.newDsl=false
android.builtInKotlin=false
```

`builtInKotlin=false` keeps KGP in charge of Kotlin compilation; with it off,
the Flutter Gradle plugin applies `kotlin-android` itself, which is why the app
build files do not declare that plugin.

Remove both flags only once Flutter supports the new DSL and built-in Kotlin
(tracked in [Issue #180137](https://github.com/flutter/flutter/issues/180137)).

## What AGP 9 required changing

- `rootProject.buildDir` → `rootProject.layout.buildDirectory` (removed in Gradle 9)
- `compileSdkVersion` / `targetSdkVersion` methods → `compileSdk =` / `targetSdk =`
- `kotlinOptions {}` → `kotlin { compilerOptions { jvmTarget = …JvmTarget.JVM_17 } }`
- `android.enableJetifier=true` dropped — Jetifier is gone in AGP 9
- `multiDexEnabled` + `com.android.support:multidex` dropped — minSdk 24 has
  native multidex, and the support-library artifact needed Jetifier. The stale
  `FlutterMultiDexApplication.java` copies were deleted with it.
- `package="…"` removed from every `AndroidManifest.xml`; `namespace` in the
  build file is authoritative
- `aaptOptions { noCompress "bin" }` → `androidResources { noCompress += "bin" }`
  (Patrol setup in `growerp_order_accounting/example`)
- the `androidx.glance` / `androidx.compose.remote` `resolutionStrategy` pin (an
  AGP 8 workaround for `home_widget`) is no longer needed and was removed

The inert `flutter.compileSdkVersion` / `flutter.minSdkVersion` lines in
`gradle.properties` were also dropped — the Flutter Gradle plugin never read
them; SDK levels come from `flutter.compileSdkVersion` / `flutter.minSdkVersion`
/ `flutter.targetSdkVersion` in the build file.

## Verification

`flutter build apk --debug` passes for all Android projects except
`packages/website`, whose `lib/main.dart` imports `flutter_web_plugins`
(web-only) and therefore cannot compile for Android — a pre-existing condition
unrelated to Gradle; `website` ships web-only.

## Date

2026-08-14 (previous revision 2026-02-11)
