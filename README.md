# Lynx Template

RN-style starter for building Lynx apps on iOS, Android (7+), and Web from one codebase.

## Prereqs

- Node 20 (`nvm use`)
- pnpm 9 (`corepack enable`)
- Xcode 15+ and CocoaPods ≥ 1.11.3 (`brew install cocoapods xcodegen`)
- Android Studio Hedgehog+ with API 34 SDK and an API 24+ emulator
- JDK 17

## Clone + rename

1. `git clone <url> my-app && cd my-app`
2. Find/replace across the repo (use your editor's project-wide replace):
   - `LynxTemplate` → `MyApp`
   - `com.example.lynxtemplate` → `com.mycompany.myapp`
   - `lynx-template` → `my-app`
3. `cd ios && xcodegen generate && cd ..` (regenerates the xcodeproj under new name)

## Install

```bash
pnpm install
cd ios && pod install && cd ..
```

## Dev loop

In one terminal:

```bash
pnpm dev          # rspeedy native dev server
```

### iOS

- Simulator: open `ios/LynxTemplate.xcworkspace`, Run. Fetches bundle from `http://localhost:3000`.
- Physical device: edit `devHost` in `ios/LynxTemplate/ViewController.swift` to the IP printed by `pnpm dev:ip`.

### Android

- Emulator: open `android/` in Android Studio, Run. Fetches from `http://10.0.2.2:3000`.
- Physical device: edit the `http://...` URL in `android/app/src/main/java/com/example/lynxtemplate/MainActivity.kt` to the `pnpm dev:ip` output.

### Web

```bash
pnpm dev:web      # rspeedy serves web host on :3001 with live-reload
```

True HMR for `<lynx-view>` is tracked upstream at <https://github.com/lynx-family/lynx-stack/issues/140>. This template falls back to full page reload until that ships.

## Release

```bash
pnpm release        # build both bundles + embed native bundle into ios/ and android/
```

- iOS: Xcode Archive → distribute.
- Android: `cd android && ./gradlew assembleRelease`.
- Web: deploy `dist/web/` to any static host.

## Known gaps

- Physical-device dev URL requires a one-line edit in Swift/Kotlin.
- iOS User Script Sandboxing must stay OFF (enforced by Podfile `post_install`).
- Web HMR is page-reload until lynx-stack#140 ships.
- Web host currently requires manual `<script>` wiring pending upstream fix for rspeedy html plugin.

## Docs

- iOS: <https://lynxjs.org/guide/start/integrate-with-existing-apps?platform=ios>
- Android: <https://lynxjs.org/guide/start/integrate-with-existing-apps?platform=android>
- Web: <https://lynxjs.org/guide/start/integrate-with-existing-apps?platform=web>
