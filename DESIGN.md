---
name: CargasCalc
description: A midnight-transit split for a shared cash pot.
colors:
  ink: "#081428"
  deep: "#050E1C"
  panel: "#0F213A"
  hairline: "#23395A"
  porcelain: "#F4F7FB"
  secondary: "#97A9BC"
  tertiary: "#7A8EA6"
  line-imran: "#E03A2F"
  line-bambang: "#F0A500"
  line-danii: "#2F6FD0"
typography:
  display:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "34px"
    fontWeight: 300
    lineHeight: 1.1
  title:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "28px"
    fontWeight: 300
    lineHeight: 1.15
  headline:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.25
  body:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.35
  label:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.3
rounded:
  bar: "4px"
  field: "8px"
  pill: "999px"
spacing:
  xs: "3px"
  sm: "8px"
  md: "15px"
  lg: "20px"
  xl: "30px"
components:
  button-primary:
    backgroundColor: "{colors.porcelain}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    height: "52px"
  field-advance:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.porcelain}"
    rounded: "{rounded.field}"
    height: "32px"
  route-bar:
    backgroundColor: "{colors.hairline}"
    rounded: "{rounded.bar}"
    height: "12px"
---

# Design System: CargasCalc

## Overview

**Creative North Star: "Midnight Transit"**

CargasCalc is a route map for one shared pot. The cash in hand is the junction; each person is a coloured line leaving it; the amount still owed to them is the bright tail of that line, and what they already took is the dim track behind it. The world comes from the KL rail diagram read at night — enamel navy, porcelain lettering, and three inks that stay identifiable at a glance — while the controls underneath are ordinary iPhone controls.

The screen is one continuous map sheet, not a stack of cards. Type does the hierarchy: a light, large cash figure at the top, a poster-scale payout at each station, and small tracked captions for the arithmetic. Colour is reserved for the three lines and never carries meaning alone; every coloured state is also written in words.

**Key Characteristics:**
- Deep midnight ground with a single vertical light fall.
- Three fixed line inks: scarlet Imran, amber Bambang, cobalt Danii.
- Porcelain text; secondary and tertiary tints are blue-grey, never neutral grey.
- One horizontal route bar and three station rails; no decorative side stripes.
- Native iOS navigation, lists, sheets, text fields, and decimal pads.

## Colors

A midnight enamel ground carrying porcelain type and three transit inks.

