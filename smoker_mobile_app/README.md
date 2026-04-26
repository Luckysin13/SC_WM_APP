# Smoker Mobile App

The native Flutter mobile application for interacting with the ESP32 Smoker Controller on your local network.

This application runs on iOS and Android to replace the previous embedded web UI constraints, delivering responsive native widgets, local network scanning via mDNS, historical visualization, PID tuning tools, and Over-The-Air firmware updating processes.

## Architecture Guidelines

- **Domain Driven:** Features are scoped via `lib/features/<name>`.
- **State Management:** Fully integrated Riverpod 2.0 implementation without mutable `setState` artifacts for connection bounds.
- **Protocols:** Built aggressively to wrap the raw WebSocket commands of the firmware v5.0.1+ interface while providing a REST payload wrapper for configuration setups.

## Connecting
1. Power up the ESP32.
2. If connecting for the first time, join its AP `SmokerSetupAP` and use this app to map credentials.
3. Once booted on your local router, this app's mDNS client handles the rest under `smoker.local`.

## Building
```bash
flutter pub get
flutter run
```

## Versioning
This project uses Semantic Versioning (`major.minor.patch+build`).
To bump the version automatically, use the provided script:

- **Bump Build Number:** `./scripts/bump_version.sh build` (e.g., `1.0.0+1` -> `1.0.0+2`)
- **Bump Patch:** `./scripts/bump_version.sh patch` (e.g., `1.0.0+1` -> `1.0.1+2`)
- **Bump Minor:** `./scripts/bump_version.sh minor` (e.g., `1.0.0+1` -> `1.1.0+2`)
- **Bump Major:** `./scripts/bump_version.sh major` (e.g., `1.0.0+1` -> `2.0.0+2`)

The version is displayed in the **Configuration** screen and the **Troubleshooting** screen using the `VersionDisplay` widget.
