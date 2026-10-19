import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry { SnapshotEntry(date: .now, snapshot: .placeholder) }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [SnapshotEntry(date: .now, snapshot: WidgetSnapshot.load())], policy: .after(midnight)))
    }
}

struct LimbLogWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry
    private var s: WidgetSnapshot { entry.snapshot }

    private func volume(_ ml: Double) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.maximumFractionDigits = 0
        return "\(n.string(from: NSNumber(value: ml.rounded())) ?? "\(Int(ml))") mL"
    }

    private func signed(_ v: Double, suffix: String) -> String {
        let sign = v > 0 ? "+" : v < 0 ? "−" : ""
        return sign + (suffix == "%" ? String(format: "%.1f%%", abs(v)) : volume(abs(v)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(s.limbLabel.isEmpty ? AppConfig.appName : "\(s.limbLabel) · \(AppConfig.appName)")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary).lineLimit(1)
            if !s.hasProfile {
                Text("Set up the limb").font(.headline)
            } else if let latest = s.latestVolumeML {
                Text(volume(latest)).font(.system(size: 26, weight: .bold, design: .rounded)).monospacedDigit()
                if let p = s.percentVsOtherSide {
                    Text("\(signed(p, suffix: "%")) vs other side").font(.caption).foregroundStyle(p > 10 ? .orange : .secondary)
                }
                if family != .systemSmall, let c = s.changeSinceBaselineML {
                    Text("\(signed(c, suffix: "mL")) since baseline").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("No measurements yet").font(.headline)
            }
            Spacer(minLength: 0)
            if let due = s.nextDue {
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: entry.date), to: due).day ?? 0
                Text(days <= 0 ? "Measurement due" : "Next measurement in \(days)d").font(.caption2).foregroundStyle(days <= 0 ? .orange : .secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LimbLogWidget: Widget {
    let kind = "LimbLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { LimbLogWidgetView(entry: $0) }
            .configurationDisplayName(AppConfig.appName)
            .description("Latest estimated volume, side-to-side difference and when the next measurement is due.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LimbLogWidgetBundle: WidgetBundle {
    var body: some Widget { LimbLogWidget() }
}
