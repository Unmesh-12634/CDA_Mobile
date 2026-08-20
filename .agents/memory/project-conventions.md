---
type: project
created: 2026-05-25
updated: 2026-05-25
---

# Project Conventions

## Git & Release Workflow
- Always create a new dedicated branch for major code changes.
- Branch name format should follow: `feature/[task-slug]` or `fix/[bug-slug]`.
- **Version Updates**: Always bump the version in `frontend/pubspec.yaml` and create a **brand new unique incremental Git tag** (e.g. `v2.9.1`, `v2.9.2`, `v3.0.0`) and push it to GitHub with `git push origin [tag]` every time the user asks for a version update or APK release. Never reuse/force-push old tags.
