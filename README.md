# CargasCalc

A small native SwiftUI app for splitting a shared cash pot three ways after some people have already taken money out.

Repository: [github.com/dan1165/CargasCalc](https://github.com/dan1165/CargasCalc)

## What it does

- The app starts with empty fields; there are no demo numbers.
- Enter the cash in hand and how much each person took early.
- See the total pot, each person's equal share, and what they still receive.
- Save splits to history, open, edit, share, or delete them.
- Money is handled in integer cents; no floating-point split math.

The three names are currently hard-coded in `Split.people` (`Imran`, `Bambang`, `Danii`).

## Split rule

The pot is `cash in hand + everything taken early`. It is divided equally, with leftover cents going one each to the earliest people. Each person's payout is their share minus what they already took, so the payouts always add up to the cash in hand.

## Platform

iOS 26.0 is the **minimum install version**, not the SDK or tech level. The app is built with Swift tools 6.3, native SwiftUI, and the latest iOS 26 SDK/Xcode 26 available on the macOS 26 CI runner.

The native UI only needs iOS 17 APIs. If older devices matter, the deployment target can be lowered; the current baseline simply matches the latest toolchain and the test device.

## Build

The unsigned IPA is built by the `Build unsigned IPA` GitHub Actions workflow. It is **manual dispatch only**; pushing does not build.

- Runner: `macos-26-intel` (the arm64 pool had long queues).
- Product: `CargasCalc`.
- Toolchain: Swift 6.3, native SwiftUI, Xcode 26 on macOS 26.
- Output: `xtool/CargasCalc.ipa`.
- Artifact: `CargasCalc-ipa`.
- Local Linux builds need an Xcode SDK; use CI instead.
- The IPA is unsigned. Sign it with your own signing service before installing.

## Test

All logic is in `Sources/CargasCalcCore`; UI code is in `Sources/CargasCalc`.

```bash
swift build --target CargasCalcCoreTests
```

`swift test` at the repo root fails on Linux because it also compiles the SwiftUI app. See `AGENTS.md` for the scratch-package test command and the toolchain environment.

## Structure

- `Sources/CargasCalcCore` — money parsing/formatting, split math, saved record model (Foundation only)
- `Sources/CargasCalc` — native SwiftUI app and `UserDefaults` history store
- `Tests/CargasCalcCoreTests` — split, money, record and summary tests

The app, product, module and bundle are all `CargasCalc` / `com.daniisaahir.cargascalc`. This is a fresh app identity: it does not read data from the old `Calc` app. Uninstall the old app to remove its saved history.

## Icon

The app icon is `icon.png` (1024×1024), referenced by `iconPath` in `xtool.yml`.

## Known gaps

- No simulator/on-device visual test in this environment; SwiftUI is compile-checked by CI.
