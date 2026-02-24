import Testing
import Foundation
@testable import UltraTrain

struct RequestDeduplicationTests {

    // MARK: - InFlightRequestKey

    @Test func sameGetRequestsProduceSameKey() {
        let key1 = InFlightRequestKey(
            method: "GET",
            path: "/runs",
            queryItems: [URLQueryItem(name: "limit", value: "10")],
            bodyData: nil
        )
        let key2 = InFlightRequestKey(
            method: "GET",
            path: "/runs",
            queryItems: [URLQueryItem(name: "limit", value: "10")],
            bodyData: nil
        )
        #expect(key1 == key2)
        #expect(key1.hashValue == key2.hashValue)
    }

    @Test func differentPathsProduceDifferentKeys() {
        let key1 = InFlightRequestKey(method: "GET", path: "/runs", queryItems: nil, bodyData: nil)
        let key2 = InFlightRequestKey(method: "GET", path: "/races", queryItems: nil, bodyData: nil)
        #expect(key1 != key2)
    }

    @Test func differentQueryItemsProduceDifferentKeys() {
        let key1 = InFlightRequestKey(
            method: "GET",
            path: "/runs",
            queryItems: [URLQueryItem(name: "limit", value: "10")],
            bodyData: nil
        )
        let key2 = InFlightRequestKey(
            method: "GET",
            path: "/runs",
            queryItems: [URLQueryItem(name: "limit", value: "20")],
            bodyData: nil
        )
        #expect(key1 != key2)
    }

    @Test func differentMethodsProduceDifferentKeys() {
        let key1 = InFlightRequestKey(method: "GET", path: "/runs", queryItems: nil, bodyData: nil)
        let key2 = InFlightRequestKey(method: "POST", path: "/runs", queryItems: nil, bodyData: nil)
        #expect(key1 != key2)
    }

    @Test func nilQueryItemsMatchOtherNilQueryItems() {
        let key1 = InFlightRequestKey(method: "GET", path: "/runs", queryItems: nil, bodyData: nil)
        let key2 = InFlightRequestKey(method: "GET", path: "/runs", queryItems: nil, bodyData: nil)
        #expect(key1 == key2)
    }

    @Test func differentBodyDataProducesDifferentKeys() {
        let key1 = InFlightRequestKey(
            method: "POST",
            path: "/runs",
            queryItems: nil,
            bodyData: Data("body1".utf8)
        )
        let key2 = InFlightRequestKey(
            method: "POST",
            path: "/runs",
            queryItems: nil,
            bodyData: Data("body2".utf8)
        )
        #expect(key1 != key2)
    }

    @Test func queryItemOrderDoesNotMatter() {
        let key1 = InFlightRequestKey(
            method: "GET",
            path: "/runs",
            queryItems: [
                URLQueryItem(name: "a", value: "1"),
                URLQueryItem(name: "b", value: "2")
            ],
            bodyData: nil
        )
        let key2 = InFlightRequestKey(
            method: "GET",
            path: "/runs",
            queryItems: [
                URLQueryItem(name: "b", value: "2"),
                URLQueryItem(name: "a", value: "1")
            ],
            bodyData: nil
        )
        #expect(key1 == key2)
    }
}
