// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: deep-blue; icon-glyph: map;

/**
 * CargasCalc for Scriptable — calculator only.
 *
 * A drawn Midnight Transit hero, one native table, single-field alerts.
 * No history, images on disk, WebView, network, or stored state.
 *
 * Install: copy this file into Scriptable and run it.
 */

const PEOPLE = ['Imran', 'Bambang', 'Danii'];

const LINE_COLORS = [
  Color.dynamic(new Color('#B42318'), new Color('#FF6B5E')),
  Color.dynamic(new Color('#8A5A00'), new Color('#F0A500')),
  Color.dynamic(new Color('#1D4ED8'), new Color('#6FA8FF'))
];

const HERO_INKS = ['#FF6B5E', '#F0A500', '#6FA8FF'];
const HERO_INK = '#081428';
const HERO_BORDER = '#1E3554';
const HERO_TEXT = '#F4F7FB';
const HERO_SECONDARY = '#97A9BC';
const HERO_TERTIARY = '#7A8EA6';
const HERO_HAIRLINE = '#23395A';
const HERO_HEIGHT = 204;
const HERO_WIDTH = Math.min(Device.screenSize().width - 32, 520);

const LABELS = ['Cash in hand', 'Imran took', 'Bambang took', 'Danii took'];

function parseCents(text) {
  if (text.indexOf('-') !== -1) return 0;
  const cleaned = text.replace(/[^0-9.]/g, '');
  if (!cleaned) return 0;
  const value = Number(cleaned);
  if (!isFinite(value)) return 0;
  const cents = Math.round(value * 100);
  if (!isFinite(cents) || cents < 0) return 0;
  return Math.min(cents, Number.MAX_SAFE_INTEGER);
}

function format(cents) {
  const whole = Math.floor(cents / 100).toString();
  const fraction = (cents % 100 < 10 ? '0' : '') + (cents % 100);
  return whole.replace(/\B(?=(\d{3})+(?!\d))/g, ',') + '.' + fraction;
}

function money(cents) {
  return 'RM ' + format(cents);
}

function calculate(values) {
  const cash = values[0];
  const advances = values.slice(1);
  const pot = cash + advances.reduce((total, amount) => total + amount, 0);
  const base = Math.floor(pot / 3);
  const remainder = pot % 3;
  const shares = [
    base + (remainder > 0 ? 1 : 0),
    base + (remainder > 1 ? 1 : 0),
    base
  ];

  return {
    pot: pot,
    shares: shares,
    payouts: shares.map((share, index) => share - advances[index])
  };
}

/**
 * Work out who pays whom. A person over their share pays the people who are
 * still owed; the cash in hand covers the rest. Amounts are whole cents and
 * every debtor pays exactly their over-share amount.
 */
function settleTransfers(payouts) {
  const needs = payouts.map((payout) => Math.max(0, payout));
  const transfers = [];

  payouts.forEach((payout, from) => {
    if (payout >= 0) return;

    let remaining = -payout;
    const totalNeed = needs.reduce((total, need) => total + need, 0);
    if (remaining <= 0 || totalNeed <= 0) return;

    const exact = needs.map((need) => remaining * need / totalNeed);
    const amounts = exact.map((value) => Math.floor(value));
    let leftover = remaining - amounts.reduce((total, value) => total + value, 0);

    const order = exact
      .map((value, index) => ({ index: index, fraction: value - Math.floor(value) }))
      .sort((a, b) => b.fraction - a.fraction || a.index - b.index);

    let cursor = 0;
    while (leftover > 0) {
      const index = order[cursor % order.length].index;
      if (amounts[index] < needs[index]) {
        amounts[index] += 1;
        leftover -= 1;
      }
      cursor += 1;
    }

    amounts.forEach((amount, to) => {
      if (amount > 0) {
        transfers.push({ from: from, to: to, amount: amount });
        needs[to] -= amount;
      }
    });
  });

  return transfers;
}

function drawRoundedRect(context, rect, radius, color) {
  const path = new Path();
  path.addRoundedRect(rect, radius, radius);
  context.addPath(path);
  context.setFillColor(color);
  context.fillPath();
}

