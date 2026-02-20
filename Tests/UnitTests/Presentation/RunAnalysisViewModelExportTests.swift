import Foundation
import Testing
@testable import UltraTrain

@Suite("RunAnalysisViewModel Export Tests")
struct RunAnalysisViewModelExportTests {

    private func makeRun() -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now,
            distanceKm: 25,
            elevationGainM: 800,
            elevationLossM: 750,
            duration: 9000,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [
                TrackPoint(latitude: 45.0, longitude: 6.0, altitudeM: 1000, timestamp: Date.now, heartRate: 140),
                TrackPoint(latitude: 45.01, longitude: 6.01, altitudeM: 1100, timestamp: Date.now.addingTimeInterval(600), heartRate: 155)
            ],
            splits: [
                Split(id: UUID(), kilometerNumber: 1, duration: 360, elevationChangeM: 50, averageHeartRate: 145)
            ],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    @MainActor
    private func makeViewModel(
        exportService: MockExportService = MockExportService()
    ) -> (RunAnalysisViewModel, MockExportService) {
        let vm = RunAnalysisViewModel(
            run: makeRun(),
            planRepository: MockTrainingPlanRepository(),
            athleteRepository: MockAthleteRepository(),
            raceRepository: MockRaceRepository(),
            runRepository: MockRunRepository(),
            finishEstimateRepository: MockFinishEstimateRepository(),
            exportService: exportService
        )
        return (vm, exportService)
    }

    @Test("Export as share image calls export service")
    @MainActor
    func exportShareImageCallsService() async {
        let (vm, service) = makeViewModel()

        await vm.exportAsShareImage(unitPreference: .metric)

        #expect(service.exportRunAsShareImageCalled)
    }

    @Test("Export as share image sets share sheet visible")
    @MainActor
    func exportShareImageShowsSheet() async {
        let (vm, _) = makeViewModel()

        await vm.exportAsShareImage(unitPreference: .metric)

        #expect(vm.showingShareSheet)
        #expect(vm.exportFileURL != nil)
    }

    @Test("Export as share image sets error on failure")
    @MainActor
    func exportShareImageError() async {
        let service = MockExportService()
        service.shouldThrow = true
        let (vm, _) = makeViewModel(exportService: service)

        await vm.exportAsShareImage(unitPreference: .metric)

        #expect(vm.exportError != nil)
        #expect(!vm.showingShareSheet)
    }

    @Test("Export as GPX calls export service")
    @MainActor
    func exportGPXCallsService() async {
        let (vm, service) = makeViewModel()

        await vm.exportAsGPX()

        #expect(service.exportRunAsGPXCalled)
        #expect(vm.showingShareSheet)
    }

    @Test("Export as track CSV calls export service")
    @MainActor
    func exportTrackCSVCallsService() async {
        let (vm, service) = makeViewModel()

        await vm.exportAsTrackCSV()

        #expect(service.exportRunTrackAsCSVCalled)
        #expect(vm.showingShareSheet)
    }

    @Test("Export as PDF calls export service")
    @MainActor
    func exportPDFCallsService() async {
        let (vm, service) = makeViewModel()

        await vm.exportAsPDF()

        #expect(service.exportRunAsPDFCalled)
        #expect(vm.showingShareSheet)
    }

    @Test("isExporting is false after export completes")
    @MainActor
    func isExportingFalseAfterComplete() async {
        let (vm, _) = makeViewModel()

        await vm.exportAsGPX()

        #expect(!vm.isExporting)
    }
}
