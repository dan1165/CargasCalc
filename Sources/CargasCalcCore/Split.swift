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
        return lines.joined(separator: "\n")
    }
}
