import SwiftUI

@main
struct SignalFieldApp: App {
    @StateObject private var monitor = SignalMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .tint(Color(red: 0.09, green: 0.36, blue: 0.33))
        }
    }
}
