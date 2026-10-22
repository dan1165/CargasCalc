# CargasCalc

A small native SwiftUI app for splitting a shared cash pot three ways after some people have already taken money out.

Repository: [github.com/dan1165/CargasCalc](https://github.com/dan1165/CargasCalc)

## What it does

- Enter the cash in hand and how much each person took early.
- See the total pot, each person's equal share, and what they still receive.
- Save splits to history, open, edit, share, or delete them.
- Money is handled in integer cents; no floating-point split math.

The three names are currently hard-coded in `Split.people` (`Imran`, `Bambang`, `Danii`).

## Split rule

The pot is `cash in hand + everything taken early`. It is divided equally, with leftover cents going one each to the earliest people. Each person's payout is their share minus what they already took, so the payouts always add up to the cash in hand.

## Build

The unsigned IPA is built by the `Build unsigned IPA` GitHub Actions workflow. It is **manual dispatch only**; pushing does not build.

- Runner: `macos-26-intel` (the arm64 pool had long queues).
- Product: `CargasCalc`.
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

## Known gaps

- No app icon yet.
- iOS 26 baseline.
- No simulator/on-device visual test in this environment; SwiftUI is compile-checked by CI.
