import SwiftUI

struct GearListView: View {
    @State private var viewModel: GearListViewModel
    private let gearRepository: any GearRepository
    private let runRepository: any RunRepository

    init(gearRepository: any GearRepository, runRepository: any RunRepository) {
        _viewModel = State(initialValue: GearListViewModel(gearRepository: gearRepository))
        self.gearRepository = gearRepository
        self.runRepository = runRepository
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.gearItems.isEmpty {
                emptyState
            } else {
                activeSection
                if !viewModel.retiredGear.isEmpty {
                    retiredSection
                }
            }
        }
        .navigationTitle("Gear")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingAddGear = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add gear")
                .accessibilityHint("Opens the add gear form")
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $viewModel.showingAddGear) {
            EditGearSheet(mode: .add) { newItem in
                Task { await viewModel.addGear(newItem) }
            }
        }
        .sheet(item: $viewModel.gearToEdit) { item in
            EditGearSheet(mode: .edit(item)) { updated in
                Task { await viewModel.updateGear(updated) }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Section {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "shoe.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
                Text("No Gear Yet")
                    .font(.headline)
                Text("Add your trail shoes and other gear to track their mileage and know when to replace them.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                Button("Add Gear") {
                    viewModel.showingAddGear = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
        }
    }

    // MARK: - Active Section

    private var activeSection: some View {
        Section {
            ForEach(viewModel.activeGear) { item in
                NavigationLink {
                    GearDetailView(
                        item: item,
                        gearRepository: gearRepository,
                        runRepository: runRepository
                    )
                } label: {
                    GearRowView(item: item)
                }
                .swipeActions(edge: .trailing) {
                    Button("Retire") {
                        Task { await viewModel.retireGear(item) }
                    }
                    .tint(.orange)

                    Button("Edit") {
                        viewModel.gearToEdit = item
                    }
                    .tint(.blue)
                }
            }
        } header: {
            Text("Active")
        }
    }

    // MARK: - Retired Section

    private var retiredSection: some View {
        Section {
            ForEach(viewModel.retiredGear) { item in
                GearRowView(item: item)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteGear(id: item.id) }
                        }
                    }
            }
        } header: {
            Text("Retired")
        }
    }
}
