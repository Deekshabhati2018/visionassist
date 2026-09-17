# VisionAssist mobile application

This folder contains the Flutter + Dart Android application shell for VisionAssist.

## Current milestone

Implemented:

- safety-aware onboarding screen
- accessible home screen
- large Start Assistance / Stop Assistance controls
- explicit prototype messaging before camera integration
- widget tests for the onboarding and assistance state flow

Not implemented yet:

- camera permission
- live camera preview
- AI inference
- text-to-speech

Those are separate milestones so each integration can be tested on a real Android device instead of being hidden behind a simulated screen.

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