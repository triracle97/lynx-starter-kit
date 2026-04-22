# Lynx Template — Design

**Date:** 2026-04-22
**Status:** Approved (brainstorming)
**Target:** Git-clone starter for cross-platform Lynx apps (iOS + Android + Web) with a React Native–style repo layout.

## 1. Goals & Non-Goals

### Goals
- Zero-to-running Lynx app on iOS, Android, and Web from a single `git clone`.
- RN-like flat repo layout: `ios/`, `android/`, `web/`, `src/` at root.
- Swift host on iOS, Kotlin host on Android.
- Android 7.0+ (`minSdkVersion 24`); iOS 12+.
- ReactLynx (`@lynx-js/react`) for JS, `react-router` memory routing for navigation.
- RN-style dev/release bundle loading: LAN dev server in Debug, embedded bundle in Release.
- pnpm package manager.
- TypeScript strict, ESLint, Prettier, Vitest (JS smoke tests only).
- One demo flow: `Hello` landing → navigate to `Counter` screen.

### Non-Goals
- No `create-lynx-app` CLI scaffolder (git-clone + find/replace only).
- No monorepo / workspaces.
- No example native module (user adds as needed).
- No bundled state manager, data fetcher, i18n, or theming.
- No native test scaffolding (XCTest, Android instrumentation).
- No CI workflow files shipped (README documents expected CI steps).

## 2. Repo Layout

```
lynx-template/
├── android/                         # Gradle app module, Kotlin host
├── ios/                             # Xcode project + Podfile, Swift host
├── web/                             # Static host shell
│   ├── index.html
│   └── main.ts                      # `import '@lynx-js/web-core'`
├── src/                             # ReactLynx app
│   ├── index.tsx                    # ReactLynx root registration
│   ├── App.tsx                      # MemoryRouter + Routes
│   ├── routes/
│   │   ├── Hello.tsx
│   │   └── Counter.tsx
│   └── styles.ts
├── scripts/
│   ├── dev-ip.cjs                   # print LAN bundle URL
│   └── embed-bundle.cjs             # copy dist bundles into native assets
├── docs/superpowers/specs/          # this file
├── lynx.config.ts                   # rspeedy config (lynx + web envs)
├── package.json
├── pnpm-lock.yaml
├── tsconfig.json
├── vitest.config.ts
├── .eslintrc.cjs
├── .prettierrc
├── .gitignore
├── .nvmrc                           # Node 20
└── README.md
```

## 3. JS / ReactLynx Application

### Dependencies (runtime)
- `@lynx-js/rspeedy`
- `@lynx-js/react`
- `@lynx-js/react-rsbuild-plugin`
- `@lynx-js/web-core`
- `react-router` (memory routing — Lynx does not support browser History API on native)

### Dependencies (dev)
- `typescript`
- `eslint`, `@typescript-eslint/{parser,eslint-plugin}`, `eslint-plugin-react`, `eslint-plugin-react-hooks`
- `prettier`
- `vitest`, `jsdom`, `@testing-library/react`
- `@types/react`

### Entry & routing
- `src/index.tsx` — ReactLynx root registration with `<App/>`.
- `src/App.tsx`:
  ```tsx
  <MemoryRouter>
    <Routes>
      <Route path="/" element={<Hello/>} />
      <Route path="/counter" element={<Counter/>} />
    </Routes>
  </MemoryRouter>
  ```
- Navigation: `useNavigate()` from `react-router`. No `<Link>` (not supported in ReactLynx per upstream docs).

### Screens
- **`Hello.tsx`** — `<view>` + `<text>` "Hello Lynx" + tappable link (`bindtap` on a `<view>`) that calls `nav('/counter')`.
- **`Counter.tsx`** — `useState`-backed counter with `+` / `−` buttons and a back link via `nav(-1)`.

### Primitives used
`<view>`, `<text>`, `bindtap` event. Inline style objects.

## 4. Build System (rspeedy)

`lynx.config.ts` defines two environments:

