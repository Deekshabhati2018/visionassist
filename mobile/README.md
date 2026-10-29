# VisionAssist mobile application

This folder contains the Flutter + Dart Android application for VisionAssist.

## Current milestone

Implemented:

- accessible onboarding and persistent prototype safety notice
- explicit camera permission request and back-camera preview
- camera cleanup when assistance stops or Android backgrounds the app
- one-shot **Analyze Current Frame** action using the real pretrained detector
- continuous assistance with 3, 5, or 10 second sampling intervals
- sequential requests; overlapping inference is skipped
- Start, Pause, Resume, and Stop Continuous controls
- concise scene summaries, object labels, confidence percentages, and detection counts
- Android text-to-speech with Speak Again, Mute/Unmute, rate, and volume controls
- repeat suppression for identical automatic summaries
- loading, AI-service health, server-error, malformed-response, timeout, and empty-result states
- bounded upload size, validated API data, and abortable in-flight analysis
- Python and Flutter unit/widget coverage for the service, response contract, and controls

Frames are captured only for an analysis request. The Flutter camera plugin
deletes each temporary capture after reading it, and the AI service does not
retain uploaded images. Stop Assistance cancels sampling and pending requests,
stops speech, and releases the camera session. Continuous assistance pauses
when Android backgrounds the app; resume it explicitly after returning.

Scene summaries describe object labels and counts only. Bounding boxes do not
provide distance, motion, or hazard estimates. VisionAssist is an assistive
prototype, not a certified mobility or safety device.

## Camera and speech dependencies

The project uses the official Flutter `camera` plugin at version `0.12.1`. It
resolves to `camera_android_camerax 0.7.4+8`, which includes the CameraX
compile-classpath fix for `CallbackToFutureAdapter`. Do not downgrade to the
previous `camera 0.11.4` / `camera_android_camerax 0.6.30` combination.

Speech uses `flutter_tts 4.2.5` and Android's installed text-to-speech engine.
Choose or enable a speech engine in Android's Text-to-speech settings if speech
is unavailable.

## Windows setup and Android build

From the repository root in PowerShell, install the Python dependencies and
start the AI service:

```powershell
cd C:\path\to\visionassist
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r ai-service\requirements.txt
$env:PYTHONPATH = "ai-service"
python -m uvicorn ai_service.main:app --host 0.0.0.0 --port 8000
```

The pretrained YOLOv5n ONNX weights download on the first inference. They are
stored under `ai-service\models` and are intentionally not committed to Git.
The first request may take longer while the model loads.

## Test the Python AI service

From the repository root, run the API and detector tests:

```powershell
cd C:\path\to\visionassist
$env:PYTHONPATH = "ai-service"
python -m unittest discover -s ai-service\tests -v
python -m compileall -q ai-service\ai_service ai-service\tests
```

With the AI service still running in its first PowerShell window, validate the
live pretrained model and response contract from another window. Use a local
JPEG, PNG, or WebP image path; the script validates and prints the response
without saving the image:

```powershell
cd C:\path\to\visionassist
$env:PYTHONPATH = "ai-service"
python ai-service\scripts\smoke_test.py C:\path\to\test-image.jpg
```

In a second PowerShell window, prepare the Android runner and run the mobile
checks:

```powershell
cd C:\path\to\visionassist\mobile
flutter create --platforms=android --project-name visionassist_mobile .
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The repository contains Flutter source and dependency configuration, but not
the generated `android` runner. If `flutter create` asks whether to replace
`lib\main.dart`, keep the existing VisionAssist file.

## Connect a physical phone to the AI service

1. Put the PC and phone on the same trusted Wi-Fi network.
2. In PowerShell, run `ipconfig` and note the active Wi-Fi adapter's IPv4
   address. Do not use the phone's address.
3. Confirm the Windows network is marked **Private** with
   `Get-NetConnectionProfile`.
4. If Windows Firewall blocks access, run this from an Administrator
   PowerShell window while on that trusted Private network:

   ```powershell
   New-NetFirewallRule -DisplayName "VisionAssist AI (Local Wi-Fi)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -Profile Private -RemoteAddress LocalSubnet
   ```

   Remove the temporary rule when finished:

   ```powershell
   Remove-NetFirewallRule -DisplayName "VisionAssist AI (Local Wi-Fi)"
   ```

5. After the service is running, launch Flutter with the PC's actual Wi-Fi IPv4
   address:

   ```powershell
   cd C:\path\to\visionassist\mobile
   flutter run --dart-define=VISIONASSIST_AI_BASE_URL=http://192.168.1.20:8000
   ```

   Replace `192.168.1.20` with the address found using `ipconfig`. Android
   emulators can use the default `http://10.0.2.2:8000`.

For local HTTP development only, Android may require
`android:usesCleartextTraffic="true"` on the generated `<application>` element
in `android\app\src\main\AndroidManifest.xml`. Confirm that the main manifest
contains `<uses-permission android:name="android.permission.INTERNET" />`.
Keep cleartext traffic limited to local development. The AI endpoint has no
caller authentication and must not be exposed on untrusted or public networks;
use an authenticated HTTPS deployment for remote use.

## Manual phone checks

On the Android phone:

1. Continue through onboarding and confirm the safety notice is visible.
2. Start Assistance and verify the camera preview and Camera/AI service/Analysis
   status rows.
3. Tap **Analyze Current Frame** and verify a real detection list or the
   explicit no-objects result.
4. Verify a new summary is spoken; tap **Speak Again**, then test Mute/Unmute,
   speech rate, and volume.
5. Start continuous assistance, pause it, resume it, then stop it. Confirm that
   no more frames are sent after stopping.
6. Tap **Stop Assistance** while speech is playing and confirm speech stops and
   the camera closes.
7. Stop the Python service and verify the app reports a reachable-service
   error instead of freezing.

For an Android build after changing camera dependencies, run
`flutter clean`, `flutter pub get`, and `flutter build apk --debug` as shown
above. The dependency override for CameraX must remain in `pubspec.yaml`.
