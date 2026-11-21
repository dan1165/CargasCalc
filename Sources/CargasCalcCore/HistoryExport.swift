import Foundation

/// A machine-readable export of the saved splits. One row per record, newest
/// first, with the person columns in `Split.people` order.
public enum HistoryExport {
    public static func csv(_ records: [SplitRecord]) -> String {
        let keys = Split.people.map { $0.lowercased() }
        var header = ["saved_at", "cash_in_hand"]
        header += keys.map { "\($0)_took" }
        header.append("total_pot")
        header += keys.map { "\($0)_share" }
        header += keys.map { "\($0)_gets" }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        var lines = [header.joined(separator: ",")]
        for record in records {
            let split = record.split
            var fields = [
                formatter.string(from: record.date),
                Money.decimal(split.cash),
            ]
            fields += split.advances.map(Money.decimal)
            fields.append(Money.decimal(split.pot))
            fields += split.shares.map(Money.decimal)
            fields += split.payouts.map(Money.decimal)
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
