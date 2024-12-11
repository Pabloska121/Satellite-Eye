import Foundation
import SwiftUI

class SatelliteInfo: ObservableObject {
    
    @Published var position: SatellitePosition?
    
    func update(with data: SatellitePosition) {
        DispatchQueue.main.async {
            self.position = data
        }
    }
    
    static func requestSatelliteData(satelliteInfo: SatelliteInfo,_ parameters: TLE, lat_et: Double, lon_et: Double, observerAlt: Double) async {
        let satelliteCalc = SatelliteCalc(tle: parameters)
        let (lonDegrees, latDegrees, alt, vel, pos) = satelliteCalc.satelliteCalc(utcTime: Date())
        let (az, el) = satelliteCalc.getObserverLook(utcTime: Date(), observerLon: lon_et, observerLat: lat_et, observerAlt: observerAlt)
        let satellite = SatellitePosition(name: parameters.OBJECT_NAME, latitude: latDegrees, longitude: lonDegrees, elevationAngle: el, azimut: az, altitude: alt, velocity: vel, xyz: pos)
        satelliteInfo.update(with: satellite)
    }
}

struct SatellitePosition {
    let name: String
    let latitude: Double
    let longitude: Double
    let elevationAngle: Double
    let azimut: Double
    let altitude: Double
    let velocity: Double
    let xyz: (Double, Double, Double)
}
