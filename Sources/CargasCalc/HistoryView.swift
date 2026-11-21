import Foundation
import SwiftUI
import CargasCalcCore

struct HistoryView: View {
    @Environment(HistoryStore.self) private var history
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var exportFailed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Transit.ground
                    .ignoresSafeArea()

                if history.records.isEmpty {
                    ContentUnavailableView {
                        Label("No saved splits", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Save a calculation and it will wait here.")
                    }
                } else {
                    List {
                        ForEach(history.records) { record in
                            NavigationLink {
                                RecordDetailView(id: record.id)
                            } label: {
                                HistoryRow(record: record)
                            }
                            .listRowBackground(Transit.panel)
                            .listRowSeparatorTint(Transit.hairline)
                        }
                        .onDelete { history.delete(at: $0) }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
                    if !history.records.isEmpty {
                        Button {
                            exportCSV()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export history")
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
            .sheet(isPresented: $showShare) {
                ActivitySheet(items: shareItems)
            }
            .alert("Couldn't export history", isPresented: $exportFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try again.")
            }
        }
    }

    private func exportCSV() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let name = "CargasCalc-history-\(formatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)

        do {
            try HistoryExport.csv(history.records)
                .write(to: url, atomically: true, encoding: .utf8)
            shareItems = [url]
            showShare = true
        } catch {
            exportFailed = true
        }
    }
}

private struct HistoryRow: View {
    let record: SplitRecord
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let split = record.split

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Transit.secondary)
                Spacer(minLength: 8)
                MoneyFigure(cents: split.pot, size: .compact)
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Split.people.indices, id: \.self) { index in
                        payoutPair(index, split: split)
                    }
                }
            } else {
                HStack(spacing: 11) {
                    ForEach(Split.people.indices, id: \.self) { index in
                        payoutPair(index, split: split)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func payoutPair(_ index: Int, split: Split) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Transit.line(index))
                .frame(width: 6, height: 6)
            Text("\(Split.people[index]) \(Money.format(split.payouts[index]))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Transit.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

private enum DetailSheet: String, Identifiable {
    case edit
    case share

    var id: String { rawValue }
}

private struct RecordDetailView: View {
    @Environment(HistoryStore.self) private var history
    let id: UUID
    @State private var activeSheet: DetailSheet?
    @State private var shareItems: [Any] = []

    private var record: SplitRecord? {
        history.records.first { $0.id == id }
    }

    var body: some View {
        ZStack {
            Transit.ground
                .ignoresSafeArea()

            if let record {
                let split = record.split

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(record.date.formatted(date: .long, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Transit.secondary)
                            .padding(.top, 10)

                        Text("Total pot")
                            .font(.caption)
                            .foregroundStyle(Transit.secondary)
                            .padding(.top, 22)
                        MoneyFigure(cents: split.pot, size: .display)
                            .padding(.top, 2)

                        PotRouteBar(split: split)
                            .padding(.top, 18)

                        Hairline()
                            .padding(.top, 6)

                        VStack(spacing: 0) {
                            ForEach(Split.people.indices, id: \.self) { index in
                                StationSummary(
                                    index: index,
                                    split: split,
                                    isFirst: index == 0,
                                    isLast: index == Split.people.count - 1
                                )
                            }
                        }

                        Hairline()

                        HStack {
                            Text("Cash in hand")
                                .font(.subheadline)
                                .foregroundStyle(Transit.secondary)
                            Spacer()
                            MoneyFigure(cents: record.cash, size: .compact)
                        }
                        .padding(.top, 16)

                        HStack {
                            Text("Taken early")
                                .font(.subheadline)
                                .foregroundStyle(Transit.secondary)
                            Spacer()
                            MoneyFigure(cents: record.advances.reduce(0, +), size: .compact)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                ContentUnavailableView("Split deleted", systemImage: "trash")
            }
        }
        .navigationTitle("Saved split")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let record {
                    Button {
                        share(record)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share as image")

                    Button("Edit") {
                        activeSheet = .edit
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                if let record {
                    EditSplitView(record: record)
                        .presentationBackground(Transit.ink)
                }
            case .share:
                ActivitySheet(items: shareItems)
            }
        }
    }

    private func share(_ record: SplitRecord) {
        var items: [Any] = [record.summary]
        if let image = SplitImageRenderer.render(record) {
            items.insert(image, at: 0)
        }
        shareItems = items
        activeSheet = .share
    }
}

private enum EditField: Hashable {
    case cash
    case advance(Int)
}

private struct EditSplitView: View {
    @Environment(HistoryStore.self) private var history
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: EditField?

    let record: SplitRecord
    @State private var cashText: String
    @State private var advanceTexts: [String]

    init(record: SplitRecord) {
        self.record = record
        _cashText = State(initialValue: Self.text(for: record.cash))
        _advanceTexts = State(initialValue: record.advances.map { Self.text(for: $0) })
    }

    private var editedSplit: Split {
        Split(cash: Money.parse(cashText), advances: advanceTexts.map(Money.parse))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 6) {
                        Text("RM")
                            .font(.callout)
                            .foregroundStyle(Transit.secondary)
                            .accessibilityHidden(true)
                        TextField("0.00", text: $cashText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.monospacedDigit())
                            .focused($focused, equals: .cash)
                            .accessibilityLabel("Cash in hand in ringgit")
                    }
                } header: {
                    Text("Cash in hand")
                        .foregroundStyle(Transit.secondary)
                }
                .listRowBackground(Transit.panel)

                Section {
                    ForEach(Split.people.indices, id: \.self) { index in
                        HStack(spacing: 6) {
                            Text(Split.people[index])
                            Spacer(minLength: 12)
                            Text("RM")
                                .font(.callout)
                                .foregroundStyle(Transit.secondary)
                                .accessibilityHidden(true)
                            TextField("0.00", text: $advanceTexts[index])
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.body.monospacedDigit())
                                .focused($focused, equals: .advance(index))
                                .accessibilityLabel(
                                    "Amount \(Split.people[index]) took early, in ringgit"
                                )
                        }
                    }
                } header: {
                    Text("Taken early")
                        .foregroundStyle(Transit.secondary)
                }
                .listRowBackground(Transit.panel)
            }
            .scrollContentBackground(.hidden)
            .background(Transit.ground)
            .scrollDismissesKeyboard(.interactively)
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
                    .disabled(editedSplit.pot == 0)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focused = nil
                    }
                }
            }
        }
    }

    private static func text(for cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
}
