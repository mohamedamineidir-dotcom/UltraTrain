import Testing
import Foundation
@testable import UltraTrain

@Suite("RunImportUseCase")
struct RunImportUseCaseTests {
    private let mockRunRepo = MockRunRepository()
    private let athleteId = UUID()

    private func makeUseCase() -> DefaultRunImportUseCase {
        DefaultRunImportUseCase(
            gpxParser: GPXParser(),
            runRepository: mockRunRepo
        )
    }

    private func validGPX(
        pointCount: Int = 5,
        distanceStep: Double = 0.001
    ) -> Data {
        var segments = ""
        let baseLat = 45.0
        let baseLon = 6.0
        for i in 0..<pointCount {
            let lat = baseLat + Double(i) * distanceStep
            let lon = baseLon + Double(i) * distanceStep
            let ele = 1000.0 + Double(i) * 5
            let time = "2024-02-18T08:00:\(String(format: "%02d", i * 10))Z"
            segments += """
              <trkpt lat="\(lat)" lon="\(lon)">
                <ele>\(ele)</ele>
                <time>\(time)</time>
                <extensions>
                  <gpxtpx:TrackPointExtension>
                    <gpxtpx:hr>\(140 + i)</gpxtpx:hr>
                  </gpxtpx:TrackPointExtension>
                </extensions>
              </trkpt>

            """
        }

        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <metadata><name>Test Run</name></metadata>
          <trk>
            <trkseg>
            \(segments)
            </trkseg>
          </trk>
        </gpx>
        """
        return Data(gpx.utf8)
    }

    @Test("Import creates valid CompletedRun")
    func importCreatesRun() async throws {
        let useCase = makeUseCase()
        let run = try await useCase.importFromGPX(
            data: validGPX(),
            athleteId: athleteId
        )

        #expect(run.athleteId == athleteId)
        #expect(run.distanceKm > 0)
        #expect(run.duration > 0)
        #expect(run.averagePaceSecondsPerKm > 0)
        #expect(run.gpsTrack.count == 5)
        #expect(run.notes?.contains("Imported") == true)
    }

    @Test("Import calculates elevation correctly")
    func importCalculatesElevation() async throws {
        let useCase = makeUseCase()
        let run = try await useCase.importFromGPX(
            data: validGPX(),
            athleteId: athleteId
        )

        #expect(run.elevationGainM > 0)
    }

    @Test("Import calculates heart rate stats")
    func importCalculatesHeartRate() async throws {
        let useCase = makeUseCase()
        let run = try await useCase.importFromGPX(
            data: validGPX(),
            athleteId: athleteId
        )

        #expect(run.averageHeartRate != nil)
        #expect(run.maxHeartRate != nil)
        #expect(run.maxHeartRate! >= run.averageHeartRate!)
    }

    @Test("Import saves run to repository")
    func importSavesToRepository() async throws {
        let useCase = makeUseCase()
        let run = try await useCase.importFromGPX(
            data: validGPX(),
            athleteId: athleteId
        )

        let saved = try await mockRunRepo.getRun(id: run.id)
        #expect(saved != nil)
        #expect(saved?.id == run.id)
    }

    @Test("Import with too few points throws error")
    func importTooFewPoints() async {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
              <trkpt lat="45.0" lon="6.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:00Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let useCase = makeUseCase()
        do {
            _ = try await useCase.importFromGPX(
                data: Data(gpx.utf8),
                athleteId: athleteId
            )
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is DomainError)
        }
    }

    @Test("Import with zero duration throws error")
    func importZeroDuration() async {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
              <trkpt lat="45.0" lon="6.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:00Z</time>
              </trkpt>
              <trkpt lat="45.1" lon="6.1">
                <ele>1010</ele>
                <time>2024-02-18T08:00:00Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let useCase = makeUseCase()
        do {
            _ = try await useCase.importFromGPX(
                data: Data(gpx.utf8),
                athleteId: athleteId
            )
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is DomainError)
        }
    }
}
