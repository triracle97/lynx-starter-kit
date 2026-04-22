# Lynx Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a git-clone starter that launches the same ReactLynx app — "Hello Lynx" → Counter — on iOS (Swift), Android (Kotlin, 7+), and Web, with RN-style dev/release bundle flow.

**Architecture:** Flat RN-style repo. JS source in `src/` built by rspeedy into `dist/main.lynx.bundle` (native) and `dist/main.web.bundle` (web). Native hosts fetch bundle from LAN rspeedy dev server in Debug, embedded asset in Release. Web host is a static `index.html` that registers `<lynx-view>` via `@lynx-js/web-core`.

**Tech Stack:** pnpm, TypeScript 5 (strict), ReactLynx (`@lynx-js/react` + `@lynx-js/react-rsbuild-plugin`), `@lynx-js/rspeedy`, `@lynx-js/web-core`, `react-router` (memory), Vitest, ESLint, Prettier. iOS: Swift, CocoaPods, Lynx 3.6.0 / PrimJS 3.6.1, xcodegen to generate `.xcodeproj`. Android: Kotlin 1.9, Gradle 8.x, AGP 8.x, Lynx Android 3.6.0.

**Spec:** `docs/superpowers/specs/2026-04-22-lynx-template-design.md`.

**Pre-existing state:** repo already contains this plan and the spec under `docs/superpowers/`; a single root commit exists. All paths below are relative to the repo root `/Users/tran/Documents/triracle/Code/lynx-template`.

**Verification convention for native tasks:** Native code is not unit-tested (spec non-goal). Instead, every native task's "failing test" step is a build check run *before* the files exist (expected to fail) and a re-run *after* to prove it succeeds. This is TDD applied at the build-system level.

---

## Phase 1 — Repo Foundation (JS)

### Task 1: Root package.json + pnpm setup

**Files:**
- Create: `package.json`
- Create: `.nvmrc`
- Create: `.gitignore`

- [ ] **Step 1: Verify pnpm available**

Run: `pnpm --version`
Expected: a version ≥ 9.0.0. If missing, run `corepack enable && corepack prepare pnpm@latest --activate`.

- [ ] **Step 2: Write `.nvmrc`**

Create `.nvmrc`:
```
20
```

- [ ] **Step 3: Write `.gitignore`**

Create `.gitignore`:
```
node_modules/
dist/
.DS_Store

# iOS
ios/Pods/
ios/build/
ios/LynxTemplate/bundle/main.lynx.bundle
ios/LynxTemplate.xcodeproj/
*.xcuserstate
xcuserdata/

# Android
android/.gradle/
android/build/
android/app/build/
android/app/src/main/assets/main.lynx.bundle
android/local.properties
*.iml
```

- [ ] **Step 4: Write `package.json`**

Create `package.json`:
```json
{
  "name": "lynx-template",
  "version": "0.0.1",
  "private": true,
  "packageManager": "pnpm@9.12.0",
  "engines": { "node": ">=20" },
  "scripts": {
    "dev": "rspeedy dev",
    "dev:web": "rspeedy dev --environment web",
    "dev:ip": "node scripts/dev-ip.cjs",
    "build": "rspeedy build",
    "build:native": "rspeedy build --environment lynx",
    "build:web": "rspeedy build --environment web",
    "embed": "node scripts/embed-bundle.cjs",
    "release": "pnpm build && pnpm embed",
    "lint": "eslint src",
    "test": "vitest run",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@lynx-js/react": "^0.107.0",
    "@lynx-js/web-core": "^0.15.0",
    "react": "^17.0.2",
    "react-dom": "^17.0.2",
    "react-router": "^6.28.0"
  },
  "devDependencies": {
    "@lynx-js/react-rsbuild-plugin": "^0.10.0",
    "@lynx-js/rspeedy": "^0.9.0",
    "@testing-library/react": "^12.1.5",
    "@types/react": "^17.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint": "^9.0.0",
    "eslint-plugin-react": "^7.37.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "jsdom": "^25.0.0",
    "prettier": "^3.3.0",
    "typescript": "^5.6.0",
    "vitest": "^2.1.0"
  }
}
```

(Note: if the listed version is not yet published when the plan runs, bump to the nearest stable — do not downgrade below a 0.x line.)

- [ ] **Step 5: Install**

Run: `pnpm install`
Expected: pnpm creates `node_modules/` and `pnpm-lock.yaml`.

- [ ] **Step 6: Commit**

```bash
git add package.json pnpm-lock.yaml .nvmrc .gitignore
git commit -m "chore: scaffold pnpm + node engine"
```

---

### Task 2: TypeScript config

**Files:**
- Create: `tsconfig.json`

- [ ] **Step 1: Write failing typecheck**

Run: `pnpm typecheck`
Expected: FAIL with "File 'tsconfig.json' not found" or similar.

