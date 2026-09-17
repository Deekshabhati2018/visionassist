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

The camera milestone uses the official Flutter `camera` plugin. Version
`0.11.2+1` is the compatible release range for this project's declared Dart
3.7 / Flutter 3.29 baseline. Newer plugin releases may require a newer local
Flutter SDK.

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

## Camera testing checklist

On a physical Android phone:

1. Start the app and tap Continue.
2. Tap Start Assistance.
3. Allow camera access when Android asks.
4. Confirm the live preview appears and the status says `Assistance is active`.
5. Tap Stop Assistance and confirm the preview closes.
6. Deny camera access and confirm the app explains how to enable it in Android settings.
7. Background and resume the app while assistance is active and confirm the preview recovers.