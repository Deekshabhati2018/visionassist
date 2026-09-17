# VisionAssist

VisionAssist is an assistive Android capstone prototype for visually impaired users. It combines camera input, computer vision, context-aware prioritization, and concise audio guidance with a backend event history and web dashboard.

> **Safety boundary:** VisionAssist is not a certified mobility aid and must not be treated as guaranteed collision avoidance. It avoids face recognition and does not store raw camera video by default.

## What is being built

```text
Android camera
    -> AI service: detection, tracking, OCR, depth
    -> decision engine: context, persistence, risk, alert throttling
    -> mobile text-to-speech
    -> backend: users, preferences, sessions, events
    -> dashboard: history, analytics, service health
```

The first meaningful demo is intentionally small:

```text
Start Assistance -> test frame -> detection -> priority decision
-> one spoken message -> saved event -> dashboard history
```

## Repository map

| Area | Purpose | Status |
| --- | --- | --- |
| `mobile/` | Flutter Android application | Shell + camera preview milestone |
| `ai-service/` | Python computer-vision service | Foundation placeholder |
| `backend/` | Spring Boot API | Foundation placeholder |
| `web-dashboard/` | React dashboard | Foundation placeholder |
| `infra/` | Docker and local infrastructure | Foundation placeholder |
| `docs/` | Architecture, setup, roadmap, and learning material | Foundation milestone |
| `artifacts/api-server/` | Current Replit Express health API | Runnable scaffold |
| `lib/api-spec/` | Current OpenAPI contract | Health endpoint only |

## Current development shell

This Replit workspace uses pnpm workspaces and currently runs:

```bash
pnpm --filter @workspace/api-server run dev
pnpm run typecheck
pnpm run build
```

The current API health check is available through the preview at `GET /api/healthz`.

## Getting started

Read these in order:

1. [`docs/setup.md`](docs/setup.md) — toolchain verification and installation order
2. [`docs/architecture.md`](docs/architecture.md) — service boundaries and data flow
3. [`docs/roadmap.md`](docs/roadmap.md) — milestone order
4. [`docs/learning-guide.md`](docs/learning-guide.md) — how each technology will be taught
5. [`docs/development-checklist.md`](docs/development-checklist.md) — definition of done

## Git workflow

Use small, meaningful commits such as:

```text
docs: establish VisionAssist foundation
feat(mobile): add camera permission flow
feat(ai): add pretrained detection endpoint
test(decision): cover alert prioritization
```

Never commit `.env` files, passwords, API keys, tokens, private keys, generated credentials, or raw camera data.