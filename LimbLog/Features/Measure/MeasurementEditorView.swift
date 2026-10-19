import SwiftUI
import SwiftData
import PhotosUI

/// Type one circumference per tape point. Fields prefill from the last measurement of that side.
struct MeasurementEditorView: View {
    let profile: LimbProfile
    @State var side: Side
    let existing: LimbMeasurement?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Query(sort: \LimbMeasurement.date, order: .reverse) private var measurements: [LimbMeasurement]

    @State private var date: Date = .now
    /// Entered in the profile's unit, keyed by distanceCm.
    @State private var entered: [Double: String] = [:]
    @State private var notes = ""
    @State private var photo: Data?
    @State private var pickerItem: PhotosPickerItem?
    @FocusState private var focused: Double?

    private var unit: LengthUnit { profile.unit }

    private var seriesCm: [(distanceCm: Double, circumferenceCm: Double)] {
        profile.points.compactMap { point in
            guard let text = entered[point.distanceCm], let value = Double(text.replacingOccurrences(of: ",", with: ".")), value > 0 else { return nil }
            return (point.distanceCm, unit.toCm(value))
        }
    }

    private var canSave: Bool { seriesCm.count >= 2 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Side", selection: $side) {
                        ForEach(Side.allCases) { s in Text(s == profile.affectedSide ? "\(s.name) (affected)" : s.name).tag(s) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(existing != nil)
                    DatePicker("When", selection: $date)
                }
                Section {
                    ForEach(profile.points) { point in
                        HStack {
                            Text(point.label)
                            Spacer()
                            TextField("0.0", text: Binding(get: { entered[point.distanceCm] ?? "" }, set: { entered[point.distanceCm] = $0 }))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($focused, equals: point.distanceCm)
                                .submitLabel(.next)
                            Text(unit.rawValue).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
                        }
                    }
                } header: {
                    Text("Circumference from the \(profile.limbType.landmark)")
                } footer: {
                    Text(canSave ? "Estimated volume: \(Formatters.volume(VolumeMath.frustumVolume(seriesCm)))" : "Enter at least two points to estimate volume.")
                        .font(.footnote.weight(.semibold))
                }
                Section("Notes and photo") {
                    TextField("Time of day, posture, swelling you noticed…", text: $notes)
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 8))
                        Button("Remove photo", role: .destructive) { self.photo = nil }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(photo == nil ? "Add photo" : "Replace photo", systemImage: "photo")
                    }
                }
                Section {
                    Text("Same time of day, same posture, tape snug but not tight. Measure the other side the same day so the app can compare them.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(existing == nil ? "Measure" : "Edit Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().disabled(!canSave) }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Next") { advance() }
                }
            }
            .onAppear(perform: load)
            .onChange(of: side) { if existing == nil { prefill() } }
            .onChange(of: pickerItem) {
                guard let pickerItem else { return }
                Task { if let data = try? await pickerItem.loadTransferable(type: Data.self) { photo = ImageCompressor.compress(data) } }
            }
        }
    }

    private func load() {
        if let existing {
            date = existing.date
            side = existing.side
            entered = existing.values.mapValues { String(format: "%.1f", unit.display(cm: $0)) }
            notes = existing.notes
            photo = existing.photo
        } else {
            prefill()
            focused = profile.points.first?.distanceCm
        }
    }

    private func prefill() {
        guard let last = measurements.first(where: { $0.profileID == profile.id && $0.side == side }) else { entered = [:]; return }
        entered = last.values.mapValues { String(format: "%.1f", unit.display(cm: $0)) }
    }

    private func advance() {
        let ids = profile.points.map(\.distanceCm)
        guard let current = focused, let index = ids.firstIndex(of: current), index + 1 < ids.count else { focused = nil; return }
        focused = ids[index + 1]
    }

    private func save() {
        let target = existing ?? LimbMeasurement(profile: profile, side: side, date: date)
        target.date = date
        target.side = side
        target.values = Dictionary(uniqueKeysWithValues: seriesCm.map { ($0.distanceCm, $0.circumferenceCm) })
        target.notes = notes
        target.photo = photo
        if existing == nil { context.insert(target) }
        ReviewPrompter.recordSuccess(request: requestReview)
        dismiss()
    }
}

enum ImageCompressor {
    static func compress(_ data: Data, maxDimension: CGFloat = 1200) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
