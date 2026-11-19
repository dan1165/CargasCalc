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
}
