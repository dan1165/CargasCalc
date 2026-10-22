# CargasCalc

iOS 26 SwiftUI app built with xtool (no `.xcodeproj`). It splits a cash pot three ways after early withdrawals and stores saved splits. Development happens on Linux, so the IPA is built by GitHub Actions, not locally.

## Build and ship

- Build only through the `Build unsigned IPA` workflow (`.github/workflows/build-ipa.yml`). It is `workflow_dispatch` only — pushing does not build.
- It runs on `macos-26-intel` deliberately: the `macos-latest` arm64 pool queued 10–25 min and had jobs cancelled before starting. Don't switch back without testing.
- On macOS xtool skips SDK setup and uses the runner's Xcode, so no Apple login is needed for an unsigned build.
- Output is `xtool/CargasCalc.ipa`, unsigned. A downloaded copy at the repo root is gitignored and safe to overwrite.
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
- The UI is plain native SwiftUI (`Form`, `List`, `Section`, `LabeledContent`, `NavigationStack`) in forced dark mode with a white tint. There is no custom theme, background or glass helper; keep it that way unless a UI change needs otherwise.
- Deployment target is iOS **26.0** (project baseline; CI uses macOS 26/Xcode 26). The UI has no custom Liquid Glass APIs; lowering the target is possible but needs CI verification.
- Known gaps: no app icon (`xtool.yml` `iconPath` takes a PNG), and no simulator/on-device visual check.

More user-facing detail is in `README.md`; keep the two files consistent.
