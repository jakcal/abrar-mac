import SwiftUI

enum WindowID {
    static let quran = "quran"
}

@main
struct AbrarApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .appEnvironment(model)
        } label: {
            MenuBarLabel(schedule: model.schedule)
        }
        .menuBarExtraStyle(.window)

        Window("Quran", id: WindowID.quran) {
            QuranWindow()
                .appEnvironment(model)
        }
        .defaultSize(width: 1000, height: 720)

        Settings {
            SettingsView()
                .appEnvironment(model)
        }
    }
}

private extension View {
    func appEnvironment(_ model: AppModel) -> some View {
        environment(model)
            .environment(model.settings)
            .environment(model.schedule)
            .environment(model.reader)
            .environment(model.player)
            .environment(model.downloads)
            .environment(model.location)
    }
}
