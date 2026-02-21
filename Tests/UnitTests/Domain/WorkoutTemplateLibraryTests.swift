import Foundation
import Testing
@testable import UltraTrain

@Suite("WorkoutTemplateLibrary Tests")
struct WorkoutTemplateLibraryTests {

    @Test("All templates have unique IDs")
    func uniqueIds() {
        let ids = WorkoutTemplateLibrary.all.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("Filter by category returns correct subset")
    func filterByCategory() {
        let hillTemplates = WorkoutTemplateLibrary.templates(for: .hillTraining)
        #expect(!hillTemplates.isEmpty)
        #expect(hillTemplates.allSatisfy { $0.category == .hillTraining })

        let speedTemplates = WorkoutTemplateLibrary.templates(for: .speedWork)
        #expect(!speedTemplates.isEmpty)
        #expect(speedTemplates.allSatisfy { $0.category == .speedWork })
    }

    @Test("Search matches by name case-insensitively")
    func searchByName() {
        let results = WorkoutTemplateLibrary.search(query: "fartlek")
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.name.lowercased().contains("fartlek") || $0.descriptionText.lowercased().contains("fartlek") })
    }

    @Test("Empty search returns all templates")
    func emptySearchReturnsAll() {
        let results = WorkoutTemplateLibrary.search(query: "")
        #expect(results.count == WorkoutTemplateLibrary.all.count)
    }

    @Test("All built-in templates are not user-created")
    func builtInNotUserCreated() {
        #expect(WorkoutTemplateLibrary.all.allSatisfy { !$0.isUserCreated })
    }

    @Test("Every category has at least one template")
    func everyCategoryHasTemplates() {
        for category in WorkoutCategory.allCases {
            let templates = WorkoutTemplateLibrary.templates(for: category)
            #expect(!templates.isEmpty, "Category \(category.rawValue) should have templates")
        }
    }
}
