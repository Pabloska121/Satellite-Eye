import SwiftUI

struct ContentView: View {
    @StateObject var satelliteManager = SatelliteManager()
    @StateObject var satelliteInfo = SatelliteInfo()
    @StateObject var settingsModel = SettingsModel()
    @StateObject private var locationManager = Location()
    @StateObject private var notify = NotificationHandler()
    
    @State private var selectedView = 1
    
    var body: some View {
            if !satelliteManager.isLoading {
                // Mostrar la vista principal con TabView una vez que los datos están listos
                TabView(selection: $selectedView) {
                    MapView(satelliteManager: satelliteManager, satelliteInfo: satelliteInfo, locationManager: locationManager, selectedView: $selectedView, settingsModel: settingsModel, notify: notify)
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }
                        .tag(1)

                    SearchView(satelliteManager: satelliteManager, selectedView: $selectedView)
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(2)
                    
                    PredictionView(satelliteManager: satelliteManager, satelliteInfo: satelliteInfo, locationManager: locationManager, selectedView: $selectedView, settingsModel: settingsModel, notify: notify)
                        .tabItem {
                            Label("Predict", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .tag(3)
                    
                    POVView(satelliteManager: satelliteManager, satelliteInfo: satelliteInfo, locationManager: locationManager, selectedView: $selectedView)
                        .tabItem {
                            Label("POV", systemImage: "iphone.radiowaves.left.and.right")
                        }
                        .tag(4)
                    
                    SettingsView(viewModel: settingsModel)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(5)
                }
            } else {
                // Mostrar un indicador de carga hasta que los datos estén listos
                ProgressBar(satelliteManager: satelliteManager)
                    .onAppear {
                        satelliteManager.loadSatellitesData()
                    }
            }
    }
}
