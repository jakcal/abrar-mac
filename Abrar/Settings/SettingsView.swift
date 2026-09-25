import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            LocationSettingsView()
                .frame(width: 540, height: 500)
                .tabItem { Label("Location", systemImage: "location") }
            CalculationSettingsView()
                .frame(width: 540, height: 560)
                .tabItem { Label("Calculation", systemImage: "sun.horizon") }
            NotificationSettingsView()
                .frame(width: 540, height: 440)
                .tabItem { Label("Notifications", systemImage: "bell") }
            AudioSettingsView()
                .frame(width: 540, height: 520)
                .tabItem { Label("Audio", systemImage: "headphones") }
            GeneralSettingsView()
                .frame(width: 540, height: 520)
                .tabItem { Label("General", systemImage: "gearshape") }
        }
    }
}
