
Headless Android Emulator

Builds a Docker image that runs a headless Android emulator for CI integration tests.

Based on Ubuntu 20.04 with:
- Java 17 (openjdk-17-jdk)
- Android SDK command-line tools (commandlinetools-linux-13114758)
- Android API 34, x86_64, google_apis system image
- Swiftshader software rendering (no GPU required)
- Snapshot support for fast emulator startup on CI

Files:
- Dockerfile              — image definition
- entrypoint.sh           — starts adb redirect and emulator
- run_emulator.sh         — launches the emulator binary with correct flags
- adb_redirect.sh         — forwards ADB/console ports to the host network interface
- prepare_snapshot.sh     — one-time script to boot and save a CI snapshot
- hardware/config_34.ini  — AVD hardware config for API 34

Exposed ports: 5037 (ADB server), 5554/5555 (emulator console/ADB), 5556/5557 (second emulator)

To build and publish the image:
1. cd to this directory
2. docker build -t growerp/android-emulator .
3. docker push growerp/android-emulator


