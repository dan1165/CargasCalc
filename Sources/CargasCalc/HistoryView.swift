import SwiftUI
import CargasCalcCore

struct HistoryView: View {
    @Environment(HistoryStore.self) private var history
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Group {
                if history.records.isEmpty {
                    ContentUnavailableView(
                        "No saved splits",
                        systemImage: "clock",
                        description: Text("Tap Save to history to keep a calculation.")
                    )
                } else {
                    List {
                        ForEach(history.records) { record in
                            NavigationLink {
                                RecordDetailView(id: record.id)
                            } label: {
                                HistoryRow(record: record)
                            }
                        }
                        .onDelete { history.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !history.records.isEmpty {
                        Button("Clear", role: .destructive) {
                            confirmClear = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Clear all saved splits?",
                isPresented: $confirmClear,
                titleVisibility: .visible
            ) {
                Button("Clear all", role: .destructive) {
                    history.clear()
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let record: SplitRecord

    var body: some View {
        let split = record.split

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Money.format(split.pot))
                    .font(.headline.monospacedDigit())
            }

            HStack(spacing: 12) {
                ForEach(Split.people.indices, id: \.self) { index in
                    Text("\(Split.people[index]) \(Money.format(split.payouts[index]))")
                        .font(.caption.monospacedDigit())
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct RecordDetailView: View {
    @Environment(HistoryStore.self) private var history
    let id: UUID
    @State private var isEditing = false

    private var record: SplitRecord? {
        history.records.first { $0.id == id }
    }

    var body: some View {
        if let record {
            Form {
                Section("Results") {
                    SplitBreakdown(split: record.split)
                }

                Section("Inputs") {
                    LabeledContent("Cash in hand", value: Money.format(record.cash))
                    LabeledContent("Taken early", value: Money.format(record.advances.reduce(0, +)))
                }

                Section {
                    Text("Saved \(record.date.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Saved split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: record.summary) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")

                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditSplitView(record: record)
            }
        } else {
            ContentUnavailableView("Split deleted", systemImage: "trash")
        }
    }
}

private struct EditSplitView: View {
    @Environment(HistoryStore.self) private var history
    @Environment(\.dismiss) private var dismiss

    let record: SplitRecord
    @State private var cashText: String
    @State private var advanceTexts: [String]

    init(record: SplitRecord) {
        self.record = record
        _cashText = State(initialValue: Self.text(for: record.cash))
        _advanceTexts = State(initialValue: record.advances.map { Self.text(for: $0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cash in hand") {
                    TextField("", text: $cashText)
                        .keyboardType(.decimalPad)
                }

                Section("Taken early") {
                    ForEach(Split.people.indices, id: \.self) { index in
                        LabeledContent(Split.people[index]) {
                            TextField("", text: $advanceTexts[index])
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("Edit split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        history.update(
                            record.id,
                            cash: Money.parse(cashText),
                            advances: advanceTexts.map(Money.parse)
                        )
                        dismiss()
                    }
                }
            }
        }
    }

    private static func text(for cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
}
