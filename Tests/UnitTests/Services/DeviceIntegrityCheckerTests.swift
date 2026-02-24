import Testing
import Foundation
@testable import UltraTrain

struct DeviceIntegrityCheckerTests {

    @Test func realCheckerReturnsFalseOnSimulator() {
        let checker = DeviceIntegrityChecker()
        let result = checker.isDeviceCompromised()
        // Simulator should always return false (targetEnvironment(simulator) guard)
        #expect(result == false)
    }

    @Test func conformsToProtocol() {
        let checker: any DeviceIntegrityCheckerProtocol = DeviceIntegrityChecker()
        _ = checker.isDeviceCompromised()
    }

    @Test func mockCompromisedDevice() {
        let mock = MockDeviceIntegrityChecker(compromised: true)
        #expect(mock.isDeviceCompromised() == true)
    }

    @Test func mockSafeDevice() {
        let mock = MockDeviceIntegrityChecker(compromised: false)
        #expect(mock.isDeviceCompromised() == false)
    }
}

private struct MockDeviceIntegrityChecker: DeviceIntegrityCheckerProtocol {
    let compromised: Bool

    func isDeviceCompromised() -> Bool {
        compromised
    }
}
