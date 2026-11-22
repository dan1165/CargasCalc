import SwiftUI
import CargasCalcCore

/// A station node on the route: the line changes colour at each person.
struct StationRail: View {
    let color: Color
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isFirst {
                Color.clear
                    .frame(width: 2, height: 18)
            } else {
                Rectangle()
                    .fill(color.opacity(0.5))
                    .frame(width: 2, height: 18)
            }

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay {
                    Circle()
                        .stroke(Transit.ink, lineWidth: 3)
                }

            if isLast {
                Spacer(minLength: 0)
            } else {
                Rectangle()
                    .fill(color.opacity(0.5))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 22)
        .accessibilityHidden(true)
    }
}

/// Ringgit amounts set as the figure, not as a sentence.
struct MoneyFigure: View {
    enum Size {
        case display
        case payout
        case compact
    }

    let cents: Int
    var size: Size = .payout

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("RM")
                .font(currencyFont)
                .foregroundStyle(Transit.secondary)

            Text(Money.number(cents))
                .font(valueFont)
                .monospacedDigit()
                .foregroundStyle(Transit.porcelain)
                .lineLimit(1)
                .minimumScaleFactor(size == .compact ? 0.75 : 1)
                .fixedSize(horizontal: size != .compact, vertical: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Money.format(cents))
    }

    private var valueFont: Font {
        switch size {
        case .display: .system(.largeTitle, design: .default, weight: .light)
        case .payout: .system(.title, design: .default, weight: .light)
        case .compact: .system(.callout, design: .default, weight: .medium)
        }
    }

    private var currencyFont: Font {
        switch size {
        case .display: .title3
        case .payout: .caption
        case .compact: .caption2
        }
    }
}

/// The figure and its caption, with the debt state written out.
struct PayoutBlock: View {
    let payout: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if payout < 0 {
                Text("owes \(Money.format(-payout))")
                    .font(.system(.title3, design: .default, weight: .light).monospacedDigit())
                    .foregroundStyle(Transit.porcelain)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("over the share")
                    .font(.caption2)
                    .foregroundStyle(Transit.secondary)
            } else {
                MoneyFigure(cents: payout)
                Text("gets now")
                    .font(.caption2)
                    .foregroundStyle(Transit.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Name and share on the left, payout on the right; stacks when the type grows.
struct StationHeader<Identity: View>: View {
    let payout: Int
    let identity: Identity

    init(payout: Int, @ViewBuilder identity: () -> Identity) {
        self.payout = payout
        self.identity = identity()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                identity
                Spacer(minLength: 8)
                PayoutBlock(payout: payout)
            }

            VStack(alignment: .leading, spacing: 6) {
                identity
                PayoutBlock(payout: payout)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

/// One horizontal route: each person's cell is their share, the bright tail is
/// what they still get, the dim head is what they took early.
struct PotRouteBar: View {
    let split: Split

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 3) {
                ForEach(Split.people.indices, id: \.self) { index in
                    segment(index)
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            HStack(spacing: 3) {
                ForEach(Split.people.indices, id: \.self) { index in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Transit.line(index))
                            .frame(width: 4, height: 4)
                        Text(Split.people[index])
                            .font(.caption2)
                            .foregroundStyle(Transit.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text("Bright = gets now · dim = took early")
                .font(.caption2)
                .foregroundStyle(Transit.tertiary)
        }
    }

    private func segment(_ index: Int) -> some View {
        GeometryReader { proxy in
            let share = max(split.shares[index], 1)
            let payout = max(split.payouts[index], 0)
            let bright = proxy.size.width * CGFloat(payout) / CGFloat(share)

            ZStack(alignment: .trailing) {
                Rectangle()
                    .fill(Transit.line(index).opacity(0.20))
                Rectangle()
                    .fill(Transit.line(index))
                    .frame(width: bright)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            split.payouts[index] < 0
                ? "\(Split.people[index]) owes \(Money.format(-split.payouts[index]))"
                : "\(Split.people[index]) gets \(Money.format(split.payouts[index]))"
        )
    }
}

/// The read-only version of a station, used by saved splits.
struct StationSummary: View {
    let index: Int
    let split: Split
    let isFirst: Bool
    let isLast: Bool

    private var payout: Int { split.payouts[index] }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            StationRail(
                color: Transit.line(index),
                isFirst: isFirst,
                isLast: isLast
            )

            VStack(alignment: .leading, spacing: 9) {
                StationHeader(payout: payout) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Split.people[index])
                            .font(.headline)
                            .foregroundStyle(Transit.porcelain)
                        Text(
                            "took \(Money.format(split.advances[index])) · " +
                            "share \(Money.format(split.shares[index]))"
                        )
                        .font(.caption)
                        .foregroundStyle(Transit.secondary)
                        .monospacedDigit()
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Who pays whom when someone is over their share.
struct SettlementBlock: View {
    let split: Split

    var body: some View {
        let transfers = split.settlement

        if !transfers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Settle up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Transit.porcelain)

                ForEach(transfers) { transfer in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(
                            "\(Split.people[transfer.from]) pays " +
                            "\(Split.people[transfer.to])"
                        )
                        .font(.subheadline)
                        .foregroundStyle(Transit.porcelain)

                        Spacer(minLength: 8)

                        MoneyFigure(cents: transfer.amount, size: .compact)
                    }
                    .accessibilityElement(children: .combine)
                }

                if split.cash > 0 {
                    Text("Cash in hand covers the rest of each payout.")
                        .font(.caption2)
                        .foregroundStyle(Transit.tertiary)
                        .padding(.top, 2)
                }
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Transit.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Transit.porcelain, in: Capsule())
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Transit.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}