### Primary
- **Porcelain** (#F4F7FB): primary text, payout figures, the primary button fill, station dots at full strength.
- **Route ink** (#081428): the scroll ground; every panel sits on it rather than beside it.

### Secondary
- **Scarlet line** (#E03A2F): Imran's route segment, station dot, and bar cell. Never used as a generic error colour.
- **Amber line** (#F0A500): Bambang's route segment, station dot, and bar cell.
- **Cobalt line** (#2F6FD0): Danii's route segment, station dot, and bar cell.

### Neutral
- **Deep enamel** (#050E1C): the bottom of the background gradient, below the fold.
- **Panel enamel** (#0F213A): advance fields and history rows.
- **Hairline** (#23395A): rules under the cash field and between saved records.
- **Secondary blue-grey** (#97A9BC): labels, share and advance facts.
- **Tertiary blue-grey** (#7A8EA6): footnotes and the "RM" prefix on small fields.

### Named Rules
**The Line-Ink Rule.** Only the three routes carry hue. Text, chrome, and backgrounds stay in the blue-grey family; a fourth accent never appears.

**The Written-State Rule.** A negative payout is not signalled by red alone: the row says "owes" and "over the share" beside the figure.

## Typography

**Display Font:** SF Pro (system)
**Body Font:** SF Pro (system)
**Label Font:** SF Pro (system)

**Character:** One family, three voices: a light display for money, a semibold headline for names and actions, and small tracked captions for the arithmetic. The restraint keeps the numbers legible at arm's length.

### Hierarchy
- **Display** (light, 34 pt, 1.1): the cash-in-hand field and the saved total pot.
- **Title** (light, 28 pt, 1.15): each station payout, monospaced digits.
- **Headline** (semibold, 17 pt, 1.25): person names and the primary button.
- **Body** (regular, 17 pt, 1.35): editable amounts and list labels.
- **Label** (regular, 12 pt, 1.3): "share", "gets now", legends, and timestamps.

### Named Rules
**The Money-Is-The-Display Rule.** The largest object on the screen is always an amount, never a title, icon, or decorative graphic.

## Layout

A single 20 pt inset sheet runs the full height. The cash field sits at the top under a large navigation title; the pot metrics and route bar follow at 22 pt; the three station rows are separated by 12 pt vertical padding with no dividers, so the rail reads as one continuous line. The save button closes the sheet at 24 pt after the last station. Targets are at least 44 pt tall. At the default text size the four inputs, three payouts, and the save action fit a 393 × 852 pt phone without scrolling; at accessibility sizes the sheet scrolls instead of compressing.

On Dynamic Type the sheet scrolls rather than compressing; names and amounts wrap or scale, and the rail stretches with the tallest row.

## Elevation & Depth

Flat. There are no shadows and no glass. Depth is tonal: the background is a top-lit gradient from deep enamel to route ink, fields are one step lighter (#0F213A), and hairlines separate the cash field and saved records. The only blur is the system navigation bar and sheet material.

### Named Rules
**The No-Glass Rule.** No custom blur, frosted card, or translucent overlay. If a surface needs separation, change its tone or add a hairline.

## Shapes

The route bar is a 12 pt strip with 4 pt continuous corners, divided into three cells with 3 pt joints. Advance fields are 8 pt continuous rounded rectangles. The primary button is a full capsule. Station dots are 12 pt circles ringed in the ground colour. Nothing else is rounded; the sheet itself is square.

## Components

### Buttons
- **Shape:** full capsule, 52 pt minimum height.
- **Primary:** porcelain fill, route-ink label, headline weight; full width.
- **Pressed:** 0.72 opacity, no scale or bounce.
- **Disabled:** 0.5 opacity; the label stays "Save split" until a save lands, then reads "Saved to history".

### Inputs / Fields
- **Cash field:** borderless, 34 pt light monospaced digits, RM prefix in secondary, hairline underline.
- **Advance field:** 92 pt wide, panel fill, 8 pt radius, right-aligned 17 pt monospaced digits, RM prefix outside the field.
- **Focus:** system caret and selection; the decimal pad gains a "Done" accessory.
- **Error:** none at the field level; an over-advance is explained at the station.

### Navigation
- System large title on the calculator, inline titles on history and detail.
- Leading reset action, trailing history action, both icon-only with accessibility labels.
- History is a sheet with its own stack, Clear/Done actions, and native swipe-to-delete.

### Pot Route Bar (signature)
One horizontal strip divided into three equal cells. Each cell is the person's share: the dim leading portion is what they took early, the bright trailing portion is what they still get. A names row under the bar ties each cell to a person, and one caption line names the encoding. A zero pot reads "Waiting for cash in hand".

### Station Row (signature)
A 22 pt rail column carries a 2 pt line in the person's ink through a ringed station dot; the line continues between rows and stops at the last. The row pairs the name and share with a poster-scale payout, then an inline "Took early" field. When the type grows the name and payout stack instead of truncating. Negative payouts replace the figure with "owes …" and "over the share".

### Settle Up
Plain rows under a "Settle up" label: the sentence "Imran pays Bambang" on the left, the compact amount on the right. One row per transfer; two over-people produce two rows. A caption, "Cash in hand covers the rest of each payout.", appears only when cash in hand is above zero. No cards, rails, or extra colour: the sentence itself is the explanation.

### Share Card
The same sheet at 390 × 560 pt, rendered at 3× through `ImageRenderer`: wordmark and date, total pot, route bar, three station summaries, and a one-line footer. It keeps the dark ground, the three inks, and the rail; it never introduces a second palette or a photo.

## Do's and Don'ts

### Do:
- **Do** keep the four inputs and three payouts on one screen at the default text size.
- **Do** pair every colour-coded fact with words or position.
- **Do** use monospaced digits for every amount.
- **Do** let the rail run continuously between stations.
- **Do** keep the primary button the only porcelain-filled element.
- **Do** keep shared image cards on the same ground, three inks, and route grammar.

### Don't:
- **Don't** add a fourth accent colour; the three lines are the whole palette.
- **Don't** turn station rows into cards or add a coloured bar down one edge.
- **Don't** use gradient text, glass, or celebratory motion.
- **Don't** add mascots, badges, streaks, or ranking.
- **Don't** move the cash field behind a tab, sheet, or onboarding step.
