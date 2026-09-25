import Foundation
import Testing
@testable import Abrar

struct AppVersionTests {
    @Test func parsesTagsAndCompares() throws {
        let v010 = try #require(AppVersion("v0.1.0"))
        let v02 = try #require(AppVersion("0.2"))
        let v0100 = try #require(AppVersion("0.10.0"))
        #expect(v010.description == "0.1.0")
        #expect(v010 < v02)
        #expect(v02 < v0100)
        #expect(AppVersion("1.0") == AppVersion("1.0.0"))
        #expect(AppVersion("beta") == nil)
        #expect(AppVersion("1.0-rc1") == nil)
    }

    @Test func parsesGitHubRelease() throws {
        let json = Data("""
            {"tag_name":"v0.2.0","html_url":"https://github.com/jakcal/abrar-mac/releases/tag/v0.2.0",
             "draft":false,"prerelease":false,
             "assets":[{"name":"Abrar-0.2.0.dmg.sha256","browser_download_url":"https://example.com/a.sha256"},
                       {"name":"Abrar-0.2.0.dmg","browser_download_url":"https://example.com/a.dmg"}]}
            """.utf8)
        let release = try #require(try GitHubReleaseChecker.parse(json))
        #expect(release.version == AppVersion("0.2.0"))
        #expect(release.downloadURL?.absoluteString == "https://example.com/a.dmg")
    }

    @Test func ignoresPrereleases() throws {
        let json = Data(#"{"tag_name":"v9.0.0","html_url":"https://x.com","prerelease":true,"assets":[]}"#.utf8)
        #expect(try GitHubReleaseChecker.parse(json) == nil)
    }
}

private struct FakeChecker: ReleaseChecking {
    let release: AppRelease?
    func latestRelease() async throws -> AppRelease? { release }
}

@MainActor
struct UpdateControllerTests {
    private func release(_ version: String) throws -> AppRelease {
        AppRelease(
            version: try #require(AppVersion(version)),
            pageURL: try #require(URL(string: "https://github.com/jakcal/abrar-mac/releases")),
            downloadURL: nil
        )
    }

    @Test func offersNewerRelease() async throws {
        let controller = UpdateController(checker: FakeChecker(release: try release("0.2.0")), currentVersion: AppVersion("0.1.0"))
        await controller.check()
        #expect(controller.available?.version == AppVersion("0.2.0"))
        #expect(controller.status == .upToDate)
    }

    @Test func ignoresSameOrOlderRelease() async throws {
        let controller = UpdateController(checker: FakeChecker(release: try release("0.1.0")), currentVersion: AppVersion("0.1.0"))
        await controller.check()
        #expect(controller.available == nil)
    }
}
