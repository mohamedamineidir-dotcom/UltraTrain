import Testing
import Foundation
@testable import UltraTrain

struct IdempotencyInterceptorTests {

    @Test func postRequestGetsIdempotencyHeader() {
        let interceptor = IdempotencyInterceptor()
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"

        interceptor.addKey(&request)

        let key = request.value(forHTTPHeaderField: "X-Idempotency-Key")
        #expect(key != nil)
        #expect(UUID(uuidString: key!) != nil)
    }

    @Test func putRequestGetsIdempotencyHeader() {
        let interceptor = IdempotencyInterceptor()
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "PUT"

        interceptor.addKey(&request)

        #expect(request.value(forHTTPHeaderField: "X-Idempotency-Key") != nil)
    }

    @Test func patchRequestGetsIdempotencyHeader() {
        let interceptor = IdempotencyInterceptor()
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "PATCH"

        interceptor.addKey(&request)

        #expect(request.value(forHTTPHeaderField: "X-Idempotency-Key") != nil)
    }

    @Test func getRequestDoesNotGetIdempotencyHeader() {
        let interceptor = IdempotencyInterceptor()
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "GET"

        interceptor.addKey(&request)

        #expect(request.value(forHTTPHeaderField: "X-Idempotency-Key") == nil)
    }

    @Test func deleteRequestDoesNotGetIdempotencyHeader() {
        let interceptor = IdempotencyInterceptor()
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "DELETE"

        interceptor.addKey(&request)

        #expect(request.value(forHTTPHeaderField: "X-Idempotency-Key") == nil)
    }

    @Test func eachCallGeneratesUniqueKey() {
        let interceptor = IdempotencyInterceptor()

        var request1 = URLRequest(url: URL(string: "https://example.com/api")!)
        request1.httpMethod = "POST"
        interceptor.addKey(&request1)

        var request2 = URLRequest(url: URL(string: "https://example.com/api")!)
        request2.httpMethod = "POST"
        interceptor.addKey(&request2)

        let key1 = request1.value(forHTTPHeaderField: "X-Idempotency-Key")!
        let key2 = request2.value(forHTTPHeaderField: "X-Idempotency-Key")!
        #expect(key1 != key2)
    }

    @Test func nilHttpMethodSkipsHeader() {
        let interceptor = IdempotencyInterceptor()
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = nil

        interceptor.addKey(&request)

        #expect(request.value(forHTTPHeaderField: "X-Idempotency-Key") == nil)
    }
}