- [ ] **Step 2: Create `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "allowJs": false,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true
  },
  "include": ["src", "web", "scripts", "vitest.config.ts", "lynx.config.ts"],
  "exclude": ["node_modules", "dist", "android", "ios"]
}
```

- [ ] **Step 3: Re-run typecheck**

Run: `pnpm typecheck`
Expected: PASS (no source files yet — trivially passes).

- [ ] **Step 4: Commit**

```bash
git add tsconfig.json
git commit -m "chore: add tsconfig (strict)"
```

---

### Task 3: ESLint + Prettier

**Files:**
- Create: `.eslintrc.cjs`
- Create: `.prettierrc`
- Create: `.prettierignore`

- [ ] **Step 1: Write `.prettierrc`**

```json
{
  "semi": false,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2
}
```

- [ ] **Step 2: Write `.prettierignore`**

```
node_modules
dist
ios
android
pnpm-lock.yaml
```

- [ ] **Step 3: Write `.eslintrc.cjs`**

```js
/* eslint-env node */
module.exports = {
  root: true,
  env: { browser: true, es2022: true },
  parser: '@typescript-eslint/parser',
  parserOptions: { ecmaVersion: 'latest', sourceType: 'module', ecmaFeatures: { jsx: true } },
  plugins: ['@typescript-eslint', 'react', 'react-hooks'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
  ],
  settings: { react: { version: '17' } },
  rules: {
    'react/react-in-jsx-scope': 'off',
    '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
  },
  ignorePatterns: ['dist', 'node_modules', 'ios', 'android'],
}
```

- [ ] **Step 4: Verify lint runs (no sources yet → no output)**

Run: `pnpm lint`
Expected: exits 0 with "0 problems" or similar.

- [ ] **Step 5: Commit**

```bash
git add .eslintrc.cjs .prettierrc .prettierignore
git commit -m "chore: add eslint + prettier configs"
```

---

### Task 4: Vitest config

**Files:**
- Create: `vitest.config.ts`

- [ ] **Step 1: Write `vitest.config.ts`**

```ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['src/**/*.test.{ts,tsx}'],
    exclude: ['node_modules', 'dist', 'android', 'ios', 'web'],
  },
})
```

- [ ] **Step 2: Run vitest (no tests yet)**

Run: `pnpm test`
Expected: exits 0 with "No test files found" — this is OK.

- [ ] **Step 3: Commit**

```bash
git add vitest.config.ts
git commit -m "chore: add vitest config"
```

---

### Task 5: rspeedy config (lynx env only, web added later)

**Files:**
- Create: `lynx.config.ts`

- [ ] **Step 1: Write `lynx.config.ts` (native env only for now)**

```ts
import { defineConfig } from '@lynx-js/rspeedy'
import { pluginReactLynx } from '@lynx-js/react-rsbuild-plugin'

export default defineConfig({
  plugins: [pluginReactLynx()],
  source: {
    entry: { main: './src/index.tsx' },
  },
  environments: {
    lynx: {},
  },
})
```

- [ ] **Step 2: Sanity check build fails without entry file**

Run: `pnpm build:native`
Expected: FAIL — rspeedy cannot find `src/index.tsx`.

- [ ] **Step 3: Commit**

```bash
git add lynx.config.ts
git commit -m "chore: add rspeedy config (lynx env)"
```

---

### Task 6: JS entry + App shell (router skeleton)

**Files:**
- Create: `src/index.tsx`
- Create: `src/App.tsx`
- Create: `src/App.test.tsx`

- [ ] **Step 1: Write failing test**

Create `src/App.test.tsx`:
```tsx
import { render } from '@testing-library/react'
import App from './App'

test('App renders without throwing', () => {
  expect(() => render(<App />)).not.toThrow()
})
```

- [ ] **Step 2: Run test — expect fail**

Run: `pnpm test`
Expected: FAIL — `App` module not found.

- [ ] **Step 3: Write `src/App.tsx` (minimal, router with one empty route)**

```tsx
import { MemoryRouter, Routes, Route } from 'react-router'

export default function App() {
  return (
    <MemoryRouter>
      <Routes>
        <Route path="/" element={null} />
      </Routes>
    </MemoryRouter>
  )
}
```

- [ ] **Step 4: Write `src/index.tsx`**

```tsx
import { root } from '@lynx-js/react'
import App from './App'

root.render(<App />)
```

- [ ] **Step 5: Run test — expect pass**

Run: `pnpm test`
Expected: PASS.

- [ ] **Step 6: Run typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/index.tsx src/App.tsx src/App.test.tsx
git commit -m "feat: JS entry + App shell with MemoryRouter"
```

---

### Task 7: Hello screen

**Files:**
- Create: `src/routes/Hello.tsx`
- Create: `src/routes/Hello.test.tsx`
- Create: `src/styles.ts`
- Modify: `src/App.tsx`

- [ ] **Step 1: Write failing test**

Create `src/routes/Hello.test.tsx`:
```tsx
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { Hello } from './Hello'

