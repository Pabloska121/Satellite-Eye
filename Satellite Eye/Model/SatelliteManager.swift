import Foundation

class SatelliteManager: ObservableObject {
    @Published var allSatellites: [TLE] = [] {
        didSet { saveSatellitesToFile() }
    }
    @Published var active: [TLE] = []
    @Published var visual: [TLE] = []
    @Published var stations: [TLE] = []
    @Published var satellitesByGroup: [String: [TLE]] = [:]
    @Published var selectedSatellite: TLE?
    @Published var isLoading: Bool = true
    @Published var downloadProgress: CGFloat = 0.0
    private var lastDownloadedSatellite: TLE?
    private let tleDownloader = TLEDownloader()
    private let fileManager = FileManager.default
    private let satelliteFileName = "satellitesData.json"
    private var isDownloading: Bool = false
    
    // Guardar los satélites en un archivo
    private func saveSatellitesToFile() {
        let fileURL = getFileURL()
        do {
            let encoder = JSONEncoder()
            let encodedSatellites = try encoder.encode(allSatellites)
            try encodedSatellites.write(to: fileURL)
            print("Satélites guardados en archivo.")
        } catch {
            print("Error al guardar satélites en archivo: \(error)")
        }
    }
    
    private func getFileURL() -> URL {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("No se encontró el directorio de documentos.")
        }
        return documentsDirectory.appendingPathComponent(satelliteFileName)
    }
    
    func loadAllSatelliteGroups() {
        print("Cargando todos los grupos de satélites...")
        isLoading = true
        downloadProgress = 0.0
        let groups = ["stations", "visual", "active"]
        
        // Crear un DispatchGroup para esperar a que todas las descargas finalicen
        let dispatchGroup = DispatchGroup()
        
        Task {
            // Realizamos una descarga concurrente para cada grupo de satélites
            for groupName in groups {
                dispatchGroup.enter() // Añadir al DispatchGroup
                
                // Cargar los datos de los satélites
                await loadSatellitesData(for: groupName)
                
                dispatchGroup.leave() // Finalizar la tarea de ese grupo
            }
            
            // Esperamos a que todas las tareas del DispatchGroup terminen
            dispatchGroup.notify(queue: .main) {
                self.isLoading = false // Cambiar el estado de carga
                print("Carga completa de todos los grupos.")
            }
        }
    }
    
    func loadSatellitesData(for group: String) async {
        print("Cargando datos para el grupo: \(group)...")
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Error: No se encontró el directorio de caché.")
            return
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(group).csv")
        let needsUpdate = needsFileUpdate(fileURL: fileURL)
        
        if needsUpdate {
            print("Descargando datos nuevos para el grupo \(group)...")
            await downloadAndSaveSatellites(to: fileURL, APIString: "https://celestrak.org/NORAD/elements/gp.php?GROUP=\(group)&FORMAT=csv", group: group)
        } else {
            print("Cargando datos desde caché para el grupo \(group)...")
            try? loadSatellitesFromFile(at: fileURL, group: group)
        }
    }
    
    private func needsFileUpdate(fileURL: URL) -> Bool {
        guard fileManager.fileExists(atPath: fileURL.path),
              let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return true
        }
        return Date().timeIntervalSince(modificationDate) > 24 * 60 * 60
    }
    
    private func downloadAndSaveSatellites(to fileURL: URL, APIString: String, group: String) async {
        var hasResumed = false
        
        do {
            let satellites = try await withCheckedThrowingContinuation { continuation in
                tleDownloader.downloadTLEFile(
                    urlString: APIString,
                    progressHandler: { progress in
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                            print(progress)
                        }
                    },
                    completion: { result in
                        guard !hasResumed else { return }
                        
                        switch result {
                        case .success(let satellites):
                            hasResumed = true
                            continuation.resume(returning: satellites)
                        case .failure(let error):
                            hasResumed = true
                            continuation.resume(throwing: error)
                        }
                    }
                )
            }
            try processDownloadedData(satellites: satellites, fileURL: fileURL, group: group)
        } catch {
            print("Error al descargar los datos TLE para el grupo \(group): \(error)")
        }
    }
    
    private func processDownloadedData(satellites: [TLE], fileURL: URL, group: String) throws {
        let csvString = convertSatellitesToCSV(satellites)
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        DispatchQueue.main.async {
            self.updateSatellitesGroup(satellites: satellites, group: group)
            self.satellitesByGroup[group] = satellites
            self.allSatellites.append(contentsOf: satellites)
            print("Datos procesados y almacenados para el grupo \(group)")
        }
    }
    
    private func updateSatellitesGroup(satellites: [TLE], group: String) {
        switch group {
        case "active": self.active = satellites
        case "visual": self.visual = satellites
        case "stations": self.stations = satellites
        default: print("Grupo desconocido: \(group)")
        }
    }
    
    private func loadSatellitesFromFile(at fileURL: URL, group: String) throws {
        let data = try Data(contentsOf: fileURL)
        let satellites = try parseCSV(data: data)
        DispatchQueue.main.async {
            self.updateSatellitesGroup(satellites: satellites, group: group)
            self.satellitesByGroup[group] = satellites
            self.allSatellites.append(contentsOf: satellites)
        }
    }
    
    private func convertSatellitesToCSV(_ satellites: [TLE]) -> String {
        var csvString = "OBJECT_NAME,OBJECT_ID,EPOCH,MEAN_MOTION,ECCENTRICITY,INCLINATION,RA_OF_ASC_NODE,ARG_OF_PERICENTER,MEAN_ANOMALY,EPHEMERIS_TYPE,CLASSIFICATION_TYPE,NORAD_CAT_ID,ELEMENT_SET_NO,REV_AT_EPOCH,BSTAR,MEAN_MOTION_DOT,MEAN_MOTION_DDOT\n"

        for satellite in satellites {
            csvString += "\(satellite.OBJECT_NAME),\(satellite.OBJECT_ID),\(satellite.EPOCH),\(satellite.MEAN_MOTION),\(satellite.ECCENTRICITY),\(satellite.INCLINATION),\(satellite.RA_OF_ASC_NODE),\(satellite.ARG_OF_PERICENTER),\(satellite.MEAN_ANOMALY),\(satellite.EPHEMERIS_TYPE),\(satellite.CLASSIFICATION_TYPE),\(satellite.NORAD_CAT_ID),\(satellite.ELEMENT_SET_NO),\(satellite.REV_AT_EPOCH),\(satellite.BSTAR),\(satellite.MEAN_MOTION_DOT),\(satellite.MEAN_MOTION_DDOT)\n"
        }

        return csvString
    }

    private func parseCSV(data: Data) throws -> [TLE] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "SatelliteManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV data"])
        }
        let lines = csvString.split(separator: "\n")
        var satellites: [TLE] = []

        for line in lines.dropFirst() { // Omitimos la primera línea de encabezados
            let columns = line.split(separator: ",")
            if columns.count == 17 {
                let satellite = TLE(
                    OBJECT_NAME: String(columns[0]),
                    OBJECT_ID: String(columns[1]),
                    EPOCH: String(columns[2]),
                    MEAN_MOTION: Double(columns[3]) ?? 0.0,
                    ECCENTRICITY: Double(columns[4]) ?? 0.0,
                    INCLINATION: Double(columns[5]) ?? 0.0,
                    RA_OF_ASC_NODE: Double(columns[6]) ?? 0.0,
                    ARG_OF_PERICENTER: Double(columns[7]) ?? 0.0,
                    MEAN_ANOMALY: Double(columns[8]) ?? 0.0,
                    EPHEMERIS_TYPE: Int(columns[9]) ?? 0,
                    CLASSIFICATION_TYPE: String(columns[10]),
                    NORAD_CAT_ID: Int(columns[11]) ?? 0,
                    ELEMENT_SET_NO: Int(columns[12]) ?? 0,
                    REV_AT_EPOCH: Int(columns[13]) ?? 0,
                    BSTAR: Double(columns[14]) ?? 0.0,
                    MEAN_MOTION_DOT: Double(columns[15]) ?? 0.0,
                    MEAN_MOTION_DDOT: Double(columns[16]) ?? 0.0
                )
                satellites.append(satellite)
            }
        }

        return satellites
    }
    
    // Buscar un satélite por nombre y obtener sus datos individualmente desde CelesTrak.
    func fetchSatelliteData(satelliteName: String) {
        print("Buscando satélite con nombre: \(satelliteName)...")
        print(lastDownloadedSatellite?.OBJECT_NAME == satelliteName)
        if lastDownloadedSatellite?.OBJECT_NAME == satelliteName {
            self.selectedSatellite = lastDownloadedSatellite
            return
        }
        
        // Si `isDownloading` es true, descargar directamente el TLE del satélite
        if isDownloading {
            print("Forzando descarga directa del satélite \(satelliteName)...")
            downloadTLE(satelliteName: satelliteName)
            return
        } else {
            print("Localizando datos para el satélite \(satelliteName)...")
            if let foundSatellite = allSatellites.first(where: { $0.OBJECT_NAME == satelliteName }) {
                self.selectedSatellite = foundSatellite
            } else {
                print("Satellite \(satelliteName) not found in memory.")
            }
        }
    }

    // Función para descargar los datos TLE del satélite
    private func downloadTLE(satelliteName: String) {

        guard let satellite = allSatellites.first(where: { $0.OBJECT_NAME == satelliteName }) else {
            print("El satélite \(satelliteName) no se encuentra en la lista total. No se puede descargar.")
            isDownloading = false
            return
        }

        tleDownloader.downloadSingleTLE(satelliteID: satellite.NORAD_CAT_ID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let downloadedSatellite):
                    print("Datos descargados exitosamente para \(satelliteName). Procesando...")
                    self?.selectedSatellite = downloadedSatellite
                    self?.lastDownloadedSatellite = downloadedSatellite
                    print("Datos del satélite \(satelliteName) procesados: \(downloadedSatellite)")

                case .failure(let error):
                    print("Error al descargar los datos del satélite \(satelliteName): \(error)")
                }
            }
        }
    }
}
