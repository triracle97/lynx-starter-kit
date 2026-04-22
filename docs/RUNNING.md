# Running the app

All four targets share a single JS build pipeline (rspeedy) and a single ReactLynx source tree (`src/`). The only per-platform difference is how the bundle reaches the runtime: native apps fetch it over LAN in Debug and embed it in Release; web loads it via `<lynx-view>`.

## Prereqs (one-time)

| Tool | Used by | Install |
|---|---|---|
| Node 20 | everything | `nvm use` (reads `.nvmrc`) |
| pnpm 9 | everything | `corepack enable` |
| Xcode 15+ | iOS | App Store |
| CocoaPods ≥ 1.11.3 | iOS | `brew install cocoapods` |
| xcodegen | iOS | `brew install xcodegen` |
| JDK 17 | Android | `brew install openjdk@17` |
| Android Studio Hedgehog+ + API 34 SDK + API 24+ emulator | Android | Google |

Then:
```bash
pnpm install
cd ios && pod install && cd ..
```

## The one command that feeds all native targets

```bash
pnpm dev
```

This starts **rspeedy's native dev server** on `http://localhost:3000`. It serves `/main.lynx.bundle` and pushes HMR updates to every native client connected to it. Leave this running the entire time you're developing — it's the heartbeat.

---

## iOS

### Simulator

1. In another terminal: `open ios/LynxTemplate.xcworkspace`.
2. Pick any iOS 13+ simulator in Xcode's scheme chooser.
3. **Run** (⌘R).
4. The app launches, `ViewController` loads `http://localhost:3000/main.lynx.bundle` because `#if DEBUG` is on, and "Hello Lynx" appears.
5. Edit `src/routes/Hello.tsx` → save → HMR pushes the update — no rebuild, no app restart.

The simulator can reach your Mac's `localhost` directly; nothing else to configure.

### Physical device (same Wi-Fi as your Mac)

Two one-line edits, then build:

1. Find your LAN IP:
   ```bash
   pnpm dev:ip
   # → http://192.168.x.y:3000/main.lynx.bundle
   ```
2. Edit `ios/LynxTemplate/ViewController.swift`:
   ```swift
   private static let devHost = "localhost"
   ```
   Change `"localhost"` to the IP portion (e.g. `"192.168.0.213"`).
3. In Xcode: pick your device in the scheme chooser, **Run**.

ATS is already configured for LAN (`NSAllowsLocalNetworking = YES` in `Info.plist`). User Script Sandboxing is off (enforced by `Podfile` `post_install`).

**If the device can't reach the Mac:** macOS firewall may be blocking inbound `:3000`. System Settings → Network → Firewall → allow `node` when prompted. Make sure both devices are on the same Wi-Fi (and not on a guest/isolation network).

### iOS release build

```bash
pnpm release        # builds dist/main.lynx.bundle AND copies it into ios/LynxTemplate/bundle/
```

Then Xcode **Product → Archive** → distribute. Release builds read the embedded bundle; they don't touch `localhost`.

---

## Android

### Emulator (API 24+)

1. In another terminal: open `android/` in Android Studio (first open triggers a Gradle sync — takes ~1 min).
2. Start an AVD (Android 7 / API 24 or newer).
3. **Run ▶**.
4. The app launches, `MainActivity` loads `http://10.0.2.2:3000/main.lynx.bundle` (`10.0.2.2` is the emulator's alias for the host's `localhost`).
5. Edit `src/**` → HMR pushes.

### Physical device (same Wi-Fi)

1. Enable **USB debugging** on the device, plug in.
2. Get LAN IP: `pnpm dev:ip`.
3. Edit `android/app/src/main/java/com/example/lynxtemplate/MainActivity.kt`:
   ```kotlin
   val url = if (BuildConfig.DEBUG) {
     "http://10.0.2.2:3000/main.lynx.bundle"
   } else {
     "embedded://main.lynx.bundle"
   }
   ```
   Replace `10.0.2.2` with your LAN IP (e.g. `192.168.0.213`).
4. **Run ▶**.

Cleartext HTTP to localhost / `10.0.2.2` / `192.168.0.0/16` / `10.0.0.0/8` / `172.16.0.0/12` is permitted in Debug only via `android/app/src/debug/res/xml/network_security_config.xml`. Release builds do not hit the network.

**Caveat on API < 31:** `<domain-cidr>` is silently ignored on API 24–30. If your phone is on an odd subnet not covered by the listed `<domain>` entries, add it explicitly:
```xml
<domain includeSubdomains="true">your.lan.ip.here</domain>
```

### Android release build

```bash
pnpm release
cd android && ./gradlew assembleRelease
```

APK lands at `android/app/build/outputs/apk/release/`.

---

## Web

No HMR yet — that's gated on [lynx-family/lynx-stack#140](https://github.com/lynx-family/lynx-stack/issues/140) upstream. Current flow is **build + static-serve**.

```bash
# Terminal 1 — build
pnpm build:web

# Terminal 2 — serve
npx http-server dist/web -p 4000 -c-1
```

Open `http://localhost:4000`. Requires Chrome ≥ 92 or Safari ≥ 16.4 (web-core's baseline).

On each source change:
```bash
pnpm build:web && # browser refresh
```

Full rebuild is ~1–2 s.

**How this works under the hood:** `pnpm build:web` runs `rspeedy build --environment web` (produces the Lynx app at `dist/web/main.web.bundle`) followed by `node scripts/build-web-entry.cjs` (uses esbuild to bundle `web/main.ts` → `dist/web/main.js`). The hand-authored `web/index.html` is copied verbatim; it loads `/main.js` (which side-effect-imports `@lynx-js/web-core`, registering the `<lynx-view>` custom element) and points `<lynx-view url="/main.web.bundle">` at the app bundle. This two-step is necessary because rspeedy 0.9 hard-codes `htmlPlugin: false`, so its `html.template` config is ignored.

### Web release build

The dev command IS the release build. Deploy `dist/web/` to any static host (Netlify, Vercel static, S3+CloudFront, GitHub Pages, nginx, …). No server-side code needed.

---

## Troubleshooting

**`pnpm dev` seems to work but iOS / Android shows a blank screen**
Check the port rspeedy actually bound to (first few lines of its output). If it's not `:3000`, update `devPort` in `ViewController.swift` and the URL in `MainActivity.kt`.

**iOS simulator build fails with `sandbox is not in sync with the Podfile.lock`**
Usually means Pods drifted. Fix: `cd ios && pod install && cd ..` then rebuild.

**Android build fails with `invalid Java home`**
JDK 17 needs to be on PATH for Gradle. Either:
```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
```
or permanent:
```bash
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> ~/.zshrc
```

**`<lynx-view>` appears in the web page but renders nothing**
Open browser devtools → Network tab → confirm both `/main.js` (200) and `/main.web.bundle` (200) load. If `main.js` is missing, you ran `pnpm build:web` before the T11 fix — re-build.

**Device on LAN can't reach dev server**
- Same Wi-Fi? Not a guest network with AP isolation?
- macOS firewall blocking `node`? System Settings → Network → Firewall.
- Port 3000 in use by another process? Kill it or let rspeedy pick another port and update the constants.

**Release build loads the wrong bundle**
`scripts/embed-bundle.cjs` copies `dist/main.lynx.bundle` into both `ios/LynxTemplate/bundle/main.lynx.bundle` and `android/app/src/main/assets/main.lynx.bundle`. If you renamed the bundle, `TemplateProvider` (Swift + Kotlin) now derives the filename from the requested URL, so update the URL in `ViewController.swift` / `MainActivity.kt` to match whatever file is embedded.
