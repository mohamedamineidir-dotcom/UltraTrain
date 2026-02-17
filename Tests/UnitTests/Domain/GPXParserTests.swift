import Testing
import Foundation
@testable import UltraTrain

@Suite("GPXParser")
struct GPXParserTests {
    private let parser = GPXParser()

    @Test("Parse valid GPX with track points")
    func parseValidGPX() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="TestApp">
          <metadata>
            <name>Morning Run</name>
            <time>2024-02-18T08:00:00Z</time>
          </metadata>
          <trk>
            <trkseg>
              <trkpt lat="45.123456" lon="6.789012">
                <ele>1200.5</ele>
                <time>2024-02-18T08:00:00Z</time>
              </trkpt>
              <trkpt lat="45.123500" lon="6.789100">
                <ele>1210.3</ele>
                <time>2024-02-18T08:00:10Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = Data(gpx.utf8)
        let result = try parser.parse(data)

        #expect(result.name == "Morning Run")
        #expect(result.trackPoints.count == 2)
        #expect(result.trackPoints[0].latitude == 45.123456)
        #expect(result.trackPoints[0].longitude == 6.789012)
        #expect(result.trackPoints[0].altitudeM == 1200.5)
        #expect(result.trackPoints[1].latitude == 45.123500)
        #expect(result.trackPoints[1].altitudeM == 1210.3)
    }

    @Test("Parse GPX with heart rate extension")
    func parseWithHeartRate() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
              <trkpt lat="45.0" lon="6.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:00Z</time>
                <extensions>
                  <gpxtpx:TrackPointExtension>
                    <gpxtpx:hr>155</gpxtpx:hr>
                  </gpxtpx:TrackPointExtension>
                </extensions>
              </trkpt>
              <trkpt lat="45.1" lon="6.1">
                <ele>1010</ele>
                <time>2024-02-18T08:00:10Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = Data(gpx.utf8)
        let result = try parser.parse(data)

        #expect(result.trackPoints.count == 2)
        #expect(result.trackPoints[0].heartRate == 155)
        #expect(result.trackPoints[1].heartRate == nil)
    }

    @Test("Parse GPX with empty track segment")
    func parseEmptyTrack() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = Data(gpx.utf8)
        let result = try parser.parse(data)

        #expect(result.trackPoints.isEmpty)
    }

    @Test("Parse invalid XML throws error")
    func parseInvalidXML() {
        let invalid = Data("not xml at all <><>".utf8)
        #expect(throws: DomainError.self) {
            try parser.parse(invalid)
        }
    }

    @Test("Out-of-range coordinates are rejected")
    func outOfRangeCoordinates() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
              <trkpt lat="95.0" lon="6.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:00Z</time>
              </trkpt>
              <trkpt lat="45.0" lon="200.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:10Z</time>
              </trkpt>
              <trkpt lat="45.0" lon="6.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:20Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = Data(gpx.utf8)
        let result = try parser.parse(data)

        // Only the valid point should be included
        #expect(result.trackPoints.count == 1)
        #expect(result.trackPoints[0].latitude == 45.0)
    }

    @Test("Out-of-range altitude is set to zero")
    func outOfRangeAltitude() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
              <trkpt lat="45.0" lon="6.0">
                <ele>15000</ele>
                <time>2024-02-18T08:00:00Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = Data(gpx.utf8)
        let result = try parser.parse(data)

        #expect(result.trackPoints.count == 1)
        #expect(result.trackPoints[0].altitudeM == 0)
    }

    @Test("Parse GPX with fractional seconds in timestamps")
    func parseFractionalSeconds() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1">
          <trk>
            <trkseg>
              <trkpt lat="45.0" lon="6.0">
                <ele>1000</ele>
                <time>2024-02-18T08:00:00.500Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        let data = Data(gpx.utf8)
        let result = try parser.parse(data)

        #expect(result.trackPoints.count == 1)
        #expect(result.trackPoints[0].timestamp != Date())
    }
}
