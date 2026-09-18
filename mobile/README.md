# VisionAssist mobile application

This folder contains the Flutter + Dart Android application shell for VisionAssist.

## Current milestone

Implemented:

- safety-aware onboarding screen
- accessible home screen
- large Start Assistance / Stop Assistance controls
- explicit camera permission request when assistance starts
- live camera preview with back-camera selection
- camera lifecycle cleanup when the app is paused or stopped
- clear denied, blocked, unavailable, and restricted camera states
- widget tests for the onboarding, preview, and denial flows

Not implemented yet:

- AI inference
- text-to-speech

The camera milestone uses the official Flutter `camera` plugin at version
`0.12.1`. It resolves to `camera_android_camerax 0.7.4+8`, which uses the
CameraX 1.6.2 line and includes the fix for
`CallbackToFutureAdapter` missing during Java compilation.

The previous `camera 0.11.4` / `camera_android_camerax 0.6.30` combination
used CameraX 1.5.3 and could fail with
`camera_android_camerax:compileDebugJavaWithJavac`. Do not downgrade the
CameraX implementation back to that combination.

This milestone only displays a live preview. It does not capture, save, or
upload raw camera video.

## Run locally on Windows

From a terminal with Flutter available:

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
```

This repository currently contains the Dart app shell but not the generated Android runner files. Create those once from the Flutter SDK:

```powershell
flutter create --platforms=android --project-name visionassist_mobile .
```

Then connect an emulator or Android phone and run:

```powershell
flutter devices
flutter run
```

If `flutter create` asks before updating an existing file, keep the existing `lib/main.dart` from this repository.

## Android build verification

After changing the camera dependency line, refresh the generated Android
artifacts before building:

```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

The Android runner is generated locally by Flutter. This repository keeps the
Flutter source and dependency configuration; it does not commit generated
Android runner files.

## Camera testing checklist

On a physical Android phone:

1. Start the app and tap Continue.
2. Tap Start Assistance.
3. Allow camera access when Android asks.
4. Confirm the live preview appears and the status says `Assistance is active`.
5. Tap Stop Assistance and confirm the preview closes.
6. Deny camera access and confirm the app explains how to enable it in Android settings.
7. Background and resume the app while assistance is active and confirm the preview recovers.