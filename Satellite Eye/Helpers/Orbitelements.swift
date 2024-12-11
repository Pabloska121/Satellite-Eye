import Foundation

// Definir constantes como en Python
let XMNPDA = 1440.0
let XKE = 0.0743669161
let CK2 = 5.413080e-4
let AE = 1.0
let XKMPER = 6378.135

class OrbitElements {
    
    var epoch: Date
    var excentricity: Double
    var inclination: Double
    var rightAscension: Double
    var argPerigee: Double
    var meanAnomaly: Double
    
    var meanMotion: Double
    var meanMotionDerivative: Double
    var meanMotionSecDerivative: Double
    var bstar: Double
    
    var originalMeanMotion: Double
    var semiMajorAxis: Double
    var period: Double
    var perigee: Double
    var rightAscensionLon: Double
    
    init(tle: TLE) {
        // Convertir 'epoch' de String a Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        self.epoch = dateFormatter.date(from: tle.EPOCH) ?? Date()
        
        self.excentricity = tle.ECCENTRICITY
        self.inclination = tle.INCLINATION.degreesToRadians()  // convertir grados a radianes
        self.rightAscension = tle.RA_OF_ASC_NODE.degreesToRadians()  // convertir grados a radianes
        self.argPerigee = tle.ARG_OF_PERICENTER.degreesToRadians()  // convertir grados a radianes
        self.meanAnomaly = tle.MEAN_ANOMALY.degreesToRadians()  // convertir grados a radianes
        
        self.meanMotion = tle.MEAN_MOTION * (2 * .pi / XMNPDA)
        self.meanMotionDerivative = tle.MEAN_MOTION_DOT * (2 * .pi / XMNPDA * XMNPDA)
        self.meanMotionSecDerivative = tle.MEAN_MOTION_DDOT * (2 * .pi / XMNPDA * XMNPDA * XMNPDA)
        self.bstar = tle.BSTAR * AE
        
        let n_0 = self.meanMotion
        let k_e = XKE
        let k_2 = CK2
        let i_0 = self.inclination
        let e_0 = self.excentricity
        
        let a_1 = pow(k_e / n_0, 2.0 / 3.0)
        let delta_1 = (3 / 2.0) * (k_2 / pow(a_1, 2)) * ((3 * cos(i_0) * cos(i_0) - 1) /
                                                     pow(1 - e_0 * e_0, 2.0 / 3.0))
        
        let a_0 = a_1 * (1 - delta_1 / 3 - pow(delta_1, 2) - (134.0 / 81) * pow(delta_1, 3))
        
        let delta_0 = (3 / 2.0) * (k_2 / pow(a_0, 2)) * ((3 * cos(i_0) * cos(i_0) - 1) /
                                                     pow(1 - e_0 * e_0, 2.0 / 3.0))
        
        self.originalMeanMotion = n_0 / (1 + delta_0)
        
        let a_0pp = a_0 / (1 - delta_0)
        self.semiMajorAxis = a_0pp
        
        self.period = 2 * .pi / self.originalMeanMotion
        
        self.perigee = (a_0pp * (1 - e_0) / AE - AE) * XKMPER
        
        self.rightAscensionLon = self.rightAscension - gmst(utcTime: self.epoch)
        
        if self.rightAscensionLon > .pi {
            self.rightAscensionLon -= 2 * .pi
        }
    }
}

// Extensión para convertir grados a radianes
extension Double {
    func degreesToRadians() -> Double {
        return self * .pi / 180.0
    }
}