test('Hello screen renders greeting and link', () => {
  render(
    <MemoryRouter>
      <Hello />
    </MemoryRouter>,
  )
  expect(screen.getByText('Hello Lynx')).toBeTruthy()
  expect(screen.getByText(/Go to Counter/)).toBeTruthy()
})
```

- [ ] **Step 2: Run test — expect fail**

Run: `pnpm test`
Expected: FAIL — `./Hello` module not found.

- [ ] **Step 3: Write `src/styles.ts`**

```ts
export const center = {
  flex: 1,
  alignItems: 'center' as const,
  justifyContent: 'center' as const,
}

export const link = { color: '#0066cc', fontSize: 18 }
```

- [ ] **Step 4: Write `src/routes/Hello.tsx`**

```tsx
import { useNavigate } from 'react-router'
import { center, link } from '../styles'

export function Hello() {
  const nav = useNavigate()
  return (
    <view style={center}>
      <text style={{ fontSize: 32, marginBottom: 24 }}>Hello Lynx</text>
      <view bindtap={() => nav('/counter')} style={{ padding: 12 }}>
        <text style={link}>Go to Counter →</text>
      </view>
    </view>
  )
}
```

- [ ] **Step 5: Wire into `src/App.tsx`**

Replace the empty `<Route path="/" element={null} />` with:
```tsx
<Route path="/" element={<Hello />} />
```

Add import at top:
```tsx
import { Hello } from './routes/Hello'
```

- [ ] **Step 6: Run test — expect pass**

Run: `pnpm test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/routes/Hello.tsx src/routes/Hello.test.tsx src/styles.ts src/App.tsx
git commit -m "feat: Hello screen"
```

---

### Task 8: Counter screen

**Files:**
- Create: `src/routes/Counter.tsx`
- Create: `src/routes/Counter.test.tsx`
- Modify: `src/App.tsx`

- [ ] **Step 1: Write failing test**

Create `src/routes/Counter.test.tsx`:
```tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { Counter } from './Counter'

test('Counter increments and decrements', () => {
  render(
    <MemoryRouter>
      <Counter />
    </MemoryRouter>,
  )
  expect(screen.getByText('0')).toBeTruthy()
  fireEvent.click(screen.getByText('+'))
  expect(screen.getByText('1')).toBeTruthy()
  fireEvent.click(screen.getByText('−'))
  expect(screen.getByText('0')).toBeTruthy()
})
```

- [ ] **Step 2: Run test — expect fail**

Run: `pnpm test`
Expected: FAIL — `./Counter` module not found.

- [ ] **Step 3: Write `src/routes/Counter.tsx`**

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router'
import { center, link } from '../styles'

export function Counter() {
  const [n, setN] = useState(0)
  const nav = useNavigate()
  return (
    <view style={center}>
      <text style={{ fontSize: 48, marginBottom: 16 }}>{n}</text>
      <view style={{ flexDirection: 'row', marginBottom: 24 }}>
        <view bindtap={() => setN(n - 1)} style={{ padding: 12 }}>
          <text style={{ fontSize: 28 }}>−</text>
        </view>
        <view bindtap={() => setN(n + 1)} style={{ padding: 12 }}>
          <text style={{ fontSize: 28 }}>+</text>
        </view>
      </view>
      <view bindtap={() => nav(-1)} style={{ padding: 12 }}>
        <text style={link}>← Back</text>
      </view>
    </view>
  )
}
```

**Note:** in jsdom tests `bindtap` is non-standard — the test uses `fireEvent.click` which dispatches a `click` event on the DOM node. ReactLynx on native uses `bindtap`; on web, `@lynx-js/web-core` maps tap → click. For the jsdom unit test, also wire an `onClick` alias so the click fires. Update the `+`, `−`, and back `<view>` elements to include BOTH handlers, e.g.:

```tsx
<view bindtap={() => setN(n + 1)} onClick={() => setN(n + 1)} style={{ padding: 12 }}>
```

(Do this for all three tappable views in Counter, and the one in Hello too if you want its test to be click-fire-able later.)

- [ ] **Step 4: Wire into `src/App.tsx`**

Add import:
```tsx
import { Counter } from './routes/Counter'
```
Add route inside `<Routes>`:
```tsx
<Route path="/counter" element={<Counter />} />
```

- [ ] **Step 5: Run tests — expect pass**

Run: `pnpm test`
Expected: PASS on all tests.

- [ ] **Step 6: Typecheck**

