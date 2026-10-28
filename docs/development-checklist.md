# Development checklist

## Foundation

- [x] Repository name and purpose are documented
- [x] Target service boundaries are documented
- [x] Safety and privacy boundaries are documented
- [x] Setup and installation order are documented
- [x] Teaching format is documented
- [x] Milestone roadmap exists
- [ ] Local toolchain verification is complete

## Mobile shell milestone

- [x] Flutter app package and Dart entry point exist
- [x] Onboarding includes prototype safety language
- [x] Assistance start/stop state is accessible
- [x] Widget test covers the primary state transition
- [x] Android runner generated with the local Flutter SDK
- [ ] `flutter analyze` passes on the Windows development machine
- [ ] `flutter test` passes on the Windows development machine
- [x] App shell runs on a physical Android device

## Mobile camera milestone

- [x] Camera dependency and platform abstraction are documented
- [x] CameraX compile-classpath dependency is pinned to a fixed plugin release
- [x] Camera permission is requested when assistance starts
- [x] Live preview uses the back camera when available
- [x] Preview stops when assistance stops
- [x] Preview controller is released when the app is paused
- [x] Denied and unavailable camera states have user-facing messages
- [x] Widget tests cover successful preview setup and camera denial
- [ ] `flutter pub get` passes on the Windows development machine
- [ ] `flutter analyze` passes on the Windows development machine
- [ ] `flutter test` passes on the Windows development machine
- [ ] `flutter build apk --debug` passes after refreshing Android dependencies
- [ ] Permission denial and app resume are verified on a physical device

## AI detection milestone

- [x] Python service health endpoint and model readiness state exist
- [x] Pretrained ONNX detector produces real object detections
- [x] Versioned detection response has validated bounding-box bounds
- [x] API rejects unsupported image types and malformed image bytes
- [x] Flutter sends a single temporary JPEG per explicit user action
- [x] Flutter validates the response and displays loading, errors, empty results, and detections
- [x] No raw frame is persisted by the mobile client or AI service
- [ ] Flutter analyze and widget tests pass on the Windows development machine
- [ ] One-shot camera-to-AI flow is verified on the physical Android phone

## Per-milestone quality gate

- [ ] The milestone has one clear user-visible or engineering outcome
- [ ] New dependencies are explained before installation
- [ ] The repository still starts or builds as documented
- [ ] Relevant tests or checks pass
- [ ] Logs were inspected when diagnosing failures
- [ ] No secrets, credentials, raw camera frames, or unnecessary location data are committed
- [ ] Safety language remains visible where users could misunderstand the prototype
- [ ] A meaningful commit was created
- [ ] The GitHub repository is updated when authentication is available
- [ ] The user received: completed, files changed, tests, commit, learned, next milestone

## MVP definition of done

- [ ] Android app installs on a real phone
- [ ] Camera permission works
- [ ] Frames reach the AI pipeline
- [ ] At least 5–10 useful object classes work in the chosen test environment
- [ ] Tracking and throttling prevent repetitive alerts
- [ ] Decision engine prioritizes events
- [ ] Text-to-speech speaks high-priority events
- [ ] Backend stores users, sessions, and events
- [ ] React dashboard shows history and events
- [ ] Setup is documented
- [ ] Source, docs, and tests are in GitHub
- [ ] End-to-end demo works without manual code edits