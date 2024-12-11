import Foundation

func PredictionPath(parameters: TLE, startDate: Date, endDate: Date) -> [[Double]] {
    let intervalSeconds: TimeInterval = 15
    // Inicializar el array de coordenadas
    var coordinates: [[Double]] = []
    
    // Instancia de `SatelliteCalc` usando los parámetros TLE
    let satelliteCalc = SatelliteCalc(tle: parameters)
    
    // Tiempo actual en el rango de observación
    var currentTime = startDate
    
    // Ciclo para calcular posiciones hasta `endDate`
    while currentTime <= endDate {
        // Calcular la posición del satélite
        let (lonDegrees, latDegrees, _, _, _) = satelliteCalc.satelliteCalc(utcTime: currentTime)
        
        // Guardar las coordenadas calculadas
        coordinates.append([latDegrees, lonDegrees])
        
        // Avanzar el tiempo en intervalos de 15 segundos
        currentTime = currentTime.addingTimeInterval(intervalSeconds)
    }
    
    return coordinates
}
