import SwiftUI

struct RacePrepChecklistView: View {
    @State private var viewModel: RacePrepChecklistViewModel
    @State private var showResetConfirmation = false

    init(race: Race, repository: any RacePrepChecklistRepository) {
        _viewModel = State(initialValue: RacePrepChecklistViewModel(
            race: race,
            repository: repository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading checklist...")
            } else if viewModel.checklist != nil {
                checklistContent
            } else {
                ContentUnavailableView(
                    "No Checklist",
                    systemImage: "checklist",
                    description: Text("Unable to load the checklist.")
                )
            }
        }
        .navigationTitle("Race Prep")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { viewModel.showAddItem = true } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    Button(role: .destructive) { showResetConfirmation = true } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Checklist options")
                .accessibilityHint("Opens menu to add items or reset checklist")
            }
        }
        .sheet(isPresented: $viewModel.showAddItem) {
            AddChecklistItemSheet { name, category, notes in
                Task { await viewModel.addItem(name: name, category: category, notes: notes) }
            }
        }
        .confirmationDialog("Reset Checklist", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                Task { await viewModel.resetChecklist() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all items with the default checklist for this race. Custom items will be removed.")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .task {
            await viewModel.load()
        }
    }

    private var checklistContent: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                progressHeader
                ForEach(viewModel.groupedItems, id: \.category) { group in
                    categorySection(group.category, items: group.items)
                }
            }
            .padding()
        }
    }

    private var progressHeader: some View {
        let progress = viewModel.totalProgress
        return HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("\(progress.checked) of \(progress.total) items")
                    .font(.headline)
                if progress.total > 0 {
                    ProgressView(value: Double(progress.checked), total: Double(progress.total))
                        .tint(progress.checked == progress.total ? Theme.Colors.success : Theme.Colors.primary)
                }
            }
            Spacer()
            if progress.checked == progress.total && progress.total > 0 {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityLabel("All items checked")
            }
        }
        .cardStyle()
    }

    private func categorySection(_ category: ChecklistCategory, items: [ChecklistItem]) -> some View {
        let checked = items.filter(\.isChecked).count
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(category.displayName, systemImage: category.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Text("\(checked)/\(items.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(.bottom, Theme.Spacing.xs)

            ForEach(items) { item in
                ChecklistItemRow(item: item) {
                    Task { await viewModel.toggleItem(item.id) }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if item.isCustom {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteItem(item.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}