```ts
import { defineConfig } from '@lynx-js/rspeedy'
import { pluginReactLynx } from '@lynx-js/react-rsbuild-plugin'

export default defineConfig({
  plugins: [pluginReactLynx()],
  source: { entry: { main: './src/index.tsx' } },
  environments: {
    lynx: {}, // native target (iOS + Android)
    web: {
      source: { entry: { main: './web/main.ts' } },
      output: { target: 'web' },
      html: { template: './web/index.html' }
    }
  }
})
```

Bundle outputs:
- `dist/main.lynx.bundle` — native (iOS + Android share)
- `dist/main.web.bundle` + `dist/web/index.html` — web

### npm scripts
```json
{
  "dev":          "rspeedy dev",
  "dev:ip":       "node scripts/dev-ip.cjs",
  "build":        "rspeedy build",
  "build:native": "rspeedy build --env lynx",
  "build:web":    "rspeedy build --env web",
  "embed":        "node scripts/embed-bundle.cjs",
  "release":      "pnpm build && pnpm embed",
  "lint":         "eslint src",
  "test":         "vitest run",
  "typecheck":    "tsc --noEmit"
}
```

## 5. iOS Host (Swift)

### Layout
```
ios/
├── Podfile
├── LynxTemplate.xcodeproj
└── LynxTemplate/
    ├── AppDelegate.swift
    ├── SceneDelegate.swift
    ├── ViewController.swift
    ├── TemplateProvider.swift
    ├── Info.plist
    ├── bundle/main.lynx.bundle      # release (gitignored)
    └── Assets.xcassets/
```

### Podfile
```ruby
platform :ios, '12.0'
target 'LynxTemplate' do
  use_frameworks!
  pod 'Lynx',               '3.6.0', subspecs: ['Framework']
  pod 'PrimJS',             '3.6.1', subspecs: ['quickjs', 'napi']
  pod 'LynxService',        '3.6.0', subspecs: ['Image', 'Log', 'Http']
  pod 'SDWebImage',         '5.15.5'
  pod 'SDWebImageWebPCoder','0.11.0'
end
```

### Initialization
`AppDelegate.application(_:didFinishLaunchingWithOptions:)` calls `LynxEnv.sharedInstance()` (triggers singleton init).

### ViewController
```swift
#if DEBUG
let bundleURL = "http://localhost:3000/main.lynx.bundle"
#else
let bundleURL = "embedded://main.lynx.bundle"
#endif
let view = LynxViewBuilder()
    .setTemplateProvider(TemplateProvider())
    .build()
view.loadTemplate(fromURL: bundleURL, initData: nil)
```

### TemplateProvider
Implements `LynxTemplateProvider`. If url scheme is `http(s)` → `URLSession.shared.dataTask`. Else → load bytes from `Bundle.main.url(forResource: "main.lynx", withExtension: "bundle")`.

### Configuration caveats (documented in README)
- Xcode build setting **User Script Sandboxing → NO** (required by Lynx CocoaPods scripts).
- `Info.plist`: `NSAppTransportSecurity` with both `NSAllowsLocalNetworking = YES` (for LAN IP on device) and an `NSExceptionDomains` entry for `localhost` with `NSTemporaryExceptionAllowsInsecureHTTPLoads = YES` (for simulator). Debug only; Release build does not hit network.
- Physical device: swap `localhost` for LAN IP printed by `pnpm dev:ip`.

## 6. Android Host (Kotlin)

### Layout
```
android/
├── build.gradle
├── settings.gradle
├── gradle.properties                # android.useAndroidX=true
├── gradle/wrapper/...
└── app/
    ├── build.gradle                 # minSdk 24, compileSdk 34
    ├── proguard-rules.pro
    └── src/
        ├── main/
        │   ├── AndroidManifest.xml
        │   ├── java/com/example/lynxtemplate/
        │   │   ├── LynxApp.kt
        │   │   ├── MainActivity.kt
        │   │   └── TemplateProvider.kt
        │   ├── assets/main.lynx.bundle   # release (gitignored)
        │   └── res/...
        └── debug/
            ├── AndroidManifest.xml        # usesCleartextTraffic=true
            └── res/xml/network_security_config.xml
```

