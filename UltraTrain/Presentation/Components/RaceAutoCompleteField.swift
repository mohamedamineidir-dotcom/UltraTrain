import SwiftUI

struct RaceAutoCompleteField: View {
    @Binding var text: String
    let onRaceSelected: (KnownRace) -> Void

    @State private var suggestions: [KnownRace] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var showSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Race Name (e.g. UTMB, Diagonale des Fous)", text: $text)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .accessibilityIdentifier("raceNameField")
                .onChange(of: text) { _, newValue in
                    debounceSearch(query: newValue)
                }

            if showSuggestions && !suggestions.isEmpty {
                suggestionsList
            }
        }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions.prefix(5)) { race in
                Button {
                    selectRace(race)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(race.name)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.label)
                        Text("\(Int(race.distanceKm)) km · D+ \(Int(race.elevationGainM)) m · \(race.country)")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Theme.Spacing.xs)
                    .padding(.horizontal, Theme.Spacing.sm)
                }
                .buttonStyle(.plain)

                if race.id != suggestions.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            suggestions = []
            showSuggestions = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(AppConstants.Debounce.searchMilliseconds))
            guard !Task.isCancelled else { return }
            let results = RaceDatabase.search(query: query)
            suggestions = results
            showSuggestions = !results.isEmpty
        }
    }

    private func selectRace(_ race: KnownRace) {
        text = race.name
        suggestions = []
        showSuggestions = false
        searchTask?.cancel()
        onRaceSelected(race)
    }
}
