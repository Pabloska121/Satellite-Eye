import Foundation

func Path(parameters: TLE) -> [[Double]] {
    // Configuración del tiempo y el intervalo
    let hoursBackward: Double = 0.2       // Tiempo hacia atrás desde el presente, en horas
    let intervalSeconds: Double = 2       // Intervalo de tiempo entre puntos de cálculo, en segundos
    
    // Tiempo inicial (retrocediendo desde el presente)
    var currentTime = Date().addingTimeInterval(-hoursBackward * 3600)
    let totalInterval = hoursBackward * 15 * 3600   // Intervalo total en segundos
    let numPoints = Int(totalInterval / intervalSeconds)
    
    // Inicializamos el array de coordenadas
    var coordinates = Array(repeating: Array(repeating: 0.0, count: 2), count: numPoints)
    
    // Instancia de `SatelliteCalc` usando TLE y nombre
    let satelliteCalc = SatelliteCalc(tle: parameters)
    
    // Ciclo para calcular la posición en cada instante de tiempo
    for i in 0..<numPoints {
        let (lonDegrees, latDegrees, _, _, _) = satelliteCalc.satelliteCalc(utcTime: currentTime)
        
        // Guardamos las coordenadas calculadas
        coordinates[i][0] = latDegrees
        coordinates[i][1] = lonDegrees
        
        // Avanzamos al siguiente punto de tiempo
        currentTime = currentTime.addingTimeInterval(intervalSeconds)
    }

    return coordinates
}
