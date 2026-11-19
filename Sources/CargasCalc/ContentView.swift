import SwiftUI
import CargasCalcCore

private enum MoneyInput: Hashable {
    case cash
    case advance(Int)
}

struct ContentView: View {
    @Environment(HistoryStore.self) private var history
    @State private var cashText = ""
    @State private var advanceTexts = ["", "", ""]
    @State private var showHistory = false
    @State private var savePulse = 0
    @State private var justSaved = false
    @FocusState private var focused: MoneyInput?

    private var split: Split {
        Split(cash: Money.parse(cashText), advances: advanceTexts.map(Money.parse))
    }

    private var hasAmount: Bool { split.pot > 0 }

    private var hasInput: Bool {
        !cashText.isEmpty || advanceTexts.contains { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Transit.ground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        cashBlock
                            .padding(.top, 10)

                        potBlock
                            .padding(.top, 30)

                        Hairline()
                            .padding(.top, 26)

                        stationBlock

                        saveBlock
                            .padding(.top, 28)
                            .padding(.bottom, 36)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("CargasCalc")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset amounts")
                    .disabled(!hasInput)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focused = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .presentationBackground(Transit.ink)
                .presentationDragIndicator(.visible)
        }
    }

    private var cashBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Cash in hand")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Transit.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("RM")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Transit.secondary)

                TextField("0.00", text: $cashText)
                    .font(.system(.largeTitle, design: .default, weight: .light).monospacedDigit())
                    .foregroundStyle(Transit.porcelain)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: .cash)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel("Cash in hand in ringgit")
            }

            Hairline()
        }
    }

    private var potBlock: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                metric("Total pot", split.pot)
                Spacer(minLength: 20)
                metric("Each share", split.shares.first ?? 0)
            }

            PotRouteBar(split: split)
        }
    }

    private func metric(_ title: String, _ cents: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Transit.secondary)
            MoneyFigure(cents: cents, size: .compact)
        }
    }

    private var stationBlock: some View {
        VStack(spacing: 0) {
            ForEach(Split.people.indices, id: \.self) { index in
                stationRow(index)
            }
        }
    }

    private func stationRow(_ index: Int) -> some View {
        let payout = split.payouts[index]

        return HStack(alignment: .top, spacing: 14) {
            StationRail(
                color: Transit.line(index),
                isLast: index == Split.people.count - 1
            )

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Split.people[index])
                            .font(.headline)
                            .foregroundStyle(Transit.porcelain)
                        Text("share \(Money.format(split.shares[index]))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Transit.secondary)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        if payout < 0 {
                            Text("owes \(Money.format(-payout))")
                                .font(.system(.title3, design: .default, weight: .light).monospacedDigit())
                                .foregroundStyle(Transit.porcelain)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("over the share")
                                .font(.caption2)
                                .foregroundStyle(Transit.secondary)
                        } else {
                            MoneyFigure(cents: payout)
                            Text("gets now")
                                .font(.caption2)
                                .foregroundStyle(Transit.secondary)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Text("Took early")
                        .font(.caption)
                        .foregroundStyle(Transit.secondary)

                    Spacer(minLength: 4)

                    Text("RM")
                        .font(.caption2)
                        .foregroundStyle(Transit.tertiary)

                    TextField("0.00", text: $advanceTexts[index])
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(Transit.porcelain)
                        .focused($focused, equals: .advance(index))
                        .frame(width: 92)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 9)
                        .background(
                            Transit.panel,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .accessibilityLabel(
                            "Amount \(Split.people[index]) took early, in ringgit"
                        )
                }
            }
        }
        .padding(.vertical, 14)
    }

    private var saveBlock: some View {
        VStack(spacing: 11) {
            Button {
                history.save(split)
                savePulse += 1
            } label: {
                Label(
                    justSaved ? "Saved to history" : "Save split",
                    systemImage: justSaved ? "checkmark" : "square.and.arrow.down"
                )
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!hasAmount)
            .opacity(hasAmount ? 1 : 0.38)
            .sensoryFeedback(.success, trigger: savePulse)

            Text("Payouts always add up to the cash in hand.")
                .font(.footnote)
                .foregroundStyle(Transit.tertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .task(id: savePulse) {
            guard savePulse > 0 else { return }
            justSaved = true
            try? await Task.sleep(for: .seconds(1.6))
            justSaved = false
        }
    }

    private func reset() {
        focused = nil
        cashText = ""
        advanceTexts = Array(repeating: "", count: Split.people.count)
    }
}
