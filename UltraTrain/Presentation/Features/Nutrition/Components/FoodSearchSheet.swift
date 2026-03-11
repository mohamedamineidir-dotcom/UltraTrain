import SwiftUI

struct FoodSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let foodService: any FoodDatabaseServiceProtocol
    private let onProductSelected: (FoodSearchResult) -> Void

    @State private var searchText = ""
    @State private var results: [FoodSearchResult] = []
    @State private var isSearchingOnline = false
    @State private var hasSearched = false
    @State private var apiFailed = false
    @State private var searchTask: Task<Void, Never>?

    init(
        foodService: any FoodDatabaseServiceProtocol,
        onProductSelected: @escaping (FoodSearchResult) -> Void
    ) {
        self.foodService = foodService
        self.onProductSelected = onProductSelected
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty && !hasSearched {
                    ContentUnavailableView(
                        "Search Food Products",
                        systemImage: "magnifyingglass",
                        description: Text("Type a food name to search.")
                    )
                } else if results.isEmpty && hasSearched && !isSearchingOnline {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    resultsList
                }
            }
            .searchable(text: $searchText, prompt: "Search foods...")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                apiFailed = false
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else {
                    results = []
                    hasSearched = false
                    isSearchingOnline = false
                    return
                }

                // Instant local results
                let localResults = CommonFoodDatabase.search(trimmed)
                results = localResults
                hasSearched = true

                // Async API search with debounce
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    guard !Task.isCancelled else { return }
                    await performOnlineSearch(query: trimmed, localResults: localResults)
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var resultsList: some View {
        List {
            ForEach(results) { result in
                Button {
                    onProductSelected(result)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        if let brand = result.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        HStack(spacing: 12) {
                            if let cal = result.caloriesPer100g {
                                Text("\(cal) kcal")
                                    .fontWeight(.medium)
                            }
                            if let carbs = result.carbsPer100g {
                                Text("C: \(Int(carbs))g")
                            }
                            if let protein = result.proteinPer100g {
                                Text("P: \(Int(protein))g")
                            }
                            if let fat = result.fatPer100g {
                                Text("F: \(Int(fat))g")
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                        Text("per 100g")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }

            // Online search status footer
            if isSearchingOnline {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching online...")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
            } else if apiFailed && !results.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("Showing offline results only")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
            }
        }
    }

    @MainActor
    private func performOnlineSearch(query: String, localResults: [FoodSearchResult]) async {
        isSearchingOnline = true
        defer { isSearchingOnline = false }

        do {
            let allResults = try await foodService.searchByName(query)
            guard !Task.isCancelled else { return }
            results = allResults
            apiFailed = false
        } catch {
            guard !Task.isCancelled else { return }
            // Keep local results, mark API as failed
            apiFailed = true
        }
    }
}
