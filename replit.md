# VisionAssist

VisionAssist is an accessibility-first Android prototype that turns camera observations into prioritized spoken guidance, with a backend event history and development dashboard.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env for the current scaffold: none
- The backend currently exposes `GET /api/healthz`; the database is intentionally not connected in the foundation milestone.

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)
- Planned services: Flutter mobile app, Python AI service, Spring Boot backend, MySQL persistence, and React dashboard. These are introduced one milestone at a time.

## Where things live

- `docs/` — source-of-truth project brief, architecture, setup, roadmap, checklist, and learning guide
- `lib/api-spec/openapi.yaml` — source-of-truth HTTP contract for the current API scaffold
- `artifacts/api-server/` — current Express health API used by the Replit preview
- `artifacts/mockup-sandbox/` — reusable UI preview surface
- `mobile/` — reserved for the Flutter Android application
- `ai-service/` — reserved for the Python computer-vision service
- `backend/` — reserved for the Spring Boot application
- `web-dashboard/` — reserved for the React dashboard
- `infra/` — reserved for Docker Compose and local infrastructure

## Architecture decisions

- Pretrained inference comes before custom training so the end-to-end loop can be measured before model work expands.
- Raw camera frames are not stored by default; the system records minimal event metadata instead.
- The decision engine is a separate boundary from model inference so risk policy can be tested independently of model vendors.
- The current workspace scaffold remains the development shell; planned services are added incrementally rather than replacing it.

## Product

The target loop is: camera frame → object detection/tracking → context and priority evaluation → concise text-to-speech alert → persisted event → dashboard history. VisionAssist is an assistive prototype, not a certified safety device.

## User preferences

- Teach each major technology before using it, then explain the important files and data flow after each milestone.
- Keep meaningful progress synchronized to GitHub when authentication is available.

## Gotchas

- Do not claim guaranteed collision avoidance or present uncertain predictions as facts.
- Do not add face recognition or raw video storage to the default design.
- Run the workspace typecheck before committing changes that affect TypeScript packages.
- Regenerate API clients after changing `lib/api-spec/openapi.yaml`.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
- See `docs/roadmap.md` for milestone order and `docs/learning-guide.md` for the teaching format
