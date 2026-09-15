# Development checklist

## Foundation

- [x] Repository name and purpose are documented
- [x] Target service boundaries are documented
- [x] Safety and privacy boundaries are documented
- [x] Setup and installation order are documented
- [x] Teaching format is documented
- [x] Milestone roadmap exists
- [ ] Local toolchain verification is complete

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