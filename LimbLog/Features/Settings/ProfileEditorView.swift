import SwiftUI
import SwiftData

/// Limb, affected side, units, tape points, therapist, schedule.
struct ProfileEditorView: View {
    let profile: LimbProfile?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var limbType: LimbType = .arm
    @State private var affectedSide: Side = .right
    @State private var unit: LengthUnit = .cm
    @State private var points: [MeasurePoint] = LimbType.arm.defaultPoints
    @State private var newLabel = ""
    @State private var newDistance = ""
    @State private var therapistName = ""
    @State private var hasAppointment = false
    @State private var nextAppointment = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var measureEveryDays = AppConfig.defaultMeasureEveryDays
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Who") {
                    TextField("Name (optional)", text: $name)
                }
                Section("Limb") {
                    Picker("Limb", selection: $limbType) { ForEach(LimbType.allCases) { Text($0.name).tag($0) } }
                        .pickerStyle(.segmented)
                        .onChange(of: limbType) { _, new in if profile == nil { points = new.defaultPoints } }
                    Picker("Affected side", selection: $affectedSide) { ForEach(Side.allCases) { Text($0.name).tag($0) } }
                        .pickerStyle(.segmented)
                    Picker("Units", selection: $unit) { ForEach(LengthUnit.allCases) { Text($0.name).tag($0) } }
                }
                Section {
                    ForEach(points) { point in
                        HStack {
                            Text(point.label)
                            Spacer()
                            Text("\(Int(point.distanceCm)) cm").foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                    .onDelete { points.remove(atOffsets: $0) }
                    HStack {
                        TextField("Label (e.g. Elbow)", text: $newLabel)
                        TextField("cm", text: $newDistance).keyboardType(.decimalPad).frame(width: 56)
                        Button("Add") {
                            guard let d = Double(newDistance.replacingOccurrences(of: ",", with: ".")), !newLabel.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            points.append(MeasurePoint(label: newLabel.trimmingCharacters(in: .whitespaces), distanceCm: d))
                            points.sort { $0.distanceCm < $1.distanceCm }
                            newLabel = ""
                            newDistance = ""
                        }
                        .disabled(newLabel.isEmpty || Double(newDistance.replacingOccurrences(of: ",", with: ".")) == nil)
                    }
                    Button("Reset to \(limbType.name.lowercased()) defaults") { points = limbType.defaultPoints }
                } header: {
                    Text("Tape points, distance from the \(limbType.landmark)")
                } footer: {
                    Text("Use the same points your therapist uses so your numbers line up with theirs. Volume is estimated between consecutive points; at least two are needed.")
                }
                Section("Schedule") {
                    Stepper("Measure every \(measureEveryDays) day\(measureEveryDays == 1 ? "" : "s")", value: $measureEveryDays, in: 1...60)
                }
                Section("Clinic") {
                    TextField("Therapist or clinic", text: $therapistName)
                    Toggle("Next appointment scheduled", isOn: $hasAppointment)
                    if hasAppointment { DatePicker("Next appointment", selection: $nextAppointment, displayedComponents: .date) }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle(profile == nil ? "Limb Setup" : "Edit Limb Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().disabled(points.count < 2) }
            }
            .onAppear {
                guard let profile else { return }
                name = profile.name
                limbType = profile.limbType
                affectedSide = profile.affectedSide
                unit = profile.unit
                points = profile.points
                therapistName = profile.therapistName
                hasAppointment = profile.nextAppointment != nil
                nextAppointment = profile.nextAppointment ?? nextAppointment
                measureEveryDays = profile.measureEveryDays
                notes = profile.notes
            }
        }
    }

    private func save() {
        let target = profile ?? LimbProfile()
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.limbType = limbType
        target.affectedSide = affectedSide
        target.unit = unit
        target.points = points
        target.therapistName = therapistName
        target.nextAppointment = hasAppointment ? nextAppointment : nil
        target.measureEveryDays = measureEveryDays
        target.notes = notes
        if profile == nil { context.insert(target) }
        dismiss()
    }
}
