import SwiftUI

struct ManualStatsEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let onSave: (Double?, TimeInterval?, Double?) -> Void

    @State private var distanceText: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var elevationText: String

    init(session: TrainingSession, onSave: @escaping (Double?, TimeInterval?, Double?) -> Void) {
        self.session = session
        self.onSave = onSave
        let planned = session.plannedDuration
        _distanceText = State(initialValue: session.plannedDistanceKm > 0
            ? String(format: "%.1f", session.plannedDistanceKm) : "")
        _hours = State(initialValue: Int(planned) / 3600)
        _minutes = State(initialValue: (Int(planned) % 3600) / 60)
        _elevationText = State(initialValue: session.plannedElevationGainM > 0
            ? String(format: "%.0f", session.plannedElevationGainM) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Stats") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("km", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h)h").tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { m in
                                Text("\(m)m").tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                    }

                    HStack {
                        Text("Elevation")
                        Spacer()
                        TextField("m", text: $elevationText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("m D+")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }

                Section {
                    Button {
                        let dist = Double(distanceText.replacingOccurrences(of: ",", with: "."))
                        let dur = TimeInterval(hours * 3600 + minutes * 60)
                        let elev = Double(elevationText)
                        onSave(dist, dur > 0 ? dur : nil, elev)
                        dismiss()
                    } label: {
                        Label("Save & Complete", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.Colors.success)
                    }
                }

                Section {
                    Button {
                        onSave(nil, nil, nil)
                        dismiss()
                    } label: {
                        Text("Skip — Mark Complete Without Stats")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
            .navigationTitle("Enter Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
