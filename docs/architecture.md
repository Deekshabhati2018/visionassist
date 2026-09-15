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
3. A frame or selected frame sample is sent to the AI service.
4. The AI service returns structured observations: class, confidence, bounding box, tracking identity, and optional relative depth.
5. The decision engine adds frame position, persistence, path relevance, motion, and recent-alert context.
6. A high-priority event becomes a short spoken message and a minimal event record.
7. The backend stores the event and session metadata.
8. The dashboard reads event history and aggregate analytics.

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

- `POST /inference/detect`
- `POST /inference/depth`
- `POST /inference/ocr`
- `POST /inference/scene`
- `POST /decision/evaluate`
- `GET /health`

The current workspace OpenAPI contract only contains the health endpoint. We will expand it when the first real backend contract is implemented, then regenerate clients before using new generated types.

## Privacy and safety constraints

- Do not store raw camera frames or video by default.
- Avoid face recognition.
- Request camera, microphone, and location permissions explicitly and only when needed.
- Minimize location retention and make it controllable.
- Do not state an uncertain prediction as a fact.
- Log service diagnostics without logging private image content.
- Label the product as an assistive prototype in the app and dashboard.