# Learning guide

VisionAssist is both a capstone build and a guided engineering course. Each major technology is introduced in the same order.

## Teaching pattern

Before a technology:

1. **What is it?**
2. **Why do we need it?**
3. **Where does it fit in VisionAssist?**
4. **How does it work at a high level?**
5. **How do we install and verify it?**

After implementation:

1. explain the important files, classes, and functions,
2. trace one request or event through the system,
3. explain the commands before asking the learner to run them,
4. diagnose actual logs instead of guessing,
5. record tests and the Git commit.

## Concepts taught by phase

| Phase | Concepts |
| --- | --- |
| Foundation | Git, repositories, commits, branches, documentation, safety boundaries |
| Mobile | Flutter, Dart, Android SDK, permissions, camera lifecycle, accessibility |
| AI | Python environments, OpenCV, model inference, tensors, confidence, benchmarking |
| Decision engine | data modeling, scoring, temporal persistence, cooldowns, unit testing |
| Audio | text-to-speech, concise language, interruption and accessibility controls |
| Backend | Java, Spring Boot, HTTP, JSON, authentication, validation, WebSockets |
| Database | relational modeling, migrations, indexes, retention and minimization |
| Dashboard | React, TypeScript, API clients, state, charts, diagnostics |
| Delivery | Docker, environment variables, CI, device testing, evaluation reports |

## How to read the project

Start at the user-visible loop, then follow the data:

```text
screen action
  -> request or frame
  -> structured response
  -> decision
  -> audio/event
  -> persistence
  -> history/analytics
```

The project should never hide model behavior behind a single “magic AI” function. Each boundary should have a clear input, output, failure mode, and test.

## First lesson: why not train a model first?

Custom training is postponed because a trained model does not prove the product loop. The first goal is to measure whether a frame can travel through inference, prioritization, speech, persistence, and dashboard history. Pretrained models let us test that loop early; only then can a custom dataset be justified by measured failure cases.