Run: `pnpm typecheck`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/routes/Counter.tsx src/routes/Counter.test.tsx src/App.tsx
git commit -m "feat: Counter screen with nav"
```

---

### Task 9: Update Hello to also expose onClick for tests

**Files:**
- Modify: `src/routes/Hello.tsx`

- [ ] **Step 1: Add onClick alias to tappable view in Hello**

Change:
```tsx
<view bindtap={() => nav('/counter')} style={{ padding: 12 }}>
```
to:
```tsx
<view bindtap={() => nav('/counter')} onClick={() => nav('/counter')} style={{ padding: 12 }}>
```

- [ ] **Step 2: Run tests**

Run: `pnpm test`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add src/routes/Hello.tsx
git commit -m "chore: mirror bindtap with onClick in Hello for test-env parity"
```

---

### Task 10: Verify native build produces bundle

**Files:** none changed.

- [ ] **Step 1: Build native bundle**

Run: `pnpm build:native`
Expected: PASS — `dist/main.lynx.bundle` (or equivalent filename rspeedy produces) is emitted. If rspeedy emits a different filename pattern (e.g. `dist/lynx/main.lynx.bundle`), note the exact path for use in Task 13 and the native fetch URLs.

- [ ] **Step 2: Confirm bundle file exists**

Run: `ls -la dist/`
Expected: a `*.lynx.bundle` file ≥ 10 KB present.

- [ ] **Step 3: Record exact filename**

If filename differs from `main.lynx.bundle`, update:
- `scripts/embed-bundle.cjs` (Task 13) to copy the correct filename.
- Native code URL constants in Task 19 and Task 27 to match.

No commit — this is a verification step.

---

## Phase 2 — Web Host

### Task 11: Web entry + HTML template + rspeedy web env

**Files:**
- Create: `web/index.html`
- Create: `web/main.ts`
- Modify: `lynx.config.ts`

- [ ] **Step 1: Create `web/main.ts`**

```ts
import '@lynx-js/web-core'
```

- [ ] **Step 2: Create `web/index.html`**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>LynxTemplate</title>
    <style>
      html, body { margin: 0; padding: 0; height: 100%; }
      lynx-view { display: block; width: 100vw; height: 100vh; }
    </style>
  </head>
  <body>
    <lynx-view url="/main.web.bundle"></lynx-view>
  </body>
</html>
```

- [ ] **Step 3: Update `lynx.config.ts` to add `web` env**

Replace the `environments` block with:
```ts
environments: {
  lynx: {},
  web: {
    source: { entry: { main: './web/main.ts' } },
    output: { target: 'web' },
    html: { template: './web/index.html' },
  },
},
```

- [ ] **Step 4: Build web bundle**

Run: `pnpm build:web`
Expected: `dist/web/index.html` and `dist/web/main.web.bundle` (or rspeedy's equivalent) are emitted. If the emitted HTML references a hashed JS filename different from `main.web.bundle`, that's fine — the `<lynx-view url>` attribute targets the Lynx bundle (produced separately) not the web host's own JS.

- [ ] **Step 5: Commit**

```bash
git add web/ lynx.config.ts
git commit -m "feat: add web host (index.html + web-core entry) + rspeedy web env"
```

---

## Phase 3 — Scripts

### Task 12: `scripts/dev-ip.cjs`

**Files:**
- Create: `scripts/dev-ip.cjs`

- [ ] **Step 1: Write the script**

```js
#!/usr/bin/env node
const os = require('os')
const port = process.env.LYNX_DEV_PORT || 3000
const nets = os.networkInterfaces()
for (const name of Object.keys(nets)) {
  for (const net of nets[name] || []) {
    if (net.family === 'IPv4' && !net.internal) {
      console.log(`http://${net.address}:${port}/main.lynx.bundle`)
      process.exit(0)
    }
  }
}
console.error('No non-internal IPv4 interface found. Connect to a network and retry.')
process.exit(1)
```

- [ ] **Step 2: Run it**

Run: `pnpm dev:ip`
Expected: prints a URL like `http://192.168.x.y:3000/main.lynx.bundle`.

- [ ] **Step 3: Commit**

```bash
git add scripts/dev-ip.cjs
git commit -m "chore: add dev-ip helper script"
```

---

### Task 13: `scripts/embed-bundle.cjs`

**Files:**
- Create: `scripts/embed-bundle.cjs`

- [ ] **Step 1: Write the script**

```js
#!/usr/bin/env node
const fs = require('fs')
const path = require('path')

const repo = path.resolve(__dirname, '..')
const src = path.join(repo, 'dist', 'main.lynx.bundle')
if (!fs.existsSync(src)) {
  console.error(`Bundle not found at ${src}. Run \`pnpm build:native\` first.`)
  process.exit(1)
}

const targets = [
  path.join(repo, 'ios', 'LynxTemplate', 'bundle', 'main.lynx.bundle'),
  path.join(repo, 'android', 'app', 'src', 'main', 'assets', 'main.lynx.bundle'),
]