### Gradle config
- AGP 8.x, Kotlin 1.9.x, Gradle 8.x
- `compileSdk 34`, `targetSdk 34`, `minSdk 24`
- `android.useAndroidX=true` in `gradle.properties`

### Dependencies (`app/build.gradle`)
```gradle
implementation 'org.lynxsdk.lynx:lynx:3.6.0'
implementation 'org.lynxsdk.lynx:lynx-jssdk:3.6.0'
implementation 'org.lynxsdk.lynx:lynx-trace:3.6.0'
implementation 'org.lynxsdk.lynx:primjs:3.6.1'
implementation 'com.facebook.fresco:fresco:2.3.0'
```

### LynxApp.kt
```kotlin
class LynxApp : Application() {
  override fun onCreate() {
    super.onCreate()
    LynxEnv.inst().init(this, null, null, null)
    LynxServiceCenter.inst().registerService(LynxImageService.getInstance())
    LynxServiceCenter.inst().registerService(LynxLogService.getInstance())
    LynxServiceCenter.inst().registerService(LynxHttpService.getInstance())
  }
}
```

### MainActivity.kt
```kotlin
val url = if (BuildConfig.DEBUG) "http://10.0.2.2:3000/main.lynx.bundle"
          else "embedded://main.lynx.bundle"
val lynx = LynxViewBuilder()
    .setTemplateProvider(TemplateProvider(this))
    .build(this)
setContentView(lynx)
lynx.renderTemplateUrl(url, "")
```

### TemplateProvider.kt
Extends `AbsTemplateProvider`. `http(s)` → `HttpURLConnection` (JDK built-in, no extra dep). Else → `assets.open("main.lynx.bundle")`. Runs off main thread via `Executors.newSingleThreadExecutor()`.

### ProGuard rules
Standard Lynx keep rules from the official docs — keep classes extending `com.lynx.tasm.behavior.ui.LynxBaseUI`, classes implementing `LynxModule`, `@Keep`-annotated members, native methods.

### Debug-only network config
`src/debug/AndroidManifest.xml` adds `android:usesCleartextTraffic="true"` and references `@xml/network_security_config` permitting `10.0.2.2` and `192.168.0.0/16`, `10.0.0.0/8` for LAN dev. Release manifest is untouched.

### Caveats (documented)
- Emulator: `10.0.2.2:3000`.
- Physical device: swap to LAN IP in `MainActivity.kt`.

## 7. Web Host

### Layout
```
web/
├── index.html
└── main.ts       # `import '@lynx-js/web-core'`
```

### `web/index.html`
```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>LynxTemplate</title>
    <style>html,body,lynx-view{margin:0;height:100vh;width:100vw}</style>
  </head>
  <body>
    <lynx-view url="/main.web.bundle"></lynx-view>
  </body>
</html>
```

### Hot reload
Rely on rsbuild dev server's built-in live-reload (full page refresh on bundle change). True HMR for `<lynx-view>` is tracked upstream at <https://github.com/lynx-family/lynx-stack/issues/140>. README documents the gap and promises an upgrade when the feature ships.

### Dev command
`pnpm rspeedy dev --env web` serves `:3001`.

## 8. Dev Workflow

| Target | Command | Bundle source |
|---|---|---|
| iOS simulator | Xcode run (Debug scheme) | `http://localhost:3000/main.lynx.bundle` |
| iOS device | Xcode run (Debug), edit `devHost` const | `http://<lan>:3000/main.lynx.bundle` |
| Android emulator | Android Studio run (Debug) | `http://10.0.2.2:3000/main.lynx.bundle` |
| Android device | Android Studio run (Debug), edit url const | `http://<lan>:3000/main.lynx.bundle` |
| Web | `pnpm rspeedy dev --env web` | rspeedy dev server `:3001` |

