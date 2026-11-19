# CargasCalc

iOS 26 SwiftUI app built with xtool (no `.xcodeproj`). It splits a cash pot three ways after early withdrawals and stores saved splits. Development happens on Linux, so the IPA is built by GitHub Actions, not locally.

## Build and ship

- Build only through the `Build unsigned IPA` workflow (`.github/workflows/build-ipa.yml`). It runs on every push to `main` and can also be dispatched manually.
- The workflow sets `CFBundleShortVersionString` to `1.0.<run number>` and `CFBundleVersion` to `<run number>` before building.
- It runs on `macos-26-intel` deliberately: the `macos-latest` arm64 pool queued 10–25 min and had jobs cancelled before starting. Don't switch back without testing.
- On macOS xtool skips SDK setup and uses the runner's Xcode, so no Apple login is needed for an unsigned build.
- Output is `xtool/CargasCalc-1.0.<run number>.ipa`, unsigned. A downloaded copy at the repo root is gitignored and safe to overwrite.
- A local Linux build is not possible without `xtool sdk install <Xcode.xip>` (wrapper: `~/.local/bin/xtool`). Don't attempt it; use CI.

## Tests

- All logic lives in `Sources/CargasCalcCore`; tests are in `Tests/CargasCalcCoreTests`.
- `swift test` at the repo root fails on Linux because SwiftPM also compiles the SwiftUI `CargasCalc` target.
- Compile check that works here: `swift build --target CargasCalcCoreTests`.
- To run the tests, copy `Sources/CargasCalcCore` and `Tests/CargasCalcCoreTests` into a scratch SwiftPM package with only those two targets and run `swift test` there.
- Toolchain: `~/.local/swift-6.3/usr/bin`. On Ubuntu 26.04, `swift test` also needs `libxml2.so.2` and `libicuuc.so.74` (extracted from Ubuntu 24.04 debs) on `LD_LIBRARY_PATH`; `swift build` does not.
- SwiftUI code is compiled only by CI. For UI changes, expect to iterate through the workflow.

## Architecture and conventions

- `CargasCalc` (native SwiftUI app) depends on `CargasCalcCore` (Foundation only). Keep math, parsing, and history models in `CargasCalcCore` so they stay testable on Linux.
- Money is integer cents (`Money.parse`, `Money.format`). Never switch split math to `Double`. Leftover cents go one each to the earliest people; `payouts == shares - advances` and must sum to the cash in hand.
- The three names are hard-coded in `Split.people`. Changing names or headcount changes rounding and every saved record — update tests and `SplitRecord` handling deliberately.
- `SplitRecord` is the persisted history model (JSON in `UserDefaults`). Editing a record must preserve its `id` and `date`.
- Display name **CargasCalc** comes from `Info.plist` via `infoPath` in `xtool.yml`. Product, module and bundle ID are all `CargasCalc` / `com.daniisaahir.cargascalc`; this is a fresh identity and does not read data from the old `Calc` app.
- The UI is native SwiftUI in forced dark mode with a white tint. `TransitTheme.swift` owns the Midnight Transit palette (enamel ground, porcelain text, three line inks) and `TransitComponents.swift` owns the route bar, station rail, money figures and primary button. `ContentView` and `HistoryView` compose those; navigation, text fields, sheets and lists stay stock. Keep new screens on the same tokens rather than inventing a second theme.
- The direction and tokens are recorded in `PRODUCT.md`, `DESIGN.md`, `.impeccable/design.json` and `.impeccable/surfaces/`. Update them with the code when the visual system changes.
- Deployment target is iOS **26.0**: the minimum install version, not the SDK. The build uses Swift tools 6.3 and the latest iOS SDK/Xcode available on the macOS 26 runner. The native UI only needs iOS 17 APIs, so the target can be lowered if older devices matter.
- App icon: `icon.png` via `iconPath` in `xtool.yml`.
- Known gap: no simulator/on-device visual check.

More user-facing detail is in `README.md`; keep the two files consistent.
