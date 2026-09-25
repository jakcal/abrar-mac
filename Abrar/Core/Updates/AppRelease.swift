import Foundation

struct AppRelease: Equatable, Sendable {
    let version: AppVersion
    let pageURL: URL
    let downloadURL: URL?
}

/// Dotted numeric version ("1.2.3"); a leading "v" is ignored.
struct AppVersion: Comparable, CustomStringConvertible, Sendable {
    let components: [Int]

    init?(_ string: String) {
        let trimmed = string.hasPrefix("v") ? String(string.dropFirst()) : string
        let parts = trimmed.split(separator: ".").map { Int($0) }
        guard !parts.isEmpty, parts.allSatisfy({ $0 != nil }) else { return nil }
        components = parts.compactMap { $0 }
    }

    var description: String { components.map(String.init).joined(separator: ".") }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }

    static var current: AppVersion? {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String).flatMap(AppVersion.init)
    }
}

protocol ReleaseChecking: Sendable {
    func latestRelease() async throws -> AppRelease?
}

/// Reads the latest published release of jakcal/abrar-mac from the GitHub API.
struct GitHubReleaseChecker: ReleaseChecking {
    var session: URLSession = .shared

    func latestRelease() async throws -> AppRelease? {
        guard let url = URL(string: "https://api.github.com/repos/jakcal/abrar-mac/releases/latest") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        // 404 means nothing has been released yet.
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }
        return try Self.parse(data)
    }

    static func parse(_ data: Data) throws -> AppRelease? {
        struct Response: Decodable {
            struct Asset: Decodable {
                let name: String
                let browser_download_url: URL
            }
            let tag_name: String
            let html_url: URL
            let draft: Bool?
            let prerelease: Bool?
            let assets: [Asset]
        }
        let release = try JSONDecoder().decode(Response.self, from: data)
        guard release.draft != true, release.prerelease != true, let version = AppVersion(release.tag_name) else {
            return nil
        }
        let dmg = release.assets.first { $0.name.hasSuffix(".dmg") }
        return AppRelease(version: version, pageURL: release.html_url, downloadURL: dmg?.browser_download_url)
    }
}
