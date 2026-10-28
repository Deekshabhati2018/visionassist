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
- one-frame object detection through the real AI service
- versioned detection response validation in the Flutter client
- loading, network/model error, empty-result, and detection-result states
- widget tests for the onboarding, preview, and camera-denial flows

Not implemented yet:

- continuous detection
- alert prioritization
- text-to-speech

The camera milestone uses the official Flutter `camera` plugin at version
`0.12.1`. It resolves to `camera_android_camerax 0.7.4+8`, which uses the
CameraX 1.6.2 line and includes the fix for
`CallbackToFutureAdapter` missing during Java compilation.

The previous `camera 0.11.4` / `camera_android_camerax 0.6.30` combination
used CameraX 1.5.3 and could fail with
`camera_android_camerax:compileDebugJavaWithJavac`. Do not downgrade the
CameraX implementation back to that combination.

The **Analyze Current Frame** button captures one JPEG, sends it to the
configured detector, reads the response, then deletes the temporary capture.
Frames are not retained by the Flutter client or the AI service.

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

## Connect the phone to the AI service

Run the AI service on the Windows computer from the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r ai-service\requirements.txt
$env:PYTHONPATH = "ai-service"
python -m uvicorn ai_service.main:app --host 0.0.0.0 --port 8000
```

For an Android emulator, the app defaults to `http://10.0.2.2:8000`.
For a physical phone, connect the phone and computer to the same trusted Wi-Fi,
find the computer's IPv4 address with `ipconfig`, and run the app with that
address:

```powershell
flutter run --dart-define=VISIONASSIST_AI_BASE_URL=http://192.168.1.20:8000
```

Replace `192.168.1.20` with the computer's actual LAN IPv4 address. For local
HTTP testing only, Android may require
`android:usesCleartextTraffic="true"` on the generated `<application>` element
in `android\app\src\main\AndroidManifest.xml`. Do not use unencrypted HTTP on
untrusted networks; use an HTTPS AI-service URL for remote testing.

For a release build, confirm the generated main manifest contains
`<uses-permission android:name="android.permission.INTERNET" />`. Keep
cleartext traffic enabled only for local development; do not ship that setting
for a public release.

The first analysis request downloads the model and can take up to 90 seconds.
Subsequent requests should be faster. The UI never runs detection continuously.

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
8. Start the AI service, tap **Analyze Current Frame**, and confirm a real detection response or the explicit empty-result state.