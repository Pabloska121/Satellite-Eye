import Foundation

class SatelliteManager: ObservableObject {
    @Published var allSatellites: [TLE] = []
    @Published var selectedSatellite: TLE?
    @Published var isLoading: Bool = true
    @Published var downloadProgress: CGFloat = 0.0
    
    private let tleDownloader = TLEDownloader()

    func loadSatellitesData() {
        isLoading = true
        downloadProgress = 0.0

        let fileManager = FileManager.default
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileURL = cacheDirectory.appendingPathComponent("active.csv")

            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let modificationDate = attributes[.modificationDate] as? Date,
                       Date().timeIntervalSince(modificationDate) < 10 * 3600 {
                        try loadSatellitesFromFile(at: fileURL)
                    } else {
                        downloadAndSaveSatellites(to: fileURL)
                    }
                } catch {
                    print("Error accessing cache file: \(error)")
                    isLoading = false
                }
            } else {
                downloadAndSaveSatellites(to: fileURL)
            }
        } else {
            print("Error: Cache directory not found")
            isLoading = false  // Finaliza la carga si no encuentra el directorio de caché
        }
    }

    private func downloadAndSaveSatellites(to fileURL: URL) {
        downloadProgress = 0.0 
        tleDownloader.downloadTLEFile(
            progressHandler: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.downloadProgress = progress * 1.0
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let satellites):
                        self?.processDownloadedData(satellites: satellites, fileURL: fileURL)
                    case .failure(let error):
                        print("Failed to download TLE data: \(error)")
                        self?.isLoading = false
                        self?.downloadProgress = 1.0  // Finalizar si hay error
                    }
                }
            }
        )
    }
    
    private func processDownloadedData(satellites: [TLE], fileURL: URL) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                self?.downloadProgress = 1.0
                // Guardar datos en el caché en formato CSV
                let csvString = self?.convertSatellitesToCSV(satellites) ?? ""
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

                DispatchQueue.main.async {
                    self?.allSatellites = satellites
                    self?.isLoading = false
                    print("Satellites successfully downloaded, processed, and cached!")
                }
            } catch {
                print("Error processing satellites: \(error)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.downloadProgress = 1.0  // Completar en caso de error
                }
            }
        }
    }
    
    private func loadSatellitesFromFile(at fileURL: URL) throws {
        // Simulación del progreso durante la carga desde el archivo CSV
        downloadProgress = 0.0  // Iniciar progreso en 0%
        isLoading = true
        
        // Crear un temporizador que simule el progreso
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            // Aumenta el progreso gradualmente hasta 100%
            if self.downloadProgress < 1.0 {
                self.downloadProgress += 0.05  // Ajusta el incremento según la velocidad deseada
            } else {
                // Finaliza el temporizador cuando se alcanza el 100%
                timer.invalidate()
                
                do {
                    let data = try Data(contentsOf: fileURL)
                    let satellites = try self.parseCSV(data: data)
                    DispatchQueue.main.async {
                        self.allSatellites = satellites
                        self.isLoading = false
                        print("Satellites successfully loaded from cache!")
                    }
                } catch {
                    print("Error loading satellites from file: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.downloadProgress = 1.0  // Completar en caso de error
                    }
                }
            }
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

    func fetchSatelliteData(satelliteName: String) {
        if let foundSatellite = allSatellites.first(where: { $0.OBJECT_NAME == satelliteName }) {
            self.selectedSatellite = foundSatellite
        } else {
            print("Satellite \(satelliteName) not found in memory.")
        }
    }
}
