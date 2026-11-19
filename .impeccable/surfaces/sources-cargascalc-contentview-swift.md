---
version: 1
slug: "sources-cargascalc-contentview-swift"
primary_target: "Sources/CargasCalc/ContentView.swift"
related_targets: ["Sources/CargasCalc/HistoryView.swift"]
---

# Surface brief — CargasCalc app

Scope: the whole iOS app surface — calculator, saved-split detail, edit sheet, history list, empty state. Visitor mode: Operate.

Audience: the operator and two friends settling a shared cash pot after early withdrawals, one-handed, in the moment. Job: type four amounts, read three payouts, save the agreement.

Constraints: three fixed names and order; RM and integer-cent maths; history preserved (save, open, edit, share, delete, clear); forced dark; native iOS controls and navigation; no gimmicks; no extra taps before the cash field.

## Direction contract

THESIS: The pot is a junction and each person's share is a line running from it; the split is read as a route, not a table of rows, and the category-default grouped form is refused.

OWN-WORLD: Midnight enamel ground (#081428 → #0A1A33), porcelain text, and three line inks — scarlet #E03A2F for Imran, amber #F0A500 for Bambang, cobalt #2F6FD0 for Danii. The pot bar is one horizontal route divided into three equal cells, each cell's bright remainder being the payout and its muted segment the amount already taken. Station dots, 45°/90° bends, and a hairline rule grid carry the map grammar; controls remain stock SwiftUI.

STORY: The visitor lands on the cash field, sees the pot bar redraw as they type, then reads each line's payout and what was taken early. They save, and the record reopens with the same route.

FIRST VIEWPORT: Large title "CargasCalc"; a cash card with a 44 pt RM field; directly below it the three-cell pot route bar with the total pot and equal share; then three station rows, each with a coloured rail, name, an inline "took early" field, and a poster-scale payout. Save sits at the end of the scroll, not over the numbers.

FORM: Catalog challenger `wayfinding-cartography-signage-midnight-transit-diagram`, chosen over the assigned 3rd grounded direction; seed:9e0af78b97b4610d.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
