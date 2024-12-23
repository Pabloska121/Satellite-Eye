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
    
    // Función para descargar el archivo TLE en background
    func downloadTLEFile(urlString: String, progressHandler: @escaping (CGFloat) -> Void, completion: @escaping (Result<[TLE], Error>) -> Void) {
        self.progressHandler = progressHandler
        self.completionHandler = completion
        
        // URL de la API para CSV
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "TLEDownloader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Crear tarea de descarga
        let downloadTask = backgroundSession.downloadTask(with: url)
        downloadTask.resume() // Iniciar la descarga
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
}
