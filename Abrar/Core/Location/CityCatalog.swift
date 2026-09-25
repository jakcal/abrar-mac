import Foundation

protocol CitySearching: Sendable {
    func search(_ query: String) -> [Place]
}

struct CityCatalog: CitySearching {
    let cities: [Place]

    init(cities: [Place]) {
        self.cities = cities
    }

    static func bundled(in bundle: Bundle = .main) -> CityCatalog {
        guard let url = bundle.url(forResource: "cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cities = try? JSONDecoder().decode([Place].self, from: data)
        else { return CityCatalog(cities: []) }
        return CityCatalog(cities: cities)
    }

    func search(_ query: String) -> [Place] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return cities }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return cities.filter {
            $0.name.range(of: needle, options: options) != nil
                || $0.country.range(of: needle, options: options) != nil
        }
    }
}
