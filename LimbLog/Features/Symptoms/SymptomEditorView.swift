import SwiftUI
import SwiftData

struct SymptomEditorView: View {
    let profile: LimbProfile
    let existing: SymptomEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var heaviness = 0
    @State private var tightness = 0
    @State private var pain = 0
    @State private var skin: Set<SkinSign> = []
    @State private var therapies: Set<Therapy> = []
    @State private var garmentHours = 0.0
    @State private var notes = ""
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section { DatePicker("When", selection: $date) }
                Section("How it feels (0 none – 3 severe)") {
                    scale("Heaviness", $heaviness)
                    scale("Tightness", $tightness)
                    scale("Pain", $pain)
                }
                Section("Skin") {
                    ChipPicker(options: SkinSign.allCases, label: { $0.rawValue }, selection: $skin)
                }
                Section("Therapy done") {
                    ChipPicker(options: Therapy.allCases, label: { $0.rawValue }, selection: $therapies)
                    Stepper("Compression garment worn: \(Formatters.hours(garmentHours))", value: $garmentHours, in: 0...24, step: 0.5)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 70)
                }
                Section {
                    Text("Sudden swelling with redness, warmth or fever can mean an infection (cellulitis). Contact your clinic the same day. This app only records what you noticed.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if existing != nil {
                    Section { Button("Delete entry", role: .destructive) { confirmingDelete = true } }
                }
            }
            .navigationTitle(existing == nil ? "Symptoms" : "Edit Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .onAppear {
                guard let existing else { return }
                date = existing.date
                heaviness = existing.heaviness
                tightness = existing.tightness
                pain = existing.pain
                skin = Set(existing.skinSigns)
                therapies = Set(existing.therapies)
                garmentHours = existing.garmentHours
                notes = existing.notes
            }
            .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let existing { context.delete(existing) }; dismiss() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func scale(_ label: String, _ value: Binding<Int>) -> some View {
        Picker(label, selection: value) {
            ForEach(0...3, id: \.self) { Text("\($0)").tag($0) }
        }
        .pickerStyle(.segmented)
        .overlay(alignment: .leading) { Text(label).font(.caption).foregroundStyle(.secondary).offset(y: -22) }
        .padding(.top, 18)
    }

    private func save() {
        let target = existing ?? SymptomEntry(profile: profile, date: date)
        target.date = date
        target.heaviness = heaviness
        target.tightness = tightness
        target.pain = pain
        target.skinSigns = Array(skin)
        target.therapies = Array(therapies)
        target.garmentHours = garmentHours
        target.notes = notes
        if existing == nil { context.insert(target) }
        dismiss()
    }
}
