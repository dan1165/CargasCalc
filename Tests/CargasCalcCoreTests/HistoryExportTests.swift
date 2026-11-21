import XCTest
@testable import CargasCalcCore

final class HistoryExportTests: XCTestCase {
    func testHeaderAndRow() {
        let record = SplitRecord(
            date: Date(timeIntervalSince1970: 0),
            cash: 200_000,
            advances: [50_000, 25_000, 0]
        )
        let lines = HistoryExport.csv([record])
            .split(separator: "\n")
            .map(String.init)

        XCTAssertEqual(
            lines[0],
            "saved_at,cash_in_hand,imran_took,bambang_took,danii_took," +
            "total_pot,imran_share,bambang_share,danii_share," +
            "imran_gets,bambang_gets,danii_gets"
        )
        XCTAssertEqual(
            lines[1],
            "1970-01-01T00:00:00Z,2000.00,500.00,250.00,0.00," +
            "2750.00,916.67,916.67,916.66,416.67,666.67,916.66"
        )
    }

    func testNegativePayoutIsSigned() {
        let record = SplitRecord(
            date: Date(timeIntervalSince1970: 0),
            cash: 10_000,
            advances: [20_000, 0, 0]
        )
        let row = HistoryExport.csv([record])
            .split(separator: "\n")
            .map(String.init)[1]

        XCTAssertTrue(row.hasSuffix(",-100.00,100.00,100.00"))
    }

    func testEmptyHistoryStillHasAHeader() {
        let lines = HistoryExport.csv([])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].hasPrefix("saved_at,cash_in_hand"))
        XCTAssertEqual(Money.decimal(275_000), "2750.00")
        XCTAssertEqual(Money.decimal(-10_000), "-100.00")
    }
}
