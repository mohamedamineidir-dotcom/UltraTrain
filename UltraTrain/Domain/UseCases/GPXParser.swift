import Foundation
import os

final class GPXParser: NSObject, Sendable {
    private static let logger = Logger.importData

    func parse(_ data: Data) throws -> GPXParseResult {
        let delegate = GPXParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false

        guard parser.parse() else {
            let errorDesc = parser.parserError?.localizedDescription ?? "Unknown XML parsing error"
            GPXParser.logger.error("GPX parsing failed: \(errorDesc)")
            throw DomainError.gpxParsingFailed(reason: errorDesc)
        }

        let result = delegate.result

        if result.trackPoints.isEmpty {
            GPXParser.logger.warning("GPX file parsed but contains no track points")
        } else {
            GPXParser.logger.info("GPX parsed: \(result.trackPoints.count) track points")
        }

        return result
    }
}

// MARK: - XMLParserDelegate

private final class GPXParserDelegate: NSObject, XMLParserDelegate {
    var result = GPXParseResult(name: nil, date: nil, trackPoints: [])

    private var currentElement = ""
    private var currentText = ""

    // Current track point being built
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentTime: Date?
    private var currentHR: Int?

    // Parsing state
    private var inTrackPoint = false
    private var inExtensions = false
    private var inTrackPointExtension = false
    private var inName = false
    private var inTime = false

    private let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let iso8601FallbackFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "trkpt":
            inTrackPoint = true
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentLat = lat
                currentLon = lon
            }
            currentEle = nil
            currentTime = nil
            currentHR = nil

        case "extensions":
            inExtensions = true

        case "gpxtpx:TrackPointExtension":
            inTrackPointExtension = true

        case "name":
            if !inTrackPoint {
                inName = true
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "trkpt":
            if let lat = currentLat, let lon = currentLon {
                // Validate coordinate ranges
                guard (-90...90).contains(lat),
                      (-180...180).contains(lon) else {
                    inTrackPoint = false
                    return
                }

                // Validate altitude if present
                if let ele = currentEle, !(-500...9000).contains(ele) {
                    currentEle = nil
                }

                let point = TrackPoint(
                    latitude: lat,
                    longitude: lon,
                    altitudeM: currentEle ?? 0,
                    timestamp: currentTime ?? Date(),
                    heartRate: currentHR
                )
                result.trackPoints.append(point)
            }
            inTrackPoint = false

        case "ele":
            if inTrackPoint {
                currentEle = Double(trimmed)
            }

        case "time":
            if inTrackPoint {
                currentTime = parseDate(trimmed)
            } else if result.date == nil {
                result.date = parseDate(trimmed)
            }

        case "gpxtpx:hr":
            if inTrackPointExtension {
                currentHR = Int(trimmed)
            }

        case "gpxtpx:TrackPointExtension":
            inTrackPointExtension = false

        case "extensions":
            inExtensions = false

        case "name":
            if inName {
                result.name = trimmed.isEmpty ? nil : trimmed
                inName = false
            }

        default:
            break
        }
    }

    // MARK: - Helpers

    private func parseDate(_ string: String) -> Date? {
        iso8601Formatter.date(from: string)
            ?? iso8601FallbackFormatter.date(from: string)
    }
}
