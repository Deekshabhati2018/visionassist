# VisionAssist roadmap

The project is built as one demonstrable loop, not as disconnected model demos.

## Phase 1 — foundation

- [x] Create repository and documentation structure
- [x] Record safety, privacy, and data-minimization rules
- [x] Define target service boundaries and milestone order
- [x] Add setup guide, learning guide, and development checklist
- [ ] Verify local toolchains one at a time

## Phase 2 — mobile camera foundation

- [x] Create the Flutter/Dart app shell
- [x] Generate the Android runner and verify the shell on a physical device
- [x] Add onboarding and safety notice
- [x] Add accessible home screen
- [x] Add Start Assistance / Stop Assistance shell states
- [x] Add explicit camera permission flow
- [x] Add live camera preview without storing raw video
- [ ] Verify denied, blocked, and resume camera states on a physical device
- [ ] Capture test frames without storing raw video

## Phase 3 — AI inference

- [ ] Create the Python service and isolated environment
- [ ] Add health endpoint
- [ ] Add pretrained object detection
- [ ] Define stable detection response schema
- [ ] Benchmark latency, FPS, and confidence

## Phase 4 — context and prioritization

- [ ] Add tracking
- [ ] Represent frame position and path relevance
- [ ] Implement priority scoring
- [ ] Add persistence and alert cooldowns
- [ ] Add unit tests with deterministic observations

## Phase 5 — audio accessibility

- [ ] Add concise message generation
- [ ] Add mobile text-to-speech
- [ ] Add repeat suppression and interruption rules
- [ ] Add accessibility settings for speech rate, verbosity, and vibration

## Phase 6 — backend and persistence

- [ ] Add Spring Boot service
- [ ] Add authentication through a managed identity approach
- [ ] Add MySQL schema and migrations
- [ ] Store users, preferences, devices, sessions, events, alerts, and model versions
- [ ] Add REST and WebSocket contracts

## Phase 7 — first end-to-end loop

- [ ] Connect mobile to AI service
- [ ] Connect mobile/backend session lifecycle
- [ ] Save a prioritized event
- [ ] Speak one useful message
- [ ] Show the event in the dashboard

## Phase 8 — dashboard

- [ ] Add React dashboard shell
- [ ] Add session and event history
- [ ] Add alert/object/session/latency analytics
- [ ] Add AI health, model versions, and development diagnostics
- [ ] Add privacy-aware location visualization only when enabled

## Phase 9 — advanced perception

- [ ] Add OCR for selected text
- [ ] Add relative depth estimation
- [ ] Evaluate scene descriptions on selected frames
- [ ] Decide whether edge inference is practical

## Phase 10 — navigation and delivery

- [ ] Add GPS/navigation experiments with explicit permission
- [ ] Add indoor/outdoor evaluation notes
- [ ] Add Docker Compose where practical
- [ ] Add CI checks
- [ ] Measure false positives and false negatives on a labeled validation set
- [ ] Prepare APK/AAB, report, presentation, demo script, and viva question bank

## Milestone rule

After each milestone:

1. keep the repository runnable,
2. run the relevant checks,
3. commit with a meaningful message,
4. push when GitHub authentication is available,
5. explain what changed, what was learned, and what comes next.