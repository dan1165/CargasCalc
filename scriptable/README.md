# CargasCalc for Scriptable

`CargasCalc.js` is a native Scriptable calculator. A custom-drawn Midnight Transit hero sits above one native table; tap an amount to edit it in a single-field alert. No WebView, history, exported images, network, or stored state.

## Install

1. Copy `CargasCalc.js` into Scriptable, either by creating a new script and pasting the file, or by opening the file from the Files app and sharing it to Scriptable.
2. Run the script.

## Use

- Tap **Cash in hand**, **Imran took**, **Bambang took**, or **Danii took** and enter an amount.
- The split below updates immediately: total pot, each share, and each payout.
- If someone is over their share, a **Settle up** section shows exactly who pays whom. With two people over, both payments are listed; the cash in hand covers the rest.
- Tap **Reset** to clear all amounts, or **Done** / swipe down to close.

Money is calculated in integer cents, with leftover cents going to the earliest people, matching `Sources/CargasCalcCore/Split.swift`. A negative payout reads as "owes" with the amount over the share. Person names and payouts keep the app's three line colours, using light and dark variants for contrast.

## How it is built

The hero is drawn locally with `DrawContext`: the total pot, the cash/taken line, and the three-cell route bar. The table is native, so rows, headers, selection and the action buttons behave like the rest of iOS. Inputs are single-field native alerts with the field name as the title, and the result is part of the same screen rather than a second mode.
