import SwiftUI
import CargasCalcCore

/// A station node on the route: the line changes colour at each person.
struct StationRail: View {
    let color: Color
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color.opacity(0.5))
                .frame(width: 2, height: 12)

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
                .minimumScaleFactor(0.6)
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

/// One horizontal route: each person's cell is their share, the bright tail is
/// what they still get, the dim head is what they took early.
struct PotRouteBar: View {
    let split: Split

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 3) {
                ForEach(Split.people.indices, id: \.self) { index in
                    segment(index)
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            HStack(spacing: 12) {
                legend("gets now", bright: true)
                legend("took early", bright: false)
                Spacer(minLength: 4)
                Text(
                    split.pot == 0
                        ? "Waiting for cash in hand"
                        : "Payouts total \(Money.format(split.payouts.reduce(0, +)))"
                )
                .font(.caption2)
                .foregroundStyle(Transit.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
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
            "\(Split.people[index]) gets \(Money.format(split.payouts[index]))"
        )
    }

    private func legend(_ title: String, bright: Bool) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Transit.porcelain.opacity(bright ? 1 : 0.22))
                .frame(width: 10, height: 6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Transit.secondary)
        }
    }
}

/// The read-only version of a station, used by saved splits.
struct StationSummary: View {
    let index: Int
    let split: Split
    let isLast: Bool

    private var payout: Int { split.payouts[index] }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            StationRail(color: Transit.line(index), isLast: isLast)

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

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if payout < 0 {
                    Text("owes \(Money.format(-payout))")
                        .font(.system(.title3, design: .default, weight: .light))
                        .monospacedDigit()
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
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
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
