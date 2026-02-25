import Foundation
import os

// MARK: - Export Actions

extension RunAnalysisViewModel {

    func exportAsShareImage(unitPreference: UnitPreference) async {
        isExporting = true
        exportError = nil
        do {
            let badges = historicalComparison?.badges ?? []
            exportFileURL = try await exportService.exportRunAsShareImage(
                run,
                elevationProfile: elevationProfile,
                metrics: advancedMetrics,
                badges: badges,
                unitPreference: unitPreference
            )
            showingShareSheet = true
        } catch {
            exportError = "Failed to create share image."
            Logger.export.error("Share image export failed: \(error)")
        }
        isExporting = false
    }

    func exportAsGPX() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await exportService.exportRunAsGPX(run)
            showingShareSheet = true
        } catch {
            exportError = "Failed to export GPX."
            Logger.export.error("GPX export failed: \(error)")
        }
        isExporting = false
    }

    func exportAsTrackCSV() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await exportService.exportRunTrackAsCSV(run)
            showingShareSheet = true
        } catch {
            exportError = "Failed to export CSV."
            Logger.export.error("CSV export failed: \(error)")
        }
        isExporting = false
    }

    func exportAsPDF() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await exportService.exportRunAsPDF(
                run,
                metrics: advancedMetrics,
                comparison: historicalComparison,
                nutritionAnalysis: nutritionAnalysis
            )
            showingShareSheet = true
        } catch {
            exportError = "Failed to export PDF."
            Logger.export.error("PDF export failed: \(error)")
        }
        isExporting = false
    }
}
