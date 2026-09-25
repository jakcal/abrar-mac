import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var launchAtLogin = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                AboutHeader()
            }
            Section {
                Toggle("Open Abrar at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
            }
            UpdateSettingsSection()
            Section("About") {
                Text("Made by Yassine Chandid · [yassinech.com](https://yassinech.com) · [@jakcal on GitHub](https://github.com/jakcal)")
                Text("If you find it useful, consider [supporting development on Ko-fi](https://ko-fi.com/jakcal).")
            }
            .font(.callout)
            Section("Credits") {
                Text("Quran text: [Tanzil Project](https://tanzil.net), Uthmani, CC BY 3.0, used verbatim.")
                Text("Inspired by [Guidance](https://guidanceapp.com) by Batoul Apps.")
                Text("Prayer times: [Adhan Swift](https://github.com/batoulapps/adhan-swift) (MIT).")
                Text("Recitations: [QuranicAudio](https://quranicaudio.com), served by [quran.com](https://quran.com).")
                Text("Ayah timings: [quran.com](https://quran.com) audio API. Not affiliated with or endorsed by quran.com.")
                Text("Font: [Amiri Quran](https://github.com/aliftype/amiri) (SIL OFL 1.1).")
                Text("Adhan recording by Atcovi, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3) (CC BY-SA 4.0).")
            }
            .font(.callout)
        }
        .formStyle(.grouped)
        .onAppear { launchAtLogin = app.services.launchAtLogin.isEnabled }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard enabled != app.services.launchAtLogin.isEnabled else { return }
        do {
            try app.services.launchAtLogin.setEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            launchAtLogin = app.services.launchAtLogin.isEnabled
        }
    }
}

private struct AboutHeader: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Abrar").font(.title2.weight(.semibold))
                Text("Prayer times and the Quran in your menu bar")
                    .foregroundStyle(.secondary)
                Text("Version \(version) · Open source under the MIT License")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
