# VisionAssist setup

This guide is intentionally staged. Install and verify one major toolchain at a time so an error has a clear cause.

## 1. Current workspace shell

The repository currently uses the Replit pnpm workspace:

```bash
pnpm --filter @workspace/api-server run dev
pnpm run typecheck
pnpm run build
```

The API scaffold is Express-based today because it is the workspace's existing runnable service. The capstone backend target remains Spring Boot + Java; we will introduce it after the AI and decision-engine boundaries are proven.

## 2. Required toolchains

The specification calls for:

| Tool | Why it is needed | First verification |
| --- | --- | --- |
| Git | Version history and meaningful milestones | `git --version` |
| Java 21+ | Spring Boot backend | `java -version` |
| Maven | Spring Boot build and tests | `mvn -version` |
| Python 3.x | AI service and model experiments | `python --version` |
| pip/venv | Isolated Python dependencies | `pip --version` |
| Flutter + Dart | Android application | `flutter --version`, `dart --version` |
| Android SDK + ADB | Device install, permissions, and logs | `adb --version` |
| Docker | Reproducible MySQL and service environment | `docker --version` |

The first environment check found Git, Python, and Docker available. Java/Maven, Flutter/Dart, and ADB still need to be installed in the development environment before their milestones.

## 3. Installation order

Install in this order:

1. Android Studio, including Android SDK, platform tools, and an emulator or physical-device support.
2. Flutter, then verify Dart through the Flutter installation.
3. JDK 21 and Maven.
4. Python virtual-environment support and the AI service dependencies.
5. Docker Desktop or an equivalent Docker runtime.

After each installation, run only the verification command in the table above. Keep the complete output when diagnosing a failure.

## 4. Device readiness

Before the camera milestone:

- Enable Android developer options and USB debugging on a test device.
- Connect the device with a USB cable or start an emulator.
- Run `adb devices`.
- Confirm the device is authorized.
- Do not use a real user's face or private environment for the initial test dataset.

## 5. Environment variables

Configuration will be supplied through environment variables and local ignored files. Never place values in source control.

Planned configuration includes:

- backend database URL and credentials
- service-to-service URLs
- model paths or model download configuration
- development-only logging options

The foundation milestone does not require any of these values.

## 6. Troubleshooting rule

When a command fails, capture:

1. the exact command,
2. the complete error output,
3. the tool version,
4. the operating system,
5. what changed immediately before the failure.

We diagnose the actual log before changing dependencies or configuration.