function makeHero(values, result) {
  const width = HERO_WIDTH;
  const height = HERO_HEIGHT;
  const context = new DrawContext();
  context.size = new Size(width, height);
  context.respectScreenScale = true;
  context.opaque = false;

  drawRoundedRect(
    context,
    new Rect(1, 1, width - 2, height - 2),
    20,
    new Color(HERO_INK)
  );

  const border = new Path();
  border.addRoundedRect(new Rect(1, 1, width - 2, height - 2), 20, 20);
  context.addPath(border);
  context.setStrokeColor(new Color(HERO_BORDER));
  context.setLineWidth(1);
  context.strokePath();

  context.setTextAlignedLeft();
  context.setFont(Font.semiboldSystemFont(10));
  context.setTextColor(new Color(HERO_SECONDARY));
  context.drawTextInRect('CARGASCALC', new Rect(20, 18, width - 40, 14));

  context.setTextAlignedRight();
  context.setFont(Font.mediumSystemFont(10));
  context.setTextColor(new Color(HERO_TERTIARY));
  context.drawTextInRect('3-WAY SPLIT', new Rect(width - 140, 18, 120, 14));

  context.setTextAlignedLeft();
  context.setFont(Font.semiboldSystemFont(10));
  context.setTextColor(new Color(HERO_SECONDARY));
  context.drawTextInRect('TOTAL POT', new Rect(20, 42, 160, 14));

  const amount = format(result.pot);
  const amountSize = amount.length > 19 ? 20 : amount.length > 16 ? 24 : amount.length > 13 ? 28 : amount.length > 10 ? 34 : 40;

  context.setFont(Font.mediumSystemFont(15));
  context.setTextColor(new Color(HERO_SECONDARY));
  context.drawTextInRect('RM', new Rect(20, 76, 30, 18));

  context.setFont(Font.lightMonospacedSystemFont(amountSize));
  context.setTextColor(new Color(HERO_TEXT));
  context.drawTextInRect(amount, new Rect(50, 58, width - 70, 50));

  const taken = values.slice(1).reduce((total, value) => total + value, 0);
  context.setFont(Font.regularSystemFont(11));
  context.setTextColor(new Color(HERO_SECONDARY));
  context.drawTextInRect(
    'Cash ' + format(values[0]) + '  ·  Taken ' + format(taken),
    new Rect(20, 112, width - 40, 16)
  );

  context.setFillColor(new Color(HERO_HAIRLINE));
  context.fillRect(new Rect(20, 140, width - 40, 1));

  const barX = 20;
  const barY = 154;
  const barW = width - 40;
  const barH = 12;
  const gap = 3;
  const segmentW = (barW - gap * 2) / 3;

  for (let index = 0; index < 3; index++) {
    const x = barX + index * (segmentW + gap);
    const ink = new Color(HERO_INKS[index]);

    drawRoundedRect(
      context,
      new Rect(x, barY, segmentW, barH),
      4,
      new Color(HERO_INKS[index], 0.2)
    );

    const share = result.shares[index];
    const payout = result.payouts[index];
    const ratio = share > 0 ? Math.max(0, payout) / share : 0;
    const brightW = segmentW * Math.min(1, ratio);

    if (brightW > 1) {
      drawRoundedRect(
        context,
        new Rect(x + segmentW - brightW, barY, brightW, barH),
        4,
        ink
      );
    }
  }

  context.setTextAlignedCenter();
  context.setFont(Font.regularSystemFont(9));
  context.setTextColor(new Color(HERO_TERTIARY));

  for (let index = 0; index < 3; index++) {
    context.drawTextInRect(
      PEOPLE[index],
      new Rect(barX + index * (segmentW + gap), 172, segmentW, 12)
    );
  }

  return context.getImage();
}

async function editAmount(title, cents) {
  const alert = new Alert();
  alert.title = title;
  alert.message = 'Amount in RM.';

  const field = alert.addTextField('0.00', cents > 0 ? format(cents) : '');
  field.setDecimalPadKeyboard();
  field.rightAlignText();
  field.font = Font.mediumMonospacedSystemFont(19);

  alert.addAction('Save');
  alert.addCancelAction('Cancel');

  const choice = await alert.presentAlert();
  if (choice === -1) return null;
  return parseCents(alert.textFieldValue(0));
}

function addHeader(table, title) {
  const row = new UITableRow();
  row.isHeader = true;
  row.addText(title);
  table.addRow(row);
}

