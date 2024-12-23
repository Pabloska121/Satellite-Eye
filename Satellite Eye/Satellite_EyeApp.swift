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
        .onChange(of: scenePhase) { oldValue, newValue in
            switch newValue {
            case .active: break
            case .inactive: break
            case .background:
                scheduleAppRefresh()
            @unknown default: break
            }
        }
        .backgroundTask(.appRefresh("SatelliteData")) {
            print("[backgroundTask]", "SatelliteData", "invoked")
            await handleAppRefresh() // Ejecutamos la tarea cuando la app se refresca
        }
    }

    // Maneja la actualización de la app cuando se ejecuta la tarea de fondo
    func handleAppRefresh() async {
        print("Handling app refresh...")
        
        // Define the groups to process
        let groups = ["active", "visual", "stations"]
        
        // Get the cache directory
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Failed to get cache directory.")
            return
        }
        
        // Iterate over each group
        for group in groups {
            let fileURL = cacheDirectory.appendingPathComponent("\(group).csv")
            print("Downloading and saving satellites for group '\(group)' to: \(fileURL)")
            
            // Call the method to download and save satellites
            satelliteManager.downloadAndSaveSatellites(
                to: fileURL,
                APIString: "https://celestrak.org/NORAD/elements/gp.php?GROUP=\(group)&FORMAT=csv",
                group: group
            )
        }
    }

    // Maneja la tarea de fondo cuando se llama en segundo plano
    func handleAppRefreshTask(_ task: BGTask) {
        print("Handling background refresh task...")
        
        // Define qué hacer cuando la tarea caduca
        task.expirationHandler = {
            print("Task expired.")
            task.setTaskCompleted(success: false)
        }

        // Ejecuta la actualización y marca la tarea como completada
        Task {
            print("Starting app refresh...")
            await handleAppRefresh() // Realiza la actualización
            task.setTaskCompleted(success: true) // Marca la tarea como completada
            print("App refresh completed successfully.")

            // Después de completar la tarea, vuelve a agendar la siguiente
            scheduleAppRefresh()
        }
    }

    // Agenda la próxima tarea de fondo para mañana a las 12:00 PM
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "SatelliteData")
        request.earliestBeginDate = .now.addingTimeInterval(1/60 * 3600)
        print("Scheduling task with identifier: SatelliteData, Earliest begin date: \(request.earliestBeginDate!)")
        
        do {
            try BGTaskScheduler.shared.submit(request) // Envia la tarea para que se ejecute más tarde
            print("App Refresh Task scheduled.")
        } catch {
            print("Failed to schedule app refresh: \(error)")
        }
    }
}
