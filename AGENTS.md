# Ritmo agent guide

These instructions apply to the whole repository.

## Project shape

Ritmo is a native AppKit menu-bar app for macOS 14 or newer. It is written in Objective-C, uses ARC, and depends only on Apple frameworks. The project intentionally builds with shell scripts and Clang instead of an Xcode project.

- `Native/` contains the application, model, calculation core, and core tests.
- `support/Info.plist` defines the app bundle.
- `scripts/build-app.sh` creates `dist/Ritmo.app`.
- `scripts/test-core.sh` compiles and runs the calculation tests.
- `.github/workflows/release.yml` creates GitHub Releases from `v*` tags.

Do not commit generated files from `dist/`, `.build/`, or `.build-native/`.

## Working rules

- Keep the minimum deployment target at macOS 14 unless the task explicitly changes compatibility.
- Keep release binaries universal for both `arm64` and `x86_64`.
- Preserve the bundle identifier `io.github.ghdominguez.ritmo`. `NSUserDefaults` uses this identifier as its preferences domain, so changing it makes existing settings appear to reset.
- Keep calculation logic in `RitmoCore` independent of AppKit. Add or update cases in `Native/RitmoCoreTests.m` when calculation behavior changes.
- Keep persisted budget and calendar exceptions compatible with the existing `NSUserDefaults` keys in `RitmoModel.m` unless a migration is part of the change.
- Keep user-facing copy in Spanish.
- Do not add third-party dependencies or an Xcode project unless the requested change needs them.
- Ad-hoc signing is intentional. Do not add certificates, notarization credentials, or signing secrets.

## Validation

Run the core tests after code changes:

```bash
./scripts/test-core.sh
```

Build the application after changes that affect source code, packaging, or the property list:

```bash
./scripts/build-app.sh
```

The build must produce `dist/Ritmo.app` with a valid ad-hoc signature and both supported architectures.

## Releases

Pushing a tag such as `v1.0.1` runs the release workflow. The workflow tests the code, sets the bundle version from the tag, builds the universal app, and publishes a ZIP.

Do not create or push a release tag unless the user explicitly asks for a release. Source changes alone should not modify an existing release tag.
