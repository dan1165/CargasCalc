import Foundation
import Observation
import SwiftUI
import CargasCalcCore

@MainActor
@Observable
final class HistoryStore {
    private(set) var records: [SplitRecord] = []

    private static let key = "CargasCalcHistory"

    init() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let saved = try? JSONDecoder().decode([SplitRecord].self, from: data) else {
            return
        }
        records = saved
    }

    func save(_ split: Split) {
        records.insert(SplitRecord(cash: split.cash, advances: split.advances), at: 0)
        persist()
    }

    func update(_ id: UUID, cash: Int, advances: [Int]) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index] = SplitRecord(
            id: id,
            date: records[index].date,
            cash: cash,
            advances: advances
        )
        persist()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persist()
    }

    func clear() {
        records.removeAll()
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
