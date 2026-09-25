import Foundation

struct Place: Codable, Hashable, Identifiable, Sendable {
    var name: String
    var country: String
    var latitude: Double
    var longitude: Double
    var timeZoneID: String

    var id: String { "\(name)|\(country)|\(latitude)|\(longitude)" }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }

    var displayName: String { country.isEmpty ? name : "\(name), \(country)" }
}
