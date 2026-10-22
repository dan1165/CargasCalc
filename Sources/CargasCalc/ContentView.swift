import SwiftUI
import CargasCalcCore

struct ContentView: View {
    @Environment(HistoryStore.self) private var history
    @State private var cashText = ""
    @State private var advanceTexts = ["", "", ""]
    @State private var showHistory = false

    private var split: Split {
        Split(cash: Money.parse(cashText), advances: advanceTexts.map(Money.parse))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cash in hand") {
                    moneyField($cashText)
                }

                Section("Taken early") {
                    ForEach(Split.people.indices, id: \.self) { index in
                        LabeledContent(Split.people[index]) {
                            moneyField($advanceTexts[index])
                        }
                    }
                }

                Section("Results") {
                    SplitBreakdown(split: split)
                }

                Section {
                    Button {
                        history.save(split)
                    } label: {
                        Label("Save to history", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("CargasCalc")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        cashText = ""
                        advanceTexts = ["", "", ""]
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
    }

    private func moneyField(_ text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text("RM")
                .foregroundStyle(.secondary)
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }
}

/// Shared by the calculator and a saved split.
struct SplitBreakdown: View {
    let split: Split

    var body: some View {
        LabeledContent("Total pot") {
            Text(Money.format(split.pot))
                .font(.headline.monospacedDigit())
        }

        ForEach(Split.people.indices, id: \.self) { index in
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(Split.people[index])
                    Spacer()
                    Text(Money.format(split.payouts[index]))
                        .font(.headline.monospacedDigit())
                }
                Text("took \(Money.format(split.advances[index])) · share \(Money.format(split.shares[index]))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
