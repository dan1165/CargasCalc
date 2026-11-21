import Foundation
import SwiftUI
import UIKit
import CargasCalcCore

/// The saved split as a shareable card, rendered at 3× for a sharp PNG.
struct SplitShareCard: View {
    let record: SplitRecord

    private var split: Split { record.split }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("CARGASCALC")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Transit.secondary)
                Spacer(minLength: 8)
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(Transit.tertiary)
            }

            Text("Total pot")
                .font(.system(size: 12))
                .foregroundStyle(Transit.secondary)
                .padding(.top, 24)

            MoneyFigure(cents: split.pot, size: .display)
                .padding(.top, 2)

            PotRouteBar(split: split)
                .padding(.top, 18)

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
            .padding(.top, 6)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline) {
                Text("Three equal shares · exact to the sen")
                    .font(.system(size: 10))
                    .foregroundStyle(Transit.tertiary)
                Spacer(minLength: 8)
                Text("RM")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Transit.secondary)
            }
        }
        .padding(24)
        .frame(width: 390, height: 560, alignment: .top)
        .background(Transit.ground)
    }
}

@MainActor
enum SplitImageRenderer {
    static func render(_ record: SplitRecord) -> UIImage? {
        let renderer = ImageRenderer(content: SplitShareCard(record: record))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
