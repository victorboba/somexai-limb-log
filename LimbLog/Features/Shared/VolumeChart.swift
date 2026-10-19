import SwiftUI
import Charts

/// Estimated volume per measurement, one line per side. Used in History and rendered into the PDF.
struct VolumeChart: View {
    let measurements: [LimbMeasurement]
    let profile: LimbProfile

    private var rows: [(date: Date, side: String, ml: Double)] {
        measurements.filter { $0.profileID == profile.id }.sorted { $0.date < $1.date }
            .map { ($0.date, $0.side == profile.affectedSide ? "\($0.side.name) (affected)" : $0.side.name, $0.volumeML) }
    }

    private var domain: ClosedRange<Double> {
        let values = rows.map(\.ml)
        guard let lo = values.min(), let hi = values.max(), hi > lo else { return 0...3000 }
        let pad = (hi - lo) * 0.25
        return max(0, lo - pad)...(hi + pad)
    }

    var body: some View {
        Chart {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                LineMark(x: .value("Date", row.date), y: .value("Volume", row.ml))
                    .foregroundStyle(by: .value("Side", row.side))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Date", row.date), y: .value("Volume", row.ml))
                    .foregroundStyle(by: .value("Side", row.side))
            }
        }
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v))") } }
            }
        }
        .chartYAxisLabel("mL")
        .chartLegend(position: .top, alignment: .leading)
    }
}
