import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            LocationSettingsView()
                .tabItem { Label("Location", systemImage: "location") }
            CalculationSettingsView()
                .tabItem { Label("Calculation", systemImage: "sun.horizon") }
            NotificationSettingsView()
                .tabItem { Label("Notifications", systemImage: "bell") }
            AudioSettingsView()
                .tabItem { Label("Audio", systemImage: "headphones") }
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 520, height: 460)
    }
}
