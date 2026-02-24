protocol DeviceIntegrityCheckerProtocol: Sendable {
    func isDeviceCompromised() -> Bool
}