function addAmountRow(table, label, value, color, onSelect) {
  const row = new UITableRow();
  row.height = 48;
  row.onSelect = onSelect;
  row.dismissOnSelect = false;

  const left = UITableCell.text(label);
  left.titleFont = Font.body();
  if (color) left.titleColor = color;

  const right = UITableCell.text(value > 0 ? money(value) : '—');
  right.rightAligned();
  right.titleFont = Font.mediumMonospacedSystemFont(18);
  if (value === 0) right.titleColor = Color.gray();

  row.addCell(left);
  row.addCell(right);
  table.addRow(row);
}

function addPayoutRow(table, index, advance, share, payout) {
  const row = new UITableRow();
  row.height = 64;

  const left = UITableCell.text(
    PEOPLE[index],
    'took ' + money(advance) + ' · share ' + money(share)
  );
  left.titleFont = Font.headline();
  left.subtitleFont = Font.footnote();
  left.titleColor = LINE_COLORS[index];

  const right = payout < 0
    ? UITableCell.text('owes ' + money(-payout), 'over the share')
    : UITableCell.text(money(payout));

  right.rightAligned();
  right.titleFont = Font.semiboldMonospacedSystemFont(20);
  right.titleColor = LINE_COLORS[index];

  row.addCell(left);
  row.addCell(right);
  table.addRow(row);
}

function addTransferRow(table, transfer) {
  const row = new UITableRow();
  row.height = 44;

  const left = UITableCell.text(
    PEOPLE[transfer.from] + ' pays ' + PEOPLE[transfer.to]
  );
  left.titleFont = Font.body();
  left.titleColor = LINE_COLORS[transfer.from];

  const right = UITableCell.text(money(transfer.amount));
  right.rightAligned();
  right.titleFont = Font.mediumMonospacedSystemFont(17);

  row.addCell(left);
  row.addCell(right);
  table.addRow(row);
}

async function main() {
  const values = [0, 0, 0, 0];
  const table = new UITable();
  table.showSeparators = true;
  let isPresented = false;

  function render() {
    table.removeAllRows();

    const result = calculate(values);

    const heroRow = new UITableRow();
    heroRow.height = HERO_HEIGHT + 10;
    heroRow.addImage(makeHero(values, result));
    table.addRow(heroRow);

    addHeader(table, 'Amounts');

    if (values.every((value) => value === 0)) {
      const hint = new UITableRow();
      hint.height = 32;
      const hintCell = hint.addText('Tap an amount to edit.');
      hintCell.titleFont = Font.caption1();
      hintCell.titleColor = Color.gray();
      table.addRow(hint);
    }

    LABELS.forEach((label, index) => {
      addAmountRow(
        table,
        label,
        values[index],
        index === 0 ? null : LINE_COLORS[index - 1],
        () => edit(index)
      );
    });

    if (result.pot === 0) {
      const empty = new UITableRow();
      empty.height = 52;
      const cell = empty.addText('Enter an amount to see the split.');
      cell.titleFont = Font.footnote();
      cell.titleColor = Color.gray();
      cell.centerAligned();
      table.addRow(empty);
    } else {
      addHeader(table, 'Payouts');

      PEOPLE.forEach((name, index) => {
        addPayoutRow(
          table,
          index,
          values[index + 1],
          result.shares[index],
          result.payouts[index]
        );
      });

      const transfers = settleTransfers(result.payouts);
      if (transfers.length > 0) {
        addHeader(table, 'Settle up');
        transfers.forEach((transfer) => addTransferRow(table, transfer));

        if (values[0] > 0) {
          const note = new UITableRow();
          note.height = 32;
          const noteCell = note.addText('Cash in hand covers the rest.');
          noteCell.titleFont = Font.caption1();
          noteCell.titleColor = Color.gray();
          table.addRow(note);
        }
      }
    }

    const actions = new UITableRow();
    actions.cellSpacing = 12;

    const reset = actions.addButton('Reset');
    reset.titleColor = Color.red();
    reset.onTap = () => {
      values.fill(0);
      render();
    };

    const done = actions.addButton('Done');
    done.onTap = () => {};
    done.dismissOnTap = true;

    table.addRow(actions);

    if (isPresented) table.reload();
  }

  async function edit(index) {
    const next = await editAmount(LABELS[index], values[index]);
    if (next === null) return;
    values[index] = next;
    render();
  }

  render();
  isPresented = true;
  await table.present();
}

await main();