for (const dest of targets) {
  fs.mkdirSync(path.dirname(dest), { recursive: true })
  fs.copyFileSync(src, dest)
  console.log(`Copied → ${dest}`)
}
```

- [ ] **Step 2: Run it**

Run: `pnpm embed`
Expected: copies bundle into `ios/LynxTemplate/bundle/` and `android/app/src/main/assets/`. Both target dirs are created if missing.

- [ ] **Step 3: Commit**

```bash
git add scripts/embed-bundle.cjs
git commit -m "chore: add embed-bundle script"
```

---

## Phase 4 — iOS Host

### Task 14: Podfile + xcodegen project.yml

**Files:**
- Create: `ios/Podfile`
- Create: `ios/project.yml`
- Create: `ios/LynxTemplate/Info.plist`
- Create: `ios/LynxTemplate/Assets.xcassets/Contents.json`
- Create: `ios/LynxTemplate/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Verify xcodegen is available**

Run: `which xcodegen`
Expected: a path. If missing, run `brew install xcodegen`.

- [ ] **Step 2: Write `ios/Podfile`**

```ruby
platform :ios, '12.0'

target 'LynxTemplate' do
  use_frameworks!

  pod 'Lynx',                '3.6.0', :subspecs => ['Framework']
  pod 'PrimJS',              '3.6.1', :subspecs => ['quickjs', 'napi']
  pod 'LynxService',         '3.6.0', :subspecs => ['Image', 'Log', 'Http']
  pod 'SDWebImage',          '5.15.5'
  pod 'SDWebImageWebPCoder', '0.11.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |c|
      c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      c.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
```

- [ ] **Step 3: Write `ios/project.yml` (xcodegen spec)**

```yaml
name: LynxTemplate
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: '12.0'
settings:
  base:
    SWIFT_VERSION: '5.9'
    ENABLE_USER_SCRIPT_SANDBOXING: 'NO'
targets:
  LynxTemplate:
    type: application
    platform: iOS
    sources:
      - path: LynxTemplate
    info:
      path: LynxTemplate/Info.plist
      properties:
        CFBundleDisplayName: LynxTemplate
        CFBundleShortVersionString: '0.0.1'
        CFBundleVersion: '1'
        UILaunchStoryboardName: ''
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
          UISceneConfigurations:
            UIWindowSceneSessionRoleApplication:
              - UISceneConfigurationName: Default
                UISceneDelegateClassName: $(PRODUCT_MODULE_NAME).SceneDelegate
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.lynxtemplate
        TARGETED_DEVICE_FAMILY: '1,2'
    dependencies: []
```

- [ ] **Step 4: Write `ios/LynxTemplate/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsLocalNetworking</key><true/>
    <key>NSExceptionDomains</key>
    <dict>
      <key>localhost</key>
      <dict>
        <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key><true/>
      </dict>
    </dict>
  </dict>
</dict>
</plist>
```

- [ ] **Step 5: Asset catalog stubs**

Create `ios/LynxTemplate/Assets.xcassets/Contents.json`:
```json
{ "info": { "version": 1, "author": "xcode" } }
```
Create `ios/LynxTemplate/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{ "images": [], "info": { "version": 1, "author": "xcode" } }
```

- [ ] **Step 6: Generate Xcode project**

```bash
cd ios && xcodegen generate && cd ..
```
Expected: `ios/LynxTemplate.xcodeproj` created.

- [ ] **Step 7: Commit**

```bash
git add ios/Podfile ios/project.yml ios/LynxTemplate/Info.plist ios/LynxTemplate/Assets.xcassets
git commit -m "feat(ios): scaffold Podfile + xcodegen spec + Info.plist"
```

---

### Task 15: iOS Swift sources (AppDelegate + SceneDelegate)

**Files:**
- Create: `ios/LynxTemplate/AppDelegate.swift`
- Create: `ios/LynxTemplate/SceneDelegate.swift`

- [ ] **Step 1: Write `AppDelegate.swift`**

```swift
import UIKit
import Lynx

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    _ = LynxEnv.sharedInstance()
    return true
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
  }
}
```

- [ ] **Step 2: Write `SceneDelegate.swift`**

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = ViewController()
    self.window = window
    window.makeKeyAndVisible()
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add ios/LynxTemplate/AppDelegate.swift ios/LynxTemplate/SceneDelegate.swift
git commit -m "feat(ios): AppDelegate init LynxEnv + SceneDelegate"
```

---

### Task 16: iOS TemplateProvider

**Files:**
- Create: `ios/LynxTemplate/TemplateProvider.swift`

- [ ] **Step 1: Write `TemplateProvider.swift`**

```swift
import Foundation
import Lynx

