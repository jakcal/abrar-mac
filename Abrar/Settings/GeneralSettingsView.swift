import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var launchAtLogin = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.callout)
                }
            }
            Section("About") {
                Text("Abrar is made by Yassine Chandid · [yassinech.com](https://yassinech.com) · [@jakcal on GitHub](https://github.com/jakcal)")
                Text("If you find it useful, consider [supporting development on Ko-fi](https://ko-fi.com/jakcal).")
                Text("Open source under the MIT License.")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            Section("Credits") {
                Text("Quran text: [Tanzil Project](https://tanzil.net), Uthmani, CC BY 3.0, used verbatim.")
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
