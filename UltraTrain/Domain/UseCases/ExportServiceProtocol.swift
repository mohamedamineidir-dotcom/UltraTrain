import Foundation

protocol ExportServiceProtocol: Sendable {
    func exportRunAsGPX(_ run: CompletedRun) async throws -> URL
    func exportRunsAsCSV(_ runs: [CompletedRun]) async throws -> URL
    func exportRunTrackAsCSV(_ run: CompletedRun) async throws -> URL
    @MainActor func exportRunAsPDF(
        _ run: CompletedRun,
        metrics: AdvancedRunMetrics?,
        comparison: HistoricalComparison?,
        nutritionAnalysis: NutritionAnalysis?
    ) async throws -> URL
}