Prereq for all native targets: `pnpm dev` running (rspeedy native dev server). Port defaults to rspeedy's built-in (typically `:3000`); if the running rspeedy version picks a different port, update the `devHost`/`url` constants in `ViewController.swift` and `MainActivity.kt` accordingly.

## 9. Release Workflow

1. `pnpm release` — runs `rspeedy build` then `scripts/embed-bundle.cjs` to copy `dist/main.lynx.bundle` into `ios/LynxTemplate/bundle/` and `android/app/src/main/assets/`.
2. iOS: Xcode **Archive** → distribute.
3. Android: `cd android && ./gradlew assembleRelease`.
4. Web: deploy `dist/web/` to any static host.

## 10. Tooling

### `tsconfig.json`
`strict: true`, `jsx: react-jsx`, `moduleResolution: bundler`, `target: ES2022`, include `src/**/*`.

### ESLint
Flat config `.eslintrc.cjs` with `@typescript-eslint`, `eslint-plugin-react`, `eslint-plugin-react-hooks`. `src/` only.

### Prettier
Defaults: 2-space, single quotes, trailing commas.

### Vitest
`vitest.config.ts` with jsdom. Excludes `android/`, `ios/`, `web/`, `dist/`. One smoke test: `src/App.test.tsx` renders `<App/>` without throwing.

### `.gitignore`
```
node_modules/
dist/
# iOS
ios/Pods/
ios/build/
ios/LynxTemplate/bundle/
*.xcuserstate
# Android
android/.gradle/
android/build/
android/app/build/
android/app/src/main/assets/main.lynx.bundle
android/local.properties
# macOS
.DS_Store
```

### `.nvmrc`
`20`

## 11. Placeholder Names (user renames on clone)

| Placeholder | Default |
|---|---|
| App display name | `LynxTemplate` |
| iOS bundle id | `com.example.lynxtemplate` |
| Android application id | `com.example.lynxtemplate` |
| Android Kotlin pkg | `com.example.lynxtemplate` |
| npm package name | `lynx-template` |

README documents a single find/replace pass over these strings.

## 12. Verification

### Automated (what CI would run)
- `pnpm install`
- `pnpm typecheck`
- `pnpm lint`
- `pnpm test` (one smoke test: `App` renders)
- `pnpm build` (emits both bundles)
- `cd ios && pod install && xcodebuild -scheme LynxTemplate -sdk iphonesimulator build`
- `cd android && ./gradlew assembleDebug`
- `rspeedy build --env web` (emits `dist/web/index.html`)

### Manual runtime smoke
- iOS simulator: app launches → "Hello Lynx" → tap link → counter works → back link returns.
- Android emulator: same.
- Web browser: `pnpm rspeedy dev --env web` → `http://localhost:3001` → same flow.

## 13. README Outline

1. Prereqs — Node 20, pnpm, Xcode 15+, Android Studio Hedgehog+, Ruby + CocoaPods ≥1.11.3, JDK 17.
2. Clone & rename — find/replace table.
3. Install — `pnpm install`; `cd ios && pod install`.
4. Dev loop per platform (simulator + physical device, with LAN-IP instructions).
5. Release build.
6. Known gaps — web HMR (upstream issue #140), physical-device URL edit, iOS User Script Sandboxing toggle.
7. Pointers — official Lynx integration docs for iOS / Android / Web.

## 14. Open Risks / Follow-ups

- **Web HMR:** falls back to page reload until `lynx-family/lynx-stack#140` ships. Replace with true HMR afterwards.
- **Lynx version pins:** frozen at 3.6.0 / PrimJS 3.6.1. Bump path: change Podfile, `app/build.gradle`, `package.json` in lockstep.
- **LAN IP ergonomics:** manual edit per device. Can be automated later via a run-script phase that emits a `DevHost.swift` / `BuildConfig` field from `scripts/dev-ip.cjs`; deliberately out of scope for v1 to keep native code hand-readable.
- **Android image service:** Fresco pulled in by default for images; if a consumer app ships a different image stack they can swap `LynxImageService` per Lynx docs.
