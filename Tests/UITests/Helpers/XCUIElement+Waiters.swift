import XCTest

extension XCUIElement {

    /// Waits for the element to exist, then taps it.
    /// - Parameter timeout: Maximum seconds to wait (default 5).
    @discardableResult
    func waitAndTap(timeout: TimeInterval = 5) -> Bool {
        guard waitForExistence(timeout: timeout) else { return false }
        tap()
        return true
    }

    /// Waits until the element is enabled (hittable).
    /// - Parameter timeout: Maximum seconds to wait (default 10).
    @discardableResult
    func waitUntilEnabled(timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
