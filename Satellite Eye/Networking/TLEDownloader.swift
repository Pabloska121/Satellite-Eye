import Foundation
import Combine

class TLEDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    // Handlers para progreso y finalización
    private var progressHandler: ((CGFloat) -> Void)?
    private var completionHandler: ((Result<[TLE], Error>) -> Void)?
    
    // URLSession de configuración de fondo
    private var backgroundSession: URLSession!
    
    override init() {
        super.init()
        
        // Crear una configuración de URLSession para el background
        let configuration = URLSessionConfiguration.background(withIdentifier: "SatelliteData")
        backgroundSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func downloadTLEFile(urlString: String, progressHandler: @escaping (CGFloat) -> Void, completion: @escaping (Result<[TLE], Error>) -> Void) {
        self.progressHandler = progressHandler
        self.completionHandler = completion
        
        // URL de la API para CSV
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Crear un DispatchGroup para manejar las descargas concurrentes
        let dispatchGroup = DispatchGroup()
        
        // Crear tarea de descarga
        let downloadTask = backgroundSession.downloadTask(with: url)
        
        // Agregar al DispatchGroup
        dispatchGroup.enter()
        
        downloadTask.resume() // Iniciar la descarga
        
        // Cuando la descarga se complete, notificamos que la tarea ha finalizado
        downloadTask.observe(\.state) { task, _ in
            if task.state == .completed {
                dispatchGroup.leave() // Terminar la tarea en el DispatchGroup
            }
        }
        
        // Una vez que todas las tareas se completen, procesar los datos y llamar al completion
        dispatchGroup.notify(queue: .main) {
            do {
                let data = try Data(contentsOf: downloadTask.originalRequest!.url!)
                let satellites = try self.parseCSV(data: data)  // Parsear el CSV
                DispatchQueue.main.async {
                    self.completionHandler?(.success(satellites))  // Notificar éxito
                }
            } catch {
                DispatchQueue.main.async {
                    self.completionHandler?(.failure(error))  // Notificar error
                }
            }
        }
    }

    // Delegado de URLSession para manejar el progreso de la descarga
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandler?(progress)  // Actualizar progreso en la UI
        }
    }
    
    // Delegado de URLSession para manejar la finalización de la descarga
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            let satellites = try self.parseCSV(data: data)  // Parsear el CSV
            DispatchQueue.main.async {
                self.completionHandler?(.success(satellites))  // Notificar éxito
            }
        } catch {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))  // Notificar error
            }
        }
    }
    
    // Delegado de URLSession para manejar errores
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))  // Notificar error
            }
        }
    }
    
    // Función para parsear el CSV (Aquí puedes adaptar tu lógica de CSV)
    private func parseCSV(data: Data) throws -> [TLE] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV data"])
        }
        
        // Procesar el CSV y extraer la información
        var lines = csvString.components(separatedBy: "\n")
        lines.removeFirst()  // Eliminar la primera línea si es un encabezado
        
        var satellites: [TLE] = []
        for line in lines {
            let columns = line.split(separator: ",")
            if columns.count == 17 {  // Verificar que el CSV tenga la cantidad correcta de columnas
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
    
    func downloadSingleTLE(satelliteID: Int, completion: @escaping (Result<TLE, Error>) -> Void) {
        let apiString = "https://celestrak.org/NORAD/elements/gp.php?CATNR=\(satelliteID)&FORMAT=csv"
        print("Descargando TLE desde \(apiString)...")

        // Realizar la solicitud
        guard let url = URL(string: apiString) else {
            completion(.failure(NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL inválida."])))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos."])))
                return
            }

            do {
                if let tle = try self.parsesingleCSV(data: data) {
                    completion(.success(tle))
                } else {
                    completion(.failure(NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "No se encontraron datos TLE en la respuesta."])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func parsesingleCSV(data: Data) throws -> TLE? {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Datos CSV inválidos."])
        }

        let lines = csvString.components(separatedBy: "\n")
        guard lines.count > 1 else {
            throw NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "No se encontraron líneas de datos en el CSV."])
        }

        // Procesar la línea de datos (ignorar la cabecera)
        let columns = lines[1].split(separator: ",")
        guard columns.count == 17 else {
            throw NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "La línea de datos del CSV está mal formada."])
        }

        return TLE(
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
    }

}
