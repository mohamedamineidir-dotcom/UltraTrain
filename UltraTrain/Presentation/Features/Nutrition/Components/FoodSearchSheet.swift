import SwiftUI

struct FoodSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let foodService: any FoodDatabaseServiceProtocol
    private let onProductSelected: (FoodSearchResult) -> Void

    @State private var searchText = ""
    @State private var results: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
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
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty && hasSearched {
                    ContentUnavailableView.search(text: searchText)
                } else if results.isEmpty {
                    ContentUnavailableView(
                        "Search Food Products",
                        systemImage: "magnifyingglass",
                        description: Text("Type a food name to search the Open Food Facts database.")
                    )
                } else {
                    resultsList
                }
            }
            .searchable(text: $searchText, prompt: "Search foods...")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                guard !newValue.trimmingCharacters(in: .whitespaces).isEmpty else {
                    results = []
                    hasSearched = false
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await performSearch(query: newValue)
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
        }
    }

    @MainActor
    private func performSearch(query: String) async {
        isSearching = true
        defer {
            isSearching = false
            hasSearched = true
        }
        do {
            results = try await foodService.searchByName(query)
        } catch {
            results = []
        }
    }
}
