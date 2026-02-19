import Foundation
import SwiftData

@Model
final class GearItemSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String = ""
    var typeRaw: String = "trailShoes"
    var purchaseDate: Date = Date()
    var maxDistanceKm: Double = 800
    var totalDistanceKm: Double = 0
    var totalDuration: Double = 0
    var isRetired: Bool = false
    var notes: String?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        brand: String = "",
        typeRaw: String = "trailShoes",
        purchaseDate: Date = Date(),
        maxDistanceKm: Double = 800,
        totalDistanceKm: Double = 0,
        totalDuration: Double = 0,
        isRetired: Bool = false,
        notes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.typeRaw = typeRaw
        self.purchaseDate = purchaseDate
        self.maxDistanceKm = maxDistanceKm
        self.totalDistanceKm = totalDistanceKm
        self.totalDuration = totalDuration
        self.isRetired = isRetired
        self.notes = notes
        self.updatedAt = updatedAt
    }
}
