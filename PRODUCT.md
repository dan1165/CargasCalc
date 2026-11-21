# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

The operator and two friends — Imran, Bambang, and Danii — settling a shared cash pot after some of them have already taken money out. It is used in the moment, often one-handed, while the group is together and the numbers are still fresh. There is no third audience and no account system.

## Product Purpose

Turn a potentially argumentative three-way split into a two-second, exact answer. Enter the cash still in hand and what each person took early; the app shows the total pot, each person's equal share, and exactly what each still receives. Saved splits keep a record of what was agreed. Success is that nobody has to redo the arithmetic or dispute a cent.

## Positioning

A shared pot is not divided by the cash in hand alone — early withdrawals are part of the pot. CargasCalc makes that correction automatic and exact to the cent, then keeps the result as a shareable record. A generic bill splitter cannot truthfully copy the mechanism without modelling advances.

## Operating Context

Ringgit (RM) amounts in Malaysia. The group pools cash for trips, meals, and shared purchases; one or more people take money out before the final split. Calculations happen in the moment, then the result is saved, reopened, edited, or shared as plain text or an image card. A whole history can leave the app as a CSV file.

## Capabilities and Constraints

- Three fixed people in this order: Imran, Bambang, Danii.
- Money is integer cents; no floating-point split maths. Leftover cents go one each to the earliest people.
- Payouts equal shares minus advances and always sum to the cash in hand.
- History persists as JSON in `UserDefaults`: save, open, edit, share, delete, clear.
- A saved split can be shared as a rendered PNG card; the whole history can be exported as CSV.
- Editing a saved record preserves its `id` and `date`.
- Forced dark appearance is a confirmed product constraint.
- iOS 26.0 minimum install version; SwiftUI/xtool; built only through GitHub Actions.
- No simulator or on-device visual check exists in the development environment.

## Brand Commitments

- Product and display name: CargasCalc.
- The three names are part of the product's identity at this stage, not placeholder content.
- Dark-only appearance.
- Native iOS interaction only; the app must not read as a ported website.

## Evidence on Hand

No real user records, testimonials, or analytics. All example amounts used in design work are synthetic and must not be presented as real history.

## Product Principles

1. Speed before ceremony: the first field is reachable on launch and the answer is visible while typing.
2. Exactness earns trust: show the cent-level maths plainly, never round for prettiness.
3. One hand, one glance: primary targets stay in thumb reach and results read at a glance.
4. Native by default: system navigation, controls, type, and motion carry the app.
5. A record, not a dashboard: history exists to reopen and share a past agreement, not to be analysed.

## Accessibility & Inclusion

Follow Dynamic Type for all text, keep a 44×44 pt minimum touch target, label icon-only controls for VoiceOver, and preserve contrast in the forced dark appearance. Do not encode meaning in colour alone.
