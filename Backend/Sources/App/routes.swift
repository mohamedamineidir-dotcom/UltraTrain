import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("v1")

    api.get("health") { _ in
        ["status": "ok"]
    }

    try api.register(collection: AuthController())
    try api.register(collection: AthleteController())
    try api.register(collection: RunController())
    try api.register(collection: DeviceTokenController())
}