final class TemplateProvider: NSObject, LynxTemplateProvider {
  func loadTemplate(
    withUrl url: String,
    onComplete callback: @escaping LynxTemplateLoadBlock
  ) {
    if let remote = URL(string: url), let scheme = remote.scheme, scheme.hasPrefix("http") {
      URLSession.shared.dataTask(with: remote) { data, _, err in
        DispatchQueue.main.async {
          if let data = data {
            callback(data, nil)
          } else {
            callback(nil, err ?? NSError(domain: "TemplateProvider", code: -1))
          }
        }
      }.resume()
      return
    }

    if let local = Bundle.main.url(forResource: "main.lynx", withExtension: "bundle"),
       let data = try? Data(contentsOf: local) {
      callback(data, nil)
    } else {
      callback(nil, NSError(domain: "TemplateProvider", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "bundle not found"]))
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/LynxTemplate/TemplateProvider.swift
git commit -m "feat(ios): TemplateProvider (http + embedded)"
```

---

### Task 17: iOS ViewController (dev/release URL)

**Files:**
- Create: `ios/LynxTemplate/ViewController.swift`

- [ ] **Step 1: Write `ViewController.swift`**

```swift
import UIKit
import Lynx

final class ViewController: UIViewController {
  // Physical device dev: change "localhost" to the IP printed by `pnpm dev:ip`.
  private static let devHost = "localhost"
  private static let devPort = 3000

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    #if DEBUG
    let url = "http://\(Self.devHost):\(Self.devPort)/main.lynx.bundle"
    #else
    let url = "embedded://main.lynx.bundle"
    #endif

    let lynxView = LynxViewBuilder()
      .setTemplateProvider(TemplateProvider())
      .build()
    lynxView.frame = view.bounds
    lynxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(lynxView)
    lynxView.loadTemplate(fromURL: url, initData: nil)
  }
}
```

**Note:** `LynxViewBuilder`/`loadTemplate(fromURL:initData:)` names follow the spec extract of iOS docs. If the actual Swift signature differs at the pinned pod version (e.g. method takes `LynxLoadMeta`), call the equivalent — do not invent APIs, and adjust the plan's signature in this step rather than working around it in `TemplateProvider.swift`.

- [ ] **Step 2: Commit**

```bash
git add ios/LynxTemplate/ViewController.swift
git commit -m "feat(ios): ViewController with dev/release URL switch"
```

---

### Task 18: iOS Pod install + build verification

**Files:** none.

- [ ] **Step 1: Install pods**

```bash
cd ios && pod install && cd ..
```
Expected: `ios/LynxTemplate.xcworkspace` + `ios/Pods/` created. If `pod install` fails because the pinned pod version doesn't exist, re-open the spec + plan and bump to the nearest published 3.x version in lockstep in both the Podfile and the spec's version table before continuing.

- [ ] **Step 2: Build for iOS simulator**

```bash
xcodebuild \
  -workspace ios/LynxTemplate.xcworkspace \
  -scheme LynxTemplate \
  -sdk iphonesimulator \
  -configuration Debug \
  build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Manual simulator smoke (documented, not required by CI)**

- Start `pnpm dev` in one terminal.
- In Xcode, open `ios/LynxTemplate.xcworkspace`, pick an iPhone simulator, Run.
- Verify "Hello Lynx" appears, tap → Counter shows, +/− works, ← Back returns.

- [ ] **Step 4: Commit Podfile.lock**

```bash
git add ios/Podfile.lock
git commit -m "chore(ios): lock Pods"
```

---

## Phase 5 — Android Host

### Task 19: Gradle wrapper + root project

**Files:**
- Create: `android/settings.gradle`
- Create: `android/build.gradle`
- Create: `android/gradle.properties`
- Create: `android/gradle/wrapper/gradle-wrapper.properties`
- Create: `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar`

- [ ] **Step 1: Generate wrapper**

```bash
cd android
gradle wrapper --gradle-version 8.7 --distribution-type bin
cd ..
```

If `gradle` CLI is unavailable, install via `brew install gradle` (macOS) first. The wrapper files (`gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, `gradle/wrapper/gradle-wrapper.properties`) will be created.

- [ ] **Step 2: Write `android/settings.gradle`**

```groovy
pluginManagement {
  repositories {
    gradlePluginPortal()
    google()
    mavenCentral()
  }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}
rootProject.name = 'LynxTemplate'
include ':app'
```

- [ ] **Step 3: Write `android/build.gradle`**

```groovy
plugins {
  id 'com.android.application' version '8.5.0' apply false
  id 'org.jetbrains.kotlin.android' version '1.9.24' apply false
}
```

- [ ] **Step 4: Write `android/gradle.properties`**

```properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
```

- [ ] **Step 5: Commit**

```bash
git add android/settings.gradle android/build.gradle android/gradle.properties android/gradle android/gradlew android/gradlew.bat
git commit -m "chore(android): gradle wrapper + root project"
```

---

### Task 20: Android app module

**Files:**
- Create: `android/app/build.gradle`
- Create: `android/app/proguard-rules.pro`

- [ ] **Step 1: Write `android/app/build.gradle`**

```groovy
plugins {
  id 'com.android.application'
  id 'org.jetbrains.kotlin.android'
}

android {
  namespace 'com.example.lynxtemplate'
  compileSdk 34

  defaultConfig {
    applicationId 'com.example.lynxtemplate'
    minSdk 24
    targetSdk 34
    versionCode 1
    versionName '0.0.1'
  }

  buildFeatures { buildConfig true }

  buildTypes {
    release {
      minifyEnabled true
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
    debug {
      // cleartext traffic handled via debug manifest overlay
    }
  }

  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
  kotlinOptions { jvmTarget = '17' }
}

dependencies {
  implementation 'androidx.core:core-ktx:1.13.1'
  implementation 'androidx.appcompat:appcompat:1.7.0'
  implementation 'androidx.constraintlayout:constraintlayout:2.1.4'

  implementation 'org.lynxsdk.lynx:lynx:3.6.0'
  implementation 'org.lynxsdk.lynx:lynx-jssdk:3.6.0'
  implementation 'org.lynxsdk.lynx:lynx-trace:3.6.0'
  implementation 'org.lynxsdk.lynx:primjs:3.6.1'

  implementation 'com.facebook.fresco:fresco:2.3.0'
}
```

- [ ] **Step 2: Write `android/app/proguard-rules.pro`**

```
-keepattributes *Annotation*
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
  @androidx.annotation.Keep *;
}

-keep class com.lynx.** { *; }
-keep class * extends com.lynx.tasm.behavior.ui.LynxBaseUI { *; }
-keep class * implements com.lynx.jsbridge.LynxModule { *; }

-keepclasseswithmembernames class * {
  native <methods>;
}
```

- [ ] **Step 3: Commit**

```bash
git add android/app/build.gradle android/app/proguard-rules.pro
git commit -m "feat(android): app module gradle + proguard"
```

---

### Task 21: Android manifests + resources

**Files:**
- Create: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/res/values/strings.xml`
- Create: `android/app/src/main/res/values/styles.xml`
- Create: `android/app/src/main/res/layout/activity_main.xml`
- Create: `android/app/src/debug/AndroidManifest.xml`
- Create: `android/app/src/debug/res/xml/network_security_config.xml`

- [ ] **Step 1: `android/app/src/main/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET" />
  <application
    android:name=".LynxApp"
    android:allowBackup="false"
    android:label="@string/app_name"
    android:supportsRtl="true"
    android:theme="@style/AppTheme">
    <activity
      android:name=".MainActivity"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>
  </application>
</manifest>
```

- [ ] **Step 2: `strings.xml`**

```xml
<resources>
  <string name="app_name">LynxTemplate</string>
</resources>
```

- [ ] **Step 3: `styles.xml`**

```xml
<resources>
  <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar" />
</resources>
```

- [ ] **Step 4: `activity_main.xml`**

```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:id="@+id/lynx_container"
  android:layout_width="match_parent"
  android:layout_height="match_parent" />
```

- [ ] **Step 5: `android/app/src/debug/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="true"
    tools:replace="android:usesCleartextTraffic"
    xmlns:tools="http://schemas.android.com/tools" />
</manifest>
```

- [ ] **Step 6: `network_security_config.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">10.0.2.2</domain>
    <domain includeSubdomains="true">localhost</domain>
    <domain-cidr>10.0.0.0/8</domain-cidr>
    <domain-cidr>192.168.0.0/16</domain-cidr>
    <domain-cidr>172.16.0.0/12</domain-cidr>
  </domain-config>
</network-security-config>
```

(If a specific Android API level rejects `domain-cidr`, fall back to listing `10.0.2.2` + `localhost` only and document that physical-device LAN IP must be added per-deploy.)

- [ ] **Step 7: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/res android/app/src/debug
git commit -m "feat(android): manifests + resources (debug cleartext overlay)"
```

---

### Task 22: Android Kotlin sources

**Files:**
- Create: `android/app/src/main/java/com/example/lynxtemplate/LynxApp.kt`
- Create: `android/app/src/main/java/com/example/lynxtemplate/TemplateProvider.kt`
- Create: `android/app/src/main/java/com/example/lynxtemplate/MainActivity.kt`

- [ ] **Step 1: Write `LynxApp.kt`**

```kotlin
package com.example.lynxtemplate

import android.app.Application
import com.lynx.tasm.LynxEnv
import com.lynx.service.http.LynxHttpService
import com.lynx.service.image.LynxImageService
import com.lynx.service.log.LynxLogService
import com.lynx.tasm.service.LynxServiceCenter

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

**Note:** exact service package names must match what the pinned Lynx Android artifacts expose. If `LynxHttpService` lives under a slightly different package, fix the import here only — do not remove the registration.

- [ ] **Step 2: Write `TemplateProvider.kt`**

```kotlin
package com.example.lynxtemplate

import android.content.Context
import com.lynx.tasm.provider.AbsTemplateProvider
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class TemplateProvider(private val ctx: Context) : AbsTemplateProvider() {
  private val io = Executors.newSingleThreadExecutor()

  override fun loadTemplate(url: String, callback: Callback) {
    io.execute {
      try {
        val bytes = if (url.startsWith("http://") || url.startsWith("https://")) {
          (URL(url).openConnection() as HttpURLConnection).run {
            connectTimeout = 5000
            readTimeout = 10000
            inputStream.use { it.readBytes() }
          }
        } else {
          ctx.assets.open("main.lynx.bundle").use { it.readBytes() }
        }
        callback.onSuccess(bytes)
      } catch (t: Throwable) {
        callback.onFailed(t.message ?: "load failed")
      }
    }
  }
}
```

- [ ] **Step 3: Write `MainActivity.kt`**

```kotlin
package com.example.lynxtemplate

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.lynx.tasm.LynxViewBuilder

class MainActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    val url = if (BuildConfig.DEBUG) {
      // Physical device: replace 10.0.2.2 with LAN IP printed by `pnpm dev:ip`
      "http://10.0.2.2:3000/main.lynx.bundle"
    } else {
      "embedded://main.lynx.bundle"
    }

    val lynx = LynxViewBuilder()
      .setTemplateProvider(TemplateProvider(this))
      .build(this)

    findViewById<android.widget.FrameLayout>(R.id.lynx_container).addView(lynx)
    lynx.renderTemplateUrl(url, "")
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/java
git commit -m "feat(android): Application + TemplateProvider + MainActivity"
```

---

### Task 23: Android debug build verification

**Files:** none.

- [ ] **Step 1: Build debug APK**

```bash
cd android && ./gradlew assembleDebug && cd ..
```
Expected: `BUILD SUCCESSFUL` and APK written to `android/app/build/outputs/apk/debug/app-debug.apk`.

If gradle fails because a pinned Lynx version isn't on Maven Central, bump both the spec's version table and `android/app/build.gradle` to the nearest published 3.x version in lockstep before retrying.

- [ ] **Step 2: Manual emulator smoke**

- Start `pnpm dev` in one terminal.
- Open Android Studio, open `android/` as a project, launch an API 24+ AVD, run.
- Verify Hello → Counter flow.

- [ ] **Step 3: No commit** — the task creates no new files.

---

## Phase 6 — README + Final Verification

### Task 24: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write `README.md`**

```markdown
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

## Docs

- iOS: <https://lynxjs.org/guide/start/integrate-with-existing-apps?platform=ios>
- Android: <https://lynxjs.org/guide/start/integrate-with-existing-apps?platform=android>
- Web: <https://lynxjs.org/guide/start/integrate-with-existing-apps?platform=web>
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

### Task 25: Final end-to-end verification

**Files:** none.

- [ ] **Step 1: JS gates**

```bash
pnpm install
pnpm typecheck
pnpm lint
pnpm test
pnpm build
```
Expected: all five succeed; `dist/main.lynx.bundle` and `dist/web/index.html` exist.

- [ ] **Step 2: iOS build**

```bash
cd ios && pod install && cd ..
xcodebuild -workspace ios/LynxTemplate.xcworkspace -scheme LynxTemplate -sdk iphonesimulator -configuration Debug build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Android build**

```bash
cd android && ./gradlew assembleDebug && cd ..
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Manual runtime smoke (documented)**

- Start `pnpm dev`. Launch iOS simulator via Xcode. Confirm: Hello Lynx → Counter → back.
- Launch Android emulator via Android Studio. Confirm same.
- Run `pnpm dev:web`. Open `http://localhost:3001`. Confirm same.

- [ ] **Step 5: Tag initial release**

```bash
git tag v0.0.1
```

Plan complete.

---

## Spec Coverage Self-Check

- Goals: flat RN layout (T1, T14, T19), Swift iOS (T15-17), Kotlin Android (T22), Android 7+ (T20 minSdk 24), iOS 12+ (T14), ReactLynx + react-router memory (T6-9), dev/release bundle split (T17, T22), pnpm (T1), TS strict (T2), ESLint+Prettier (T3), Vitest JS smoke (T4, T6, T7, T8), Hello → Counter (T7-8). ✅
- Non-goals honored: no scaffolder CLI, no workspaces, no native module example, no native test scaffolding, no CI files. ✅
- Repo layout matches Section 2 of spec. ✅
- rspeedy config matches Section 4. ✅
- iOS Podfile versions pinned per Section 5. ✅
- Android deps match Section 6. ✅
- Web host matches Section 7. ✅
- Placeholder names (Section 11) appear exactly as LynxTemplate / com.example.lynxtemplate across iOS + Android + README. ✅
- Verification matrix (Section 12) maps 1:1 to Task 25. ✅
