import XCTest
@testable import CargasCalcCore

final class SplitTests: XCTestCase {
    func testTheirScenario() {
        let split = Split(cash: 200_000, advances: [50_000, 25_000, 0])
        XCTAssertEqual(split.pot, 275_000)
        XCTAssertEqual(split.shares, [91_667, 91_667, 91_666])
        XCTAssertEqual(split.payouts, [41_667, 66_667, 91_666])
        // Payouts hand out exactly the cash on hand.
        XCTAssertEqual(split.payouts.reduce(0, +), 200_000)
    }

    func testNothingTaken() {
        let split = Split(cash: 90_000, advances: [0, 0, 0])
        XCTAssertEqual(split.shares, [30_000, 30_000, 30_000])
        XCTAssertEqual(split.payouts, [30_000, 30_000, 30_000])
    }

    func testEmptyInputs() {
        let split = Split(cash: 0, advances: [])
        XCTAssertEqual(split.advances, [0, 0, 0])
        XCTAssertEqual(split.pot, 0)
        XCTAssertEqual(split.payouts, [0, 0, 0])
    }

    func testPaysBackWhenAdvanceExceedsShare() {
        let split = Split(cash: 10_000, advances: [20_000, 0, 0])
        XCTAssertEqual(split.payouts, [-10_000, 10_000, 10_000])
    }

    func testParsing() {
        XCTAssertEqual(Money.parse("RM 2,750.50"), 275_050)
        XCTAssertEqual(Money.parse(""), 0)
        XCTAssertEqual(Money.parse("500"), 50_000)
        XCTAssertEqual(Money.parse(String(repeating: "9", count: 20)), Int.max)
        XCTAssertEqual(Money.parse("1.2.3"), 0)
    }

    func testFormatting() {
        XCTAssertEqual(Money.format(275_000), "RM 2,750.00")
        XCTAssertEqual(Money.format(91_666), "RM 916.66")
        XCTAssertEqual(Money.number(275_000), "2,750.00")
        XCTAssertEqual(Money.number(-10_000), "-100.00")
    }

    func testRecordRoundTrip() throws {
        let record = SplitRecord(cash: 200_000, advances: [50_000, 25_000, 0])
        let data = try JSONEncoder().encode([record])
        let decoded = try JSONDecoder().decode([SplitRecord].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.split.pot, 275_000)
        XCTAssertEqual(decoded.first?.split.payouts, [41_667, 66_667, 91_666])
    }

    func testSummary() {
        let record = SplitRecord(
            date: Date(timeIntervalSince1970: 0),
            cash: 200_000,
            advances: [50_000, 25_000, 0]
        )

        XCTAssertTrue(record.summary.hasPrefix("CargasCalc —"))
        XCTAssertTrue(record.summary.contains("Total pot: RM 2,750.00"))
        XCTAssertTrue(record.summary.contains("Cash in hand: RM 2,000.00"))
        XCTAssertTrue(record.summary.contains("Imran: gets RM 416.67"))
        XCTAssertTrue(record.summary.contains("Danii: gets RM 916.66"))
    }

    func testSummaryNamesADebt() {
        let record = SplitRecord(cash: 10_000, advances: [20_000, 0, 0])
        XCTAssertTrue(record.summary.contains("Imran: owes RM 100.00"))
        XCTAssertFalse(record.summary.contains("Imran: gets"))
        XCTAssertTrue(record.summary.contains("Settle up:"))
        XCTAssertTrue(record.summary.contains("Imran pays Bambang: RM 50.00"))
        XCTAssertTrue(record.summary.contains("Imran pays Danii: RM 50.00"))
        XCTAssertTrue(record.summary.contains("Cash in hand covers the rest."))
    }

    func testSettlementOneOverSplitsAcrossTwo() {
        let split = Split(cash: 10_000, advances: [20_000, 0, 0])
        XCTAssertEqual(split.payouts, [-10_000, 10_000, 10_000])
        XCTAssertEqual(
            split.settlement,
            [
                SplitTransfer(from: 0, to: 1, amount: 5_000),
                SplitTransfer(from: 0, to: 2, amount: 5_000),
            ]
        )
    }

    func testSettlementTwoOverPayTheThird() {
        let split = Split(cash: 0, advances: [20_000, 20_000, 0])
        XCTAssertEqual(split.payouts, [-6_666, -6_667, 13_333])
        XCTAssertEqual(
            split.settlement,
            [
                SplitTransfer(from: 0, to: 2, amount: 6_666),
                SplitTransfer(from: 1, to: 2, amount: 6_667),
            ]
        )
    }

    func testSettlementIsProportionalWhenCreditorsDiffer() {
        let split = Split(cash: 10_000, advances: [30_000, 5_000, 0])
        XCTAssertEqual(split.payouts, [-15_000, 10_000, 15_000])
        XCTAssertEqual(
            split.settlement,
            [
                SplitTransfer(from: 0, to: 1, amount: 6_000),
                SplitTransfer(from: 0, to: 2, amount: 9_000),
            ]
        )
    }

    func testSettlementWhenNobodyIsOver() {
        let split = Split(cash: 90_000, advances: [0, 0, 0])
        XCTAssertTrue(split.settlement.isEmpty)
    }

    func testSettlementTotalsAreExact() {
        let split = Split(cash: 10_000, advances: [30_000, 5_000, 0])
        for (index, payout) in split.payouts.enumerated() {
            let paid = split.settlement
                .filter { $0.from == index }
                .reduce(0) { $0 + $1.amount }
            let received = split.settlement
                .filter { $0.to == index }
                .reduce(0) { $0 + $1.amount }

            if payout < 0 {
                XCTAssertEqual(paid, -payout, "Debtor \(index) must pay the full over-share")
            }
            if payout > 0 {
                XCTAssertLessThanOrEqual(received, payout, "Creditor \(index) cannot be overpaid")
            }
        }
    }
}
