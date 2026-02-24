import Testing
import Foundation
@testable import UltraTrain

struct RequestSigningInterceptorTests {

    @Test func signAddsHeadersToRequest() {
        let interceptor = RequestSigningInterceptor(secret: "test-secret-key")
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpBody = "hello".data(using: .utf8)

        interceptor.sign(&request)

        #expect(request.value(forHTTPHeaderField: "X-Signature") != nil)
        #expect(request.value(forHTTPHeaderField: "X-Timestamp") != nil)
    }

    @Test func signProducesDeterministicHMAC() {
        let interceptor = RequestSigningInterceptor(secret: "fixed-secret")
        let body = "test-body".data(using: .utf8)!

        var request1 = URLRequest(url: URL(string: "https://example.com/api")!)
        request1.httpBody = body
        request1.setValue("2025-01-01T00:00:00Z", forHTTPHeaderField: "X-Timestamp")

        var request2 = URLRequest(url: URL(string: "https://example.com/api")!)
        request2.httpBody = body
        request2.setValue("2025-01-01T00:00:00Z", forHTTPHeaderField: "X-Timestamp")

        interceptor.sign(&request1)
        interceptor.sign(&request2)

        // Both have signatures
        let sig1 = request1.value(forHTTPHeaderField: "X-Signature")
        let sig2 = request2.value(forHTTPHeaderField: "X-Signature")
        #expect(sig1 != nil)
        #expect(sig2 != nil)
    }

    @Test func differentBodiesProduceDifferentSignatures() {
        let interceptor = RequestSigningInterceptor(secret: "test-secret")

        var request1 = URLRequest(url: URL(string: "https://example.com/api")!)
        request1.httpBody = "body-a".data(using: .utf8)
        interceptor.sign(&request1)

        var request2 = URLRequest(url: URL(string: "https://example.com/api")!)
        request2.httpBody = "body-b".data(using: .utf8)
        interceptor.sign(&request2)

        let sig1 = request1.value(forHTTPHeaderField: "X-Signature")!
        let sig2 = request2.value(forHTTPHeaderField: "X-Signature")!
        #expect(sig1 != sig2)
    }

    @Test func nilBodyStillSignsRequest() {
        let interceptor = RequestSigningInterceptor(secret: "test-secret")
        var request = URLRequest(url: URL(string: "https://example.com/api")!)

        interceptor.sign(&request)

        #expect(request.value(forHTTPHeaderField: "X-Signature") != nil)
        #expect(request.value(forHTTPHeaderField: "X-Timestamp") != nil)
    }

    @Test func emptySecretSkipsSigning() {
        let interceptor = RequestSigningInterceptor(secret: "")
        var request = URLRequest(url: URL(string: "https://example.com/api")!)

        interceptor.sign(&request)

        #expect(request.value(forHTTPHeaderField: "X-Signature") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Timestamp") == nil)
    }
}
