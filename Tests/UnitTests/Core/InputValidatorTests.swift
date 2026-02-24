import Testing
@testable import UltraTrain

struct InputValidatorTests {

    // MARK: - GPS

    @Test func validLatitude() {
        #expect(InputValidator.isValidLatitude(0))
        #expect(InputValidator.isValidLatitude(90))
        #expect(InputValidator.isValidLatitude(-90))
        #expect(InputValidator.isValidLatitude(45.678))
    }

    @Test func invalidLatitude() {
        #expect(!InputValidator.isValidLatitude(91))
        #expect(!InputValidator.isValidLatitude(-91))
        #expect(!InputValidator.isValidLatitude(Double.nan))
        #expect(!InputValidator.isValidLatitude(Double.infinity))
    }

    @Test func validLongitude() {
        #expect(InputValidator.isValidLongitude(0))
        #expect(InputValidator.isValidLongitude(180))
        #expect(InputValidator.isValidLongitude(-180))
    }

    @Test func invalidLongitude() {
        #expect(!InputValidator.isValidLongitude(181))
        #expect(!InputValidator.isValidLongitude(-181))
        #expect(!InputValidator.isValidLongitude(Double.nan))
    }

    @Test func validAltitude() {
        #expect(InputValidator.isValidAltitude(0))
        #expect(InputValidator.isValidAltitude(8849)) // Everest
        #expect(InputValidator.isValidAltitude(-430)) // Dead Sea
    }

    @Test func invalidAltitude() {
        #expect(!InputValidator.isValidAltitude(-501))
        #expect(!InputValidator.isValidAltitude(9001))
        #expect(!InputValidator.isValidAltitude(Double.nan))
    }

    @Test func validCoordinate() {
        #expect(InputValidator.isValidCoordinate(latitude: 45.5, longitude: 6.9))
    }

    @Test func invalidCoordinate() {
        #expect(!InputValidator.isValidCoordinate(latitude: 91, longitude: 0))
        #expect(!InputValidator.isValidCoordinate(latitude: 0, longitude: 181))
    }

    // MARK: - Heart Rate

    @Test func validHeartRate() {
        #expect(InputValidator.isValidHeartRate(60))
        #expect(InputValidator.isValidHeartRate(20))
        #expect(InputValidator.isValidHeartRate(250))
    }

    @Test func invalidHeartRate() {
        #expect(!InputValidator.isValidHeartRate(19))
        #expect(!InputValidator.isValidHeartRate(251))
        #expect(!InputValidator.isValidHeartRate(0))
        #expect(!InputValidator.isValidHeartRate(-1))
    }

    @Test func optionalHeartRateNilIsValid() {
        #expect(InputValidator.isValidOptionalHeartRate(nil))
    }

    @Test func optionalHeartRateInvalid() {
        #expect(!InputValidator.isValidOptionalHeartRate(999))
    }

    // MARK: - Pace

    @Test func validPace() {
        #expect(InputValidator.isValidPace(300)) // 5:00/km
        #expect(InputValidator.isValidPace(60))  // 1:00/km
        #expect(InputValidator.isValidPace(3600)) // 60:00/km
    }

    @Test func invalidPace() {
        #expect(!InputValidator.isValidPace(59))
        #expect(!InputValidator.isValidPace(3601))
        #expect(!InputValidator.isValidPace(Double.nan))
        #expect(!InputValidator.isValidPace(Double.infinity))
    }

    @Test func optionalPaceNilIsValid() {
        #expect(InputValidator.isValidOptionalPace(nil))
    }

    // MARK: - Distance

    @Test func validDistance() {
        #expect(InputValidator.isValidDistance(0))
        #expect(InputValidator.isValidDistance(42.195))
        #expect(InputValidator.isValidDistance(330)) // Tor des Géants
        #expect(InputValidator.isValidDistance(1000))
    }

    @Test func invalidDistance() {
        #expect(!InputValidator.isValidDistance(-1))
        #expect(!InputValidator.isValidDistance(1001))
        #expect(!InputValidator.isValidDistance(Double.nan))
    }

    // MARK: - Elevation

    @Test func validElevation() {
        #expect(InputValidator.isValidElevation(0))
        #expect(InputValidator.isValidElevation(24000)) // UTMB D+
        #expect(InputValidator.isValidElevation(50000))
    }

    @Test func invalidElevation() {
        #expect(!InputValidator.isValidElevation(-1))
        #expect(!InputValidator.isValidElevation(50001))
        #expect(!InputValidator.isValidElevation(Double.nan))
    }

    // MARK: - Duration

    @Test func validDuration() {
        #expect(InputValidator.isValidDuration(0))
        #expect(InputValidator.isValidDuration(3600)) // 1h
        #expect(InputValidator.isValidDuration(604800)) // 1 week
    }

    @Test func invalidDuration() {
        #expect(!InputValidator.isValidDuration(-1))
        #expect(!InputValidator.isValidDuration(604801))
        #expect(!InputValidator.isValidDuration(Double.nan))
    }

    // MARK: - Body Metrics

    @Test func validWeight() {
        #expect(InputValidator.isValidWeight(70))
        #expect(InputValidator.isValidWeight(20))
        #expect(InputValidator.isValidWeight(300))
    }

    @Test func invalidWeight() {
        #expect(!InputValidator.isValidWeight(19))
        #expect(!InputValidator.isValidWeight(301))
        #expect(!InputValidator.isValidWeight(Double.nan))
    }

    @Test func validHeight() {
        #expect(InputValidator.isValidHeight(170))
        #expect(InputValidator.isValidHeight(50))
        #expect(InputValidator.isValidHeight(300))
    }

    @Test func invalidHeight() {
        #expect(!InputValidator.isValidHeight(49))
        #expect(!InputValidator.isValidHeight(301))
    }

    // MARK: - Text Sanitization

    @Test func sanitizeTrimsWhitespace() {
        #expect(InputValidator.sanitizeText("  hello  ") == "hello")
    }

    @Test func sanitizeStripsControlCharacters() {
        #expect(InputValidator.sanitizeText("hello\u{0000}world") == "helloworld")
    }

    @Test func sanitizePreservesNewlinesAndTabs() {
        #expect(InputValidator.sanitizeText("hello\nworld\there") == "hello\nworld\there")
    }

    @Test func sanitizeTruncatesLongText() {
        let long = String(repeating: "a", count: 600)
        #expect(InputValidator.sanitizeText(long, maxLength: 500).count == 500)
    }

    @Test func sanitizeEmptyString() {
        #expect(InputValidator.sanitizeText("") == "")
    }

    @Test func sanitizeOptionalNilReturnsNil() {
        #expect(InputValidator.sanitizeOptionalText(nil) == nil)
    }

    @Test func sanitizeOptionalEmptyReturnsNil() {
        #expect(InputValidator.sanitizeOptionalText("   ") == nil)
    }

    @Test func sanitizeNameTruncatesAt100() {
        let long = String(repeating: "x", count: 150)
        #expect(InputValidator.sanitizeName(long).count == 100)
    }

    // MARK: - Positive

    @Test func isPositive() {
        #expect(InputValidator.isPositive(1))
        #expect(InputValidator.isPositive(0.001))
        #expect(!InputValidator.isPositive(0))
        #expect(!InputValidator.isPositive(-1))
        #expect(!InputValidator.isPositive(Double.nan))
        #expect(!InputValidator.isPositive(Double.infinity))
    }
}
