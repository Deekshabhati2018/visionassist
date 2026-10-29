# VisionAssist architecture

## Product boundary

VisionAssist helps a user understand nearby visual context through short, prioritized audio messages. It is an assistive prototype, not a certified safety device. The system must communicate uncertainty and must not claim guaranteed collision avoidance.

## Target service graph

```text
┌──────────────────────┐
│ Flutter Android app  │
│ camera, permissions, │
│ GPS, voice, TTS      │
└──────────┬───────────┘
           │ frames / commands
           ▼
┌──────────────────────┐       ┌──────────────────────┐
│ Python AI service    │──────▶│ Decision engine      │
│ detection, tracking, │       │ risk, context,       │
│ depth, OCR, scene    │       │ persistence, cooldown│
└──────────────────────┘       └──────────┬───────────┘
                                          │ event + alert
                         ┌────────────────┴──────────────┐
                         ▼                               ▼
               ┌──────────────────┐             ┌──────────────────┐
               │ Mobile TTS/audio │             │ Spring Boot API  │
               └──────────────────┘             │ auth, sessions,  │
                                                │ events, analytics │
                                                └────────┬─────────┘
                                                         │
                                                         ▼
                                                ┌──────────────────┐
                                                │ MySQL            │
                                                │ minimized event  │
                                                │ metadata         │
                                                └────────┬─────────┘
                                                         │ REST/WebSocket
                                                         ▼
                                                ┌──────────────────┐
                                                │ React dashboard  │
                                                │ history, health, │
                                                │ diagnostics      │
                                                └──────────────────┘
```

## Why the decision engine is separate

Model output answers “what might be visible.” The decision engine answers “what deserves the user's attention now.” Keeping those responsibilities separate makes it possible to:

- test alert policy without running a neural network,
- replace YOLO, OCR, or depth models independently,
- account for persistence, movement, position, confidence, and recent announcements,
- measure false positives and alert frequency as product behavior.

The initial conceptual score is:

```text
priority =
  class_risk
  × proximity_factor
  × path_factor
  × motion_factor
  × confidence_factor
```

The implementation must also apply alert cooldowns and persistence windows. It must not announce every raw detection.

## Data flow

1. The mobile app requests explicit camera permission.
2. Assistance starts only after the user activates it.
3. A captured frame or selected continuous sample is sent to the AI service. Sampling is configurable and requests do not overlap.
4. The AI service returns structured observations: class, confidence, and pixel-coordinate bounding box.
5. The mobile app combines labels into a concise factual scene summary. It does not infer distance, approach, path relevance, or danger from ordinary boxes.
6. Mobile text-to-speech announces new summaries with repeat suppression; the user can replay, mute, adjust rate/volume, pause, or stop.
7. A future decision engine may add persistence, path relevance, motion, and recent-alert context after those capabilities are implemented and validated.
8. The backend can later store event and session metadata; the current mobile AI milestone does not persist camera frames or detection history.
9. The dashboard reads event history and aggregate analytics when backend persistence is implemented.

## Planned API boundaries

### Mobile/backend API

- authentication and current-user profile
- preferences and accessibility settings
- assistance-session lifecycle
- detection event submission
- session history and detail
- analytics summary
- health
- WebSocket assistance channel

### AI service API

- `POST /inference/detect` — one JPEG/PNG/WebP request body, versioned detections in pixel coordinates
- `POST /inference/depth`
- `POST /inference/ocr`
- `POST /inference/scene`
- `POST /decision/evaluate`
- `GET /health` — model readiness
- `GET /openapi.json` — generated AI-service contract

The AI service currently generates its own OpenAPI contract from its validated
FastAPI response models. The shared workspace OpenAPI contract is still for
the Express/Spring-style mobile backend and will be expanded as that backend
is implemented.

## Privacy and safety constraints

- Do not store raw camera frames or video by default.
- Avoid face recognition.
- Request camera, microphone, and location permissions explicitly and only when needed.
- Minimize location retention and make it controllable.
- Do not state an uncertain prediction as a fact.
- Log service diagnostics without logging private image content.
- Label the product as an assistive prototype in the app and dashboard.