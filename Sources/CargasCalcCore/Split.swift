import Foundation

public enum Money {
    /// Parses "2,000.50", "RM 2000", etc. into whole cents. Bad input counts as zero.
    public static func parse(_ text: String) -> Int {
        guard !text.contains("-") else { return 0 }
        let cleaned = text.filter { $0.isASCII && ($0.isNumber || $0 == ".") }
        guard let value = Double(cleaned), value.isFinite else { return 0 }
        let cents = (value * 100).rounded()
        guard cents < Double(Int.max) else { return Int.max }
        return max(0, Int(cents))
    }

    private static let style: FloatingPointFormatStyle<Double> = .number
        .locale(Locale(identifier: "en_US"))
        .grouping(.automatic)
        .precision(.fractionLength(2))

    /// The amount without a currency prefix, e.g. "2,000.50".
    public static func number(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(style)
    }

    /// A plain decimal for machines, e.g. "2000.50"; never grouped, always ".".
    public static func decimal(_ cents: Int) -> String {
        String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            Double(cents) / 100
        )
    }

    public static func format(_ cents: Int) -> String {
        "RM " + number(cents)
    }
}

/// Splits a pot three ways, accounting for cash each person already took.
public struct Split: Sendable {
    public static let people = ["Imran", "Bambang", "Danii"]

    public let cash: Int
    public let advances: [Int]

    public init(cash: Int, advances: [Int]) {
        self.cash = max(0, cash)
        self.advances = Self.people.indices.map {
            advances.indices.contains($0) ? max(0, advances[$0]) : 0
        }
    }

    /// Cash in hand plus everything already taken.
    public var pot: Int { cash + advances.reduce(0, +) }

    /// Whole cents per person; leftover cents go to the first people.
    public var shares: [Int] {
        let base = pot / Self.people.count
        let remainder = pot % Self.people.count
        return Self.people.indices.map { base + ($0 < remainder ? 1 : 0) }
    }

    /// What each person still receives now, after their advance.
    public var payouts: [Int] {
        zip(shares, advances).map { $0 - $1 }
    }

    /// Who pays whom when someone took more than their share. Each debtor pays
    /// exactly their over-share amount; the cash in hand covers the rest.
    public var settlement: [SplitTransfer] {
        var needs = payouts.map { max(0, $0) }
        var transfers: [SplitTransfer] = []

        for (from, payout) in payouts.enumerated() where payout < 0 {
            var remaining = -payout
            let totalNeed = needs.reduce(0, +)
            guard remaining > 0, totalNeed > 0 else { continue }

            var amounts = needs.map { remaining * $0 / totalNeed }
            var leftover = remaining - amounts.reduce(0, +)

            let order = needs.indices.sorted { lhs, rhs in
                let left = (remaining * needs[lhs]) % totalNeed
                let right = (remaining * needs[rhs]) % totalNeed
                return left == right ? lhs < rhs : left > right
            }

            var cursor = 0
            while leftover > 0 {
                let index = order[cursor % order.count]
                if amounts[index] < needs[index] {
                    amounts[index] += 1
                    leftover -= 1
                }
                cursor += 1
            }

            for to in needs.indices where amounts[to] > 0 {
                transfers.append(
                    SplitTransfer(from: from, to: to, amount: amounts[to])
                )
                needs[to] -= amounts[to]
            }
        }

        return transfers
    }
}

/// One over-share payment from one person to another.
public struct SplitTransfer: Sendable, Equatable, Identifiable {
    public let from: Int
    public let to: Int
    public let amount: Int

    public var id: String { "\(from)-\(to)" }

    public init(from: Int, to: Int, amount: Int) {
        self.from = from
        self.to = to
        self.amount = amount
    }
}

/// A saved snapshot of one split.
public struct SplitRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let cash: Int
    public let advances: [Int]

    public init(id: UUID = UUID(), date: Date = .now, cash: Int, advances: [Int]) {
        let split = Split(cash: cash, advances: advances)
        self.id = id
        self.date = date
        self.cash = split.cash
        self.advances = split.advances
    }

    public var split: Split { Split(cash: cash, advances: advances) }

    /// Plain-text breakdown for sharing.
    public var summary: String {
        let split = split
        var lines = [
            "CargasCalc — \(date.formatted(date: .abbreviated, time: .shortened))",
            "Total pot: \(Money.format(split.pot))",
            "Cash in hand: \(Money.format(cash))",
            "",
        ]
        for index in Split.people.indices {
            let person = Split.people[index]
            let payout = split.payouts[index]
            let amount = payout < 0
                ? "owes \(Money.format(-payout))"
                : "gets \(Money.format(payout))"
            lines.append(
                "\(person): \(amount) " +
                "(share \(Money.format(split.shares[index])), " +
                "took \(Money.format(split.advances[index])))"
            )
        }

        if !split.settlement.isEmpty {
            lines.append("")
            lines.append("Settle up:")
            for transfer in split.settlement {
                lines.append(
                    "\(Split.people[transfer.from]) pays " +
                    "\(Split.people[transfer.to]): " +
                    Money.format(transfer.amount)
                )
            }
            if cash > 0 {
                lines.append("Cash in hand covers the rest.")
            }
        }

        return lines.joined(separator: "\n")
    }
}
