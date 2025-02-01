import SwiftUI
import BackgroundTasks

@main
struct Satellite_EyeApp: App {
    @StateObject var satelliteManager = SatelliteManager()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView(satelliteManager: satelliteManager)
        }
    }
